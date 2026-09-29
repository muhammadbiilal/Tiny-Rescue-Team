import 'package:flame_audio/flame_audio.dart';
import 'package:flutter/foundation.dart';

import '../simulation/engine.dart';

/// Placeholder tones. Audio failure never affects gameplay.
class AudioService {
  bool music;
  bool effects;
  final bool enabled;
  bool _musicPlaying = false;

  AudioService({this.music = true, this.effects = true, this.enabled = true});

  static const _ui = 'tap.wav';

  Future<void> preload() async {
    if (!enabled) return;
    try {
      await FlameAudio.audioCache.loadAll([
        'tap.wav',
        'move.wav',
        'pickup.wav',
        'rescue.wav',
        'action.wav',
        'warning.wav',
        'win.wav',
        'theme.wav',
      ]);
    } catch (e) {
      debugPrint('audio preload failed: $e');
    }
  }

  void tap() {
    if (!enabled || !effects) return;
    FlameAudio.play(_ui, volume: 0.4).ignore();
  }

  void playEvent(EventType type) {
    if (!enabled || !effects) return;
    final file = switch (type) {
      EventType.claim || EventType.redirect => 'move.wav',
      EventType.pickUp || EventType.pickSupplies => 'pickup.wav',
      EventType.dropOff ||
      EventType.stabilized ||
      EventType.objectiveMet => 'rescue.wav',
      EventType.cleared ||
      EventType.ability ||
      EventType.repaired ||
      EventType.extinguished ||
      EventType.bridged => 'action.wav',
      EventType.blocked ||
      EventType.fail ||
      EventType.stall ||
      EventType.spread ||
      EventType.collapse ||
      EventType.flooded ||
      EventType.commandRejected => 'warning.wav',
      EventType.win => 'win.wav',
      EventType.deploy => _ui,
      _ => null,
    };
    if (file == null) return;
    FlameAudio.play(file, volume: 0.55).ignore();
  }

  Future<void> updateMusic() async {
    if (!enabled) return;
    try {
      if (music && !_musicPlaying) {
        await FlameAudio.bgm.play('theme.wav', volume: 0.25);
        _musicPlaying = true;
      } else if (!music && _musicPlaying) {
        await FlameAudio.bgm.stop();
        _musicPlaying = false;
      }
    } catch (e) {
      debugPrint('music failed: $e');
    }
  }
}
