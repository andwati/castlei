import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

enum MoveSound { move, capture, check, end }

/// Short original sound effects plus matching haptics. Both are gated by the
/// user's settings and never throw into the UI.
class Sfx {
  static final _players = <MoveSound, AudioPlayer>{};

  static Future<void> play(
    MoveSound kind, {
    required bool sound,
    required bool haptics,
  }) async {
    if (haptics) {
      switch (kind) {
        case MoveSound.move:
          HapticFeedback.selectionClick();
        case MoveSound.capture:
          HapticFeedback.mediumImpact();
        case MoveSound.check:
        case MoveSound.end:
          HapticFeedback.heavyImpact();
      }
    }
    if (!sound) return;
    try {
      final player = _players.putIfAbsent(kind, () {
        final p = AudioPlayer()..setPlayerMode(PlayerMode.lowLatency);
        return p;
      });
      await player.stop();
      await player.play(AssetSource('sounds/${kind.name}.wav'), volume: .8);
    } catch (_) {}
  }

  /// Picks the effect for a move from its SAN (x = capture, + / # = check).
  static MoveSound forSan(String san) => san.contains('#') || san.contains('+')
      ? MoveSound.check
      : san.contains('x')
      ? MoveSound.capture
      : MoveSound.move;
}
