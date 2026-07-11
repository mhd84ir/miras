import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

/// Plays pre-baked pack audio (ADR-0005/ADR-0008): short local asset clips,
/// currently vocabulary pronunciation for listening exercises. Local-first —
/// no streaming, no network, ever.
abstract interface class AudioService {
  /// True while a clip is audibly playing (drives the play-button state).
  Stream<bool> get playing;

  /// Plays the pack asset at [assetPath] (e.g. `audio/<hash>.mp3`), replacing
  /// any current playback. Returns once playback has started, not finished.
  Future<void> playAsset(String assetPath);

  Future<void> stop();
}

/// just_audio implementation (ExoPlayer-backed on Android).
class JustAudioService implements AudioService {
  JustAudioService([AudioPlayer? player]) : _player = player ?? AudioPlayer();

  final AudioPlayer _player;

  @override
  Stream<bool> get playing => _player.playerStateStream.map(
    (s) =>
        s.playing &&
        s.processingState != ProcessingState.completed &&
        s.processingState != ProcessingState.idle,
  );

  @override
  Future<void> playAsset(String assetPath) async {
    try {
      // setAsset resets position, so a replay restarts from the top; the
      // load is a bundled file read, effectively instant.
      await _player.setAsset('assets/content/$assetPath');
      // play() completes when playback finishes — deliberately unawaited.
      unawaited(_player.play());
    } on Exception catch (error, stackTrace) {
      // Playback must never break the flow, but a failing pack asset is a
      // real content defect — surface it to crash reporting, not silence.
      // (captureException is a no-op when the DSN is absent.)
      unawaited(Sentry.captureException(error, stackTrace: stackTrace));
    }
  }

  @override
  Future<void> stop() => _player.stop();
}

/// No-op for tests.
class NoopAudioService implements AudioService {
  const NoopAudioService();

  @override
  Stream<bool> get playing => const Stream.empty();

  @override
  Future<void> playAsset(String assetPath) async {}

  @override
  Future<void> stop() async {}
}

/// Real instance provided at bootstrap; tests override with the no-op.
final audioServiceProvider = Provider<AudioService>(
  (ref) => throw UnimplementedError(
    'audioServiceProvider must be overridden at app bootstrap',
  ),
);

/// Live playback indicator for the active listening exercise's play button.
final audioPlayingProvider = StreamProvider<bool>(
  (ref) => ref.watch(audioServiceProvider).playing,
);
