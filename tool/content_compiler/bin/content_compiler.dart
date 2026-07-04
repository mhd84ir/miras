import 'dart:io';

import 'package:args/args.dart';
import 'package:content_compiler/content_compiler.dart';
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
      allowed: ['none', 'azure'],
      defaultsTo: 'none',
      help: 'TTS backend for audio generation',
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
  if (command != 'build' && command != 'validate') {
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

  // --------------------------------------------------------------- audio
  final adapter = switch (args.option('tts')) {
    'azure' =>
      AzureTts.fromEnvironment() ??
          (throw StateError(
            'AZURE_SPEECH_KEY / AZURE_SPEECH_REGION not set',
          )),
    _ => const NoopTts(),
  };
  final outDir = Directory(args.option('out')!);
  final tts = CachedTts(
    adapter,
    Directory(
      p.join(contentDir.parent.path, 'tool/content_compiler/.cache/tts'),
    ),
  );

  final audioAssets = <String, String>{};
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
  }

  for (final v in bundle.allVocab) {
    await synthesizeFor(v.id, v.word);
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

  // ---------------------------------------------------------------- pack
  final dbFile = File(p.join(outDir.path, 'miras_content.db'));
  PackWriter(
    bundle: bundle,
    packVersion: int.parse(args.option('pack-version')!),
    audioAssets: audioAssets,
  ).write(dbFile);

  final size = (dbFile.lengthSync() / 1024).toStringAsFixed(0);
  stdout.writeln(
    'build: wrote ${dbFile.path} ($size KB, '
    'pack v${args.option('pack-version')}, schema v$contentSchemaVersion)',
  );
}

void _usage(ArgParser parser, {String? error}) {
  if (error != null) stderr.writeln('error: $error\n');
  stderr
    ..writeln('usage: dart run content_compiler <build|validate> [options]\n')
    ..writeln(parser.usage);
}
