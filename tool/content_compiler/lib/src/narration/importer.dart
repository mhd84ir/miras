import 'dart:convert';
import 'dart:io';

import 'package:content_compiler/src/model/content.dart';
import 'package:content_compiler/src/narration/narration.dart';
import 'package:path/path.dart' as p;

/// Imports آوای گنجور recitations for one chapter (ADR-0011): per source
/// poem, downloads the chosen recitation's MP3 + sync XML, slices each
/// referenced couplet, and stores ID-addressed clips plus provenance under
/// `content/narration/<chapter>/`. Re-running overwrites — the import is
/// idempotent for the same recitation choices.
Future<void> importNarration({
  required ContentBundle bundle,
  required String chapterId,
  required Directory contentDir,
  String? artistFilter,
  void Function(String)? log,
}) async {
  void logLine(String line) => stdout.writeln(line);
  final out = log ?? logLine;
  final chapter = bundle.chapters.firstWhere(
    (c) => c.id == chapterId,
    orElse: () => throw StateError('unknown chapter: $chapterId'),
  );

  // verses grouped by source poem, keeping (verseId, coupletIndex).
  final byPoem = <String, List<({String verseId, int couplet})>>{};
  for (final v in chapter.verses) {
    final source = v.source;
    if (source == null) {
      throw StateError('${v.id} has no source ref — cannot locate narration');
    }
    final ref = parseGanjoorRef(source);
    byPoem.putIfAbsent(ref.path, () => []).add((
      verseId: v.id,
      couplet: ref.couplet,
    ));
  }

  final outDir = Directory(p.join(contentDir.path, 'narration', chapterId))
    ..createSync(recursive: true);
  final client = HttpClient();
  final narrators = <String, ({String name, String? url})>{};
  final verseMeta = <String, Object>{};
  final tmp = Directory.systemTemp.createTempSync('miras_narration');
  try {
    for (final MapEntry(key: poemPath, value: refs) in byPoem.entries) {
      final poem =
          jsonDecode(
                await _getString(
                  client,
                  'https://api.ganjoor.net/api/ganjoor/poem'
                  '?url=$poemPath&verseDetails=false&catInfo=false',
                ),
              )
              as Map<String, dynamic>;
      final recitations = [
        for (final r in (poem['recitations'] as List<dynamic>? ?? []))
          r as Map<String, dynamic>,
      ].where((r) => r['inSyncWithText'] == true).toList();
      if (recitations.isEmpty) {
        throw StateError('no synced recitation for $poemPath');
      }
      final recitation = artistFilter == null
          ? recitations.first
          : recitations.firstWhere(
              (r) => (r['audioArtist'] as String).contains(artistFilter),
              orElse: () {
                final available = recitations
                    .map((r) => r['audioArtist'])
                    .join('، ');
                throw StateError(
                  'no recitation by "$artistFilter" for $poemPath '
                  '(available: $available)',
                );
              },
            );
      final recId = recitation['id'] as int;
      final artist = recitation['audioArtist'] as String;
      narrators[artist] = (
        name: artist,
        url: recitation['audioArtistUrl'] as String?,
      );
      out(
        'poem $poemPath → recitation $recId ($artist), '
        '${refs.length} couplets',
      );

      final mp3 = File(p.join(tmp.path, '$recId.mp3'));
      await _download(client, recitation['mp3Url'] as String, mp3);
      final starts = parseSyncXml(
        await _getString(
          client,
          'https://api.ganjoor.net/api/audio/file/$recId.xml',
        ),
      );

      for (final ref in refs) {
        final range = coupletRangeMs(starts, ref.couplet);
        final clip = File(p.join(outDir.path, '${ref.verseId}.mp3'));
        await _slice(mp3, clip, range);
        verseMeta[ref.verseId] = {
          'poem': poemPath,
          'couplet': ref.couplet,
          'recitation_id': recId,
          'artist': artist,
        };
        out(
          '  ${ref.verseId} ← couplet ${ref.couplet} '
          '[${range.startMs}ms–${range.endMs ?? "end"}]',
        );
      }
    }
  } finally {
    client.close();
    tmp.deleteSync(recursive: true);
  }

  File(p.join(outDir.path, 'narration.json')).writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert({
      'schema': 1,
      'source': 'آوای گنجور (ganjoor.net)',
      'narrators': [
        for (final n in narrators.values) {'name': n.name, 'url': n.url},
      ],
      'verses': verseMeta,
    }),
  );
  out(
    'narration: ${verseMeta.length} clips for $chapterId by '
    '${narrators.keys.join('، ')} → ${outDir.path}',
  );
}

Future<String> _getString(HttpClient client, String url) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw HttpException('GET $url → ${response.statusCode}');
  }
  return response.transform(utf8.decoder).join();
}

Future<void> _download(HttpClient client, String url, File target) async {
  final request = await client.getUrl(Uri.parse(url));
  final response = await request.close();
  if (response.statusCode != 200) {
    throw HttpException('GET $url → ${response.statusCode}');
  }
  await response.pipe(target.openWrite());
}

/// Accurate (post-input) seek, transcoded to the pack's shared audio profile.
Future<void> _slice(
  File source,
  File target,
  ({int startMs, int? endMs}) range,
) async {
  String seconds(int ms) => (ms / 1000).toStringAsFixed(3);
  final result = await Process.run('ffmpeg', [
    '-y',
    '-loglevel',
    'error',
    '-i',
    source.path,
    '-ss',
    seconds(range.startMs),
    if (range.endMs != null) ...['-to', seconds(range.endMs!)],
    '-ar',
    '24000',
    '-ac',
    '1',
    '-b:a',
    '48k',
    target.path,
  ]);
  if (result.exitCode != 0) {
    throw ProcessException('ffmpeg', [], 'slice failed: ${result.stderr}');
  }
}
