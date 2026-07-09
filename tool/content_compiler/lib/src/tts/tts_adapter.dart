import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// Text-to-speech backend used at compile time (ADR-0005: audio is pre-baked
/// into packs; the app never synthesizes at runtime).
abstract interface class TtsAdapter {
  /// Stable identity (provider + voice) — part of the cache key, so changing
  /// voice invalidates cached audio.
  String get id;

  /// Returns encoded audio bytes (mp3), or null if synthesis is unavailable.
  Future<List<int>?> synthesize(String text);
}

/// No-op backend: packs build without audio (audio fields stay null).
/// Used until a TTS provider key is configured; see docs/CONTENT_GUIDE.md.
class NoopTts implements TtsAdapter {
  const NoopTts();

  @override
  String get id => 'none';

  @override
  Future<List<int>?> synthesize(String text) async => null;
}

/// Azure Cognitive Services neural TTS (fa-IR).
///
/// Requires `AZURE_SPEECH_KEY` and `AZURE_SPEECH_REGION` environment
/// variables. Never hardcode keys; see .gitignore (.env is ignored).
class AzureTts implements TtsAdapter {
  AzureTts({required this.key, required this.region, String? voice})
    : voice = voice ?? 'fa-IR-FaridNeural';

  static AzureTts? fromEnvironment() {
    final key = Platform.environment['AZURE_SPEECH_KEY'];
    final region = Platform.environment['AZURE_SPEECH_REGION'];
    if (key == null || region == null) return null;
    return AzureTts(key: key, region: region);
  }

  final String key;
  final String region;
  final String voice;

  @override
  String get id => 'azure:$voice';

  @override
  Future<List<int>?> synthesize(String text) async {
    final uri = Uri.parse(
      'https://$region.tts.speech.microsoft.com/cognitiveservices/v1',
    );
    final body = '<voice name="$voice">${_escapeXml(text)}</voice>';
    final ssml = '<speak version="1.0" xml:lang="fa-IR">$body</speak>';

    final client = HttpClient();
    try {
      final request = await client.postUrl(uri);
      request.headers
        ..set('Ocp-Apim-Subscription-Key', key)
        ..set('Content-Type', 'application/ssml+xml')
        ..set('X-Microsoft-OutputFormat', 'audio-24khz-48kbitrate-mono-mp3');
      request.add(utf8.encode(ssml));
      final response = await request.close();
      if (response.statusCode != 200) {
        final body = await response.transform(utf8.decoder).join();
        throw HttpException(
          'Azure TTS failed (${response.statusCode}): $body',
          uri: uri,
        );
      }
      return [
        for (final chunk in await response.toList()) ...chunk,
      ];
    } finally {
      client.close();
    }
  }

  String _escapeXml(String s) => s
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;');
}

/// Local Piper neural TTS (ADR-0008): synthesis runs offline on the authoring
/// machine — no account, no network, no key. Requires the `piper` binary
/// (override with `PIPER_BIN`) and `ffmpeg` on PATH; both are authoring-time
/// dependencies only, never needed in CI (see [CacheOnlyTts]).
class PiperTts implements TtsAdapter {
  PiperTts({required this.model, String? piperBin, String? ffmpegBin})
    : piperBin = piperBin ?? Platform.environment['PIPER_BIN'] ?? 'piper',
      ffmpegBin = ffmpegBin ?? 'ffmpeg',
      // Voice identity = model name + content hash, so swapping or updating
      // the .onnx invalidates cached audio exactly like a voice change.
      id =
          'piper:${p.basenameWithoutExtension(model.path)}'
          '@${sha256.convert(model.readAsBytesSync()).toString().substring(
            0,
            8,
          )}';

  static PiperTts? fromEnvironment() {
    final model = Platform.environment['PIPER_MODEL'];
    if (model == null) return null;
    return PiperTts(model: File(model));
  }

  final File model;
  final String piperBin;
  final String ffmpegBin;

  @override
  final String id;

  @override
  Future<List<int>?> synthesize(String text) async {
    final tmp = Directory.systemTemp.createTempSync('miras_piper');
    try {
      final wav = p.join(tmp.path, 'out.wav');
      final piper = await Process.start(piperBin, [
        '--model',
        model.path,
        '--output_file',
        wav,
      ]);
      piper.stdin.writeln(text);
      await piper.stdin.close();
      final errOut = piper.stderr.transform(utf8.decoder).join();
      await piper.stdout.drain<void>();
      if (await piper.exitCode != 0) {
        throw ProcessException(piperBin, [], 'piper failed: ${await errOut}');
      }
      // Match AzureTts's output profile (24 kHz mono 48 kbps mp3) so pack
      // size and playback behavior stay uniform across adapters.
      final mp3 = p.join(tmp.path, 'out.mp3');
      final ffmpeg = await Process.run(ffmpegBin, [
        '-y',
        '-i',
        wav,
        '-ar',
        '24000',
        '-ac',
        '1',
        '-b:a',
        '48k',
        mp3,
      ]);
      if (ffmpeg.exitCode != 0) {
        throw ProcessException(
          ffmpegBin,
          [],
          'ffmpeg failed: ${ffmpeg.stderr}',
        );
      }
      return File(mp3).readAsBytes();
    } finally {
      tmp.deleteSync(recursive: true);
    }
  }
}

/// Replays the committed audio cache with no synthesis backend, so CI and
/// contributor builds produce audio-complete packs deterministically without
/// piper installed (ADR-0008). The generating adapter records its [id] in an
/// `ADAPTER` marker file inside the cache (see [CachedTts.get]); a cache miss
/// is a hard error — audio silently missing from a pack means listening
/// exercises silently vanish from lessons.
class CacheOnlyTts implements TtsAdapter {
  CacheOnlyTts(Directory cacheDir) : id = _readId(cacheDir);

  static String _readId(Directory cacheDir) {
    final marker = File(p.join(cacheDir.path, 'ADAPTER'));
    if (!marker.existsSync()) {
      throw StateError(
        'audio cache has no ADAPTER marker (${marker.path}); '
        'generate audio first, e.g. --tts piper',
      );
    }
    return marker.readAsStringSync().trim();
  }

  @override
  final String id;

  @override
  Future<List<int>?> synthesize(String text) => throw StateError(
    'audio cache miss for "$text" (tts=cache); '
    'regenerate the cache, e.g. --tts piper',
  );
}

/// Content-hash cache in front of a [TtsAdapter]: unchanged text never
/// re-synthesizes (keeps rebuilds fast and API costs near zero).
class CachedTts {
  CachedTts(this.adapter, this.cacheDir);

  final TtsAdapter adapter;
  final Directory cacheDir;

  /// Returns cached-or-synthesized audio bytes for [text], or null when the
  /// backend is unavailable (NoopTts).
  Future<List<int>?> get(String text) async {
    final hash = sha256
        .convert(utf8.encode('${adapter.id}\x00$text'))
        .toString();
    final file = File(p.join(cacheDir.path, '$hash.mp3'));
    if (file.existsSync()) return file.readAsBytes();

    final bytes = await adapter.synthesize(text);
    if (bytes == null) return null;
    file.parent.createSync(recursive: true);
    await file.writeAsBytes(bytes);
    // Record which adapter produced the cache so CacheOnlyTts can replay it
    // under the same cache keys.
    File(p.join(cacheDir.path, 'ADAPTER')).writeAsStringSync(adapter.id);
    return bytes;
  }

  /// Deterministic asset name for [text] inside the pack.
  String assetName(String text) {
    final hash = sha256
        .convert(utf8.encode('${adapter.id}\x00$text'))
        .toString();
    return 'audio/${hash.substring(0, 16)}.mp3';
  }
}
