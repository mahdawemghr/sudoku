import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

import 'tone_generator.dart';

/// Plays game sound effects via programmatically generated WAV tones.
/// No asset files required — all audio is synthesised at runtime.
class SoundService {
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

  void setSoundEnabled(bool enabled) => _soundEnabled = enabled;

  Future<void> playCorrect() async {
    await _haptic(HapticFeedback.lightImpact);
    await _play(ToneGenerator.correct);
  }

  Future<void> playWrong() async {
    await _haptic(HapticFeedback.mediumImpact);
    await _play(ToneGenerator.wrong);
  }

  Future<void> playWin() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _play(ToneGenerator.win);
  }

  Future<void> playLose() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _play(ToneGenerator.lose);
  }

  Future<void> playHint() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.hint);
  }

  Future<void> playUndo() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.undo);
  }

  Future<void> playErase() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.erase);
  }

  Future<void> playTap() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.tap);
  }

  Future<void> playSelect() async {
    await _haptic(HapticFeedback.selectionClick);
    await _play(ToneGenerator.select);
  }

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
