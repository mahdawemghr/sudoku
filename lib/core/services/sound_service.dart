import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

/// Manages haptic feedback and sound effects.
///
/// Sound files go in assets/sounds/:
///   correct.mp3  — placed when a correct number is entered
///   wrong.mp3    — placed when a wrong number is entered
///   win.mp3      — played when the puzzle is completed
///   lose.mp3     — played when all lives are lost
///
/// Sounds are silently skipped if the files are missing or if sound is disabled.
class SoundService {
  static final SoundService _instance = SoundService._();
  factory SoundService() => _instance;
  SoundService._();

  final AudioPlayer _player = AudioPlayer();
  bool _soundEnabled = true;

  void setSoundEnabled(bool enabled) {
    _soundEnabled = enabled;
  }

  Future<void> playCorrect() async {
    await _haptic(HapticFeedback.lightImpact);
    await _play('sounds/correct.mp3');
  }

  Future<void> playWrong() async {
    await _haptic(HapticFeedback.mediumImpact);
    await _play('sounds/wrong.mp3');
  }

  Future<void> playWin() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _play('sounds/win.mp3');
  }

  Future<void> playLose() async {
    await _haptic(HapticFeedback.heavyImpact);
    await _play('sounds/lose.mp3');
  }

  Future<void> _haptic(Future<void> Function() fn) async {
    try {
      await fn();
    } catch (_) {}
  }

  Future<void> _play(String assetPath) async {
    if (!_soundEnabled) return;
    try {
      await _player.play(AssetSource(assetPath));
    } catch (_) {
      // Sound file missing or audio unavailable — silently skip.
    }
  }

  void dispose() {
    _player.dispose();
  }
}
