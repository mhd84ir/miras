import 'dart:convert';
import 'dart:io';

import 'package:args/args.dart';
import 'package:content_compiler/content_compiler.dart';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

Future<void> main(List<String> argv) async {
  final parser = ArgParser()
    ..addOption(
      'content',
      defaultsTo: 'content',
      help: 'Content source directory',
    )
    ..addOption('out', defaultsTo: 'build/pack', help: 'Pack output directory')
    ..addOption('pack-version', defaultsTo: '1')
    ..addOption(
      'tts',
      allowed: ['none', 'azure', 'piper', 'cache'],
      defaultsTo: 'none',
      help:
          'TTS backend for audio generation; "cache" replays the committed '
          'audio cache without a backend (CI/release mode)',
    )
    ..addOption(
      'piper-model',
      help: 'Path to a Piper voice model (.onnx); PIPER_MODEL env fallback',
    )
    ..addOption('chapter', help: 'Chapter id (import-narration)')
    ..addOption(
      'artist',
      help: 'Preferred narrator name substring (import-narration)',
    )
    ..addFlag('strict', help: 'Treat warnings as failures (CI/release mode)')
    ..addFlag('help', abbr: 'h', negatable: false);

  final ArgResults args;
  try {
    args = parser.parse(argv);
  } on FormatException catch (e) {
    _usage(parser, error: e.message);
    exit(64);
  }
  if (args.flag('help') || args.rest.isEmpty) {
    _usage(parser);
    exit(args.flag('help') ? 0 : 64);
  }
  final command = args.rest.first;
  const commands = {'build', 'validate', 'import-narration'};
  if (!commands.contains(command)) {
    _usage(parser, error: 'unknown command "$command"');
    exit(64);
  }

  final contentDir = Directory(args.option('content')!);
  if (!contentDir.existsSync()) {
    stderr.writeln('content directory not found: ${contentDir.path}');
    exit(66);
  }

  // ------------------------------------------------------ load + validate
  final loader = YamlLoader(contentDir);
  final bundle = loader.load();
  final issues = [...loader.issues, ...Validator(bundle).validate()];

  final errors = issues
      .where((i) => i.severity == IssueSeverity.error)
      .toList();
  final warnings = issues
      .where((i) => i.severity == IssueSeverity.warning)
      .toList();

  issues.forEach(stderr.writeln);
  stdout.writeln(
    'validate: ${bundle.chapters.length} chapters, '
    '${bundle.allLessons.length} lessons, '
    '${bundle.allExercises.length} exercises, '
    '${bundle.allVocab.length} vocab, '
    '${bundle.allVerses.length} verses — '
    '${errors.length} errors, ${warnings.length} warnings',
  );

  if (errors.isNotEmpty || (args.flag('strict') && warnings.isNotEmpty)) {
    exit(1);
  }
  if (command == 'validate') return;

  if (command == 'import-narration') {
    final chapterId = args.option('chapter');
    if (chapterId == null) {
      _usage(parser, error: 'import-narration requires --chapter');
      exit(64);
    }
    await importNarration(
      bundle: bundle,
      chapterId: chapterId,
      contentDir: contentDir,
      artistFilter: args.option('artist'),
    );
    return;
  }

  // --------------------------------------------------------------- audio
  // The cache is committed alongside authored content (ADR-0008), so builds
  // are audio-complete and deterministic without a synthesis backend.
  final cacheDir = Directory(p.join(contentDir.path, 'audio_cache'));
  final adapter = switch (args.option('tts')) {
    'azure' =>
      AzureTts.fromEnvironment() ??
          (throw StateError(
            'AZURE_SPEECH_KEY / AZURE_SPEECH_REGION not set',
          )),
    'piper' => switch (args.option('piper-model')) {
      final model? => PiperTts(model: File(model)),
      null =>
        PiperTts.fromEnvironment() ??
            (throw StateError('--piper-model or PIPER_MODEL not set')),
    },
    'cache' => CacheOnlyTts(cacheDir),
    _ => const NoopTts(),
  };
  final outDir = Directory(args.option('out')!);
  final tts = CachedTts(adapter, cacheDir);

  final audioAssets = <String, String>{};
  final assetFiles = <String, ({String sha256, int bytes})>{};
  var missingAudio = 0;
  Future<void> synthesizeFor(String id, String text) async {
    final bytes = await tts.get(text);
    if (bytes == null) {
      missingAudio++;
      return;
    }
    final asset = tts.assetName(text);
    final file = File(p.join(outDir.path, asset));
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes);
    audioAssets[id] = asset;
    assetFiles[asset] = (
      sha256: sha256.convert(bytes).toString(),
      bytes: bytes.length,
    );
  }

  for (final v in bundle.allVocab) {
    // tts_text (fully-diacritized) overrides the display form for synthesis;
    // see VocabItem.ttsText.
    await synthesizeFor(v.id, v.ttsText ?? v.word);
  }
  for (final v in bundle.allVerses) {
    await synthesizeFor(v.id, '${v.hemistich1}، ${v.hemistich2}');
  }
  if (missingAudio > 0) {
    stdout.writeln(
      'audio: $missingAudio items without audio (tts=${adapter.id}) — '
      'listening exercises will be skipped by the app until audio exists',
    );
  }
  final silentListening = listeningWithoutAudio(
    bundle,
    audioAssets.keys.toSet(),
  );
  if (silentListening.isNotEmpty) {
    final message =
        'audio: ${silentListening.length} listening exercises would be '
        'silently skipped by the app: ${silentListening.join(', ')}';
    if (args.flag('strict')) {
      stderr.writeln('ERROR $message');
      exit(1);
    }
    stdout.writeln('WARN  $message');
  }

  // ---------------------------------------------------- narration overlay
  // Human recitation (ADR-0011) overrides synthesized verse audio; clips are
  // ID-addressed under content/narration/<chapter>/ with provenance JSON.
  final credits = <PackCredit>[];
  final narrationRoot = Directory(p.join(contentDir.path, 'narration'));
  if (narrationRoot.existsSync()) {
    final verseIds = {for (final v in bundle.allVerses) v.id};
    for (final chapterDir
        in narrationRoot.listSync().whereType<Directory>().toList()
          ..sort((a, b) => a.path.compareTo(b.path))) {
      final metaFile = File(p.join(chapterDir.path, 'narration.json'));
      if (!metaFile.existsSync()) continue;
      final meta =
          jsonDecode(metaFile.readAsStringSync()) as Map<String, dynamic>;
      var clips = 0;
      for (final clip in chapterDir.listSync().whereType<File>()) {
        if (!clip.path.endsWith('.mp3')) continue;
        final verseId = p.basenameWithoutExtension(clip.path);
        if (!verseIds.contains(verseId)) {
          stdout.writeln(
            'WARN  narration clip for unknown verse "$verseId" ignored',
          );
          continue;
        }
        final bytes = clip.readAsBytesSync();
        final digest = sha256.convert(bytes).toString();
        final asset = 'audio/${digest.substring(0, 16)}.mp3';
        File(p.join(outDir.path, asset))
          ..parent.createSync(recursive: true)
          ..writeAsBytesSync(bytes);
        audioAssets[verseId] = asset;
        assetFiles[asset] = (sha256: digest, bytes: bytes.length);
        clips++;
      }
      for (final n in meta['narrators'] as List<dynamic>) {
        final narrator = n as Map<String, dynamic>;
        credits.add((
          id: 'narration:${p.basename(chapterDir.path)}:${narrator['name']}',
          kind: 'narration',
          name: narrator['name'] as String,
          url: narrator['url'] as String?,
        ));
      }
      stdout.writeln(
        'narration: ${p.basename(chapterDir.path)} — $clips clips',
      );
    }
  }

  // ---------------------------------------------------------------- pack
  final packVersion = int.parse(args.option('pack-version')!);
  final dbFile = File(p.join(outDir.path, 'miras_content.db'));
  final checksum = PackWriter(
    bundle: bundle,
    packVersion: packVersion,
    audioAssets: audioAssets,
    assetDigests: {
      for (final MapEntry(:key, :value) in assetFiles.entries)
        key: value.sha256,
    },
    credits: credits,
  ).write(dbFile);

  // Manifest (CDN, signed at release time) + sidecar (bundled with the app
  // so the bootstrap can version-check without reading DB bytes) — ADR-0010.
  final dbBytes = dbFile.readAsBytesSync();
  File(p.join(outDir.path, 'manifest.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(
      buildManifest(
        packVersion: packVersion,
        schemaVersion: contentSchemaVersion,
        checksum: checksum,
        files: {
          'miras_content.db': (
            sha256: sha256.convert(dbBytes).toString(),
            bytes: dbBytes.length,
          ),
          ...assetFiles,
        },
        builtAt: DateTime.now(),
      ),
    ),
  );
  File(p.join(outDir.path, 'pack_meta.json')).writeAsStringSync(
    jsonEncode(buildPackMeta(packVersion: packVersion, checksum: checksum)),
  );

  final size = (dbFile.lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln(
    'build: wrote ${dbFile.path} ($size KB, '
    'pack v$packVersion, schema v$contentSchemaVersion) '
    '+ manifest.json + pack_meta.json',
  );
}

void _usage(ArgParser parser, {String? error}) {
  if (error != null) stderr.writeln('error: $error\n');
  stderr
    ..writeln('usage: dart run content_compiler <build|validate> [options]\n')
    ..writeln(parser.usage);
}
