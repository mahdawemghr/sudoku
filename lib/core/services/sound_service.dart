import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'tone_generator.dart';

/// The sound-playing surface GameController depends on. Lets tests inject
/// a no-op fake instead of constructing a real SoundService, which eagerly
/// creates a platform AudioPlayer that needs a running app/platform channel.
abstract class GameSoundPlayer {
  void setSoundEnabled(bool enabled);
  Future<void> playCorrect();
  Future<void> playWrong();
  Future<void> playWin();
  Future<void> playLose();
  Future<void> playHint();
  Future<void> playUndo();
  Future<void> playErase();
  Future<void> playTap();
  Future<void> playSelect();
  Future<void> playDismiss();
}

/// Plays game sound effects via programmatically generated WAV tones.
/// No asset files required — all audio is synthesised at runtime.
class SoundService implements GameSoundPlayer {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;

  SoundService._() {
    // Pre-generate all tones eagerly so first playback has no lag.
    ToneGenerator.correct;
    ToneGenerator.wrong;
    ToneGenerator.win;
    ToneGenerator.lose;
    ToneGenerator.hint;
    ToneGenerator.undo;
    ToneGenerator.erase;
    ToneGenerator.tap;
    ToneGenerator.select;
    ToneGenerator.dismiss;
  }

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  @override
  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;

  @override
  Future<void> playCorrect() async {
    await _haptic(HapticFeedback.lightImpact);
    await _play(ToneGenerator.correct);
  }

  @override
  Future<void> playWrong() async {
    await _haptic(HapticFeedback.mediumImpact);
    await _play(ToneGenerator.wrong);
  }

  @override
  Future<void> playWin() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _play(ToneGenerator.win);
  }

  @override
  Future<void> playLose() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _play(ToneGenerator.lose);
  }

  @override
  Future<void> playHint() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.hint);
  }

  @override
  Future<void> playUndo() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.undo);
  }

  @override
  Future<void> playErase() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.erase);
  }

  @override
  Future<void> playTap() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.tap);
  }

  @override
  Future<void> playSelect() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.select);
  }

  @override
  Future<void> playDismiss() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.dismiss);
  }

  Future<void> _haptic(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {}
  }

  Future<void> _play(Uint8List bytes) async {
    if (!_soundEnabled) return;
    try {
      await _player.play(BytesSource(bytes));
    } catch (_) {}
  }

  void dispose() => _player.dispose();
}
