import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

/// Short UI feedback sounds (M4 sound design, shipped in M6): answer
/// right/wrong and lesson completion.
enum Sfx { correct, wrong, complete }

/// Distinct from `AudioService`: these are app assets, not pack audio, and
/// they respect the user's sound toggle — listening-exercise clips do not.
// One method today, but the interface/noop split is the house test seam for
// platform services (see NotificationService, HapticsService).
// ignore: one_member_abstracts
abstract interface class SfxService {
  /// Plays [sfx] iff the user's sound setting allows it. Fire-and-forget:
  /// never throws, never blocks the flow it decorates.
  Future<void> play(Sfx sfx);
}

class JustAudioSfxService implements SfxService {
  /// [enabled] is the live sound setting (`watchProfile().map(...)` at
  /// bootstrap); the service caches the latest value so playing costs no
  /// database read.
  JustAudioSfxService({required Stream<bool> enabled}) {
    enabled.listen((value) => _enabled = value);
  }

  var _enabled = true;
  final _players = <Sfx, AudioPlayer>{};

  Future<AudioPlayer> _playerFor(Sfx sfx) async {
    final cached = _players[sfx];
    if (cached != null) return cached;
    final player = AudioPlayer();
    await player.setAsset('assets/sfx/${sfx.name}.mp3');
    return _players[sfx] = player;
  }

  @override
  Future<void> play(Sfx sfx) async {
    if (!_enabled) return;
    try {
      final player = await _playerFor(sfx);
      await player.seek(Duration.zero);
      unawaited(player.play());
    } on Exception {
      // A feedback sound must never break the lesson flow.
    }
  }
}

/// Records plays for tests.
class NoopSfxService implements SfxService {
  NoopSfxService();

  final played = <Sfx>[];

  @override
  Future<void> play(Sfx sfx) async => played.add(sfx);
}

/// Real instance provided at bootstrap; tests override with the no-op.
final sfxServiceProvider = Provider<SfxService>(
  (ref) => throw UnimplementedError(
    'sfxServiceProvider must be overridden at app bootstrap',
  ),
);
