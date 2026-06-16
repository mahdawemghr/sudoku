import 'dart:math' as math;
import 'dart:typed_data';

/// Generates WAV audio bytes in pure Dart — no asset files required.
/// All sounds are computed once at first access and cached.
class ToneGenerator {
  ToneGenerator._();

  static const int _sr = 44100;

  // --- pre-built sounds ---

  /// Short ascending two-note chime — correct number placed.
  static final Uint8List correct = _twoNote(
    f1: 440.0, ms1: 75,
    f2: 659.25, ms2: 110,
  );

  /// Low short buzz — wrong number placed (lives remain).
  static final Uint8List wrong = _single(185.0, 170,
      amplitude: 0.58, releaseFrac: 0.50);

  /// Four-note ascending arpeggio — puzzle won.
  static final Uint8List win = _arpeggio(
    freqs: [523.25, 659.25, 783.99, 1046.50],
    noteDuration: 115,
    gapMs: 10,
    lastDuration: 280,
  );

  /// Three-note descending fall — all lives lost.
  static final Uint8List lose = _arpeggio(
    freqs: [392.0, 311.13, 195.99],
    noteDuration: 160,
    gapMs: 18,
    lastDuration: 340,
    amplitude: 0.60,
  );

  /// High bright ping — hint revealed.
  static final Uint8List hint = _single(1318.51, 70,
      amplitude: 0.52, attackFrac: 0.03, releaseFrac: 0.55);

  /// Neutral soft tick — undo action.
  static final Uint8List undo = _single(440.0, 65,
      amplitude: 0.42, releaseFrac: 0.45);

  /// Low soft click — erase action.
  static final Uint8List erase = _single(277.18, 55,
      amplitude: 0.38, releaseFrac: 0.40);

  /// Soft, brief click — navigation button press.
  static final Uint8List tap = _single(523.25, 40,
      amplitude: 0.40, attackFrac: 0.10, releaseFrac: 0.45);

  /// Quieter, shorter tick — cell selection / notes toggle (fires often).
  static final Uint8List select = _single(659.25, 25,
      amplitude: 0.26, attackFrac: 0.10, releaseFrac: 0.50);

  /// Soft descending blip — hint banner dismissed.
  static final Uint8List dismiss = _twoNote(
    f1: 587.33, ms1: 30,
    f2: 440.0, ms2: 35,
  );

  // --- builders ---

  static Uint8List _single(
    double freq,
    int ms, {
    double amplitude = 0.62,
    double attackFrac = 0.06,
    double releaseFrac = 0.30,
  }) =>
      _wav(_sine(
        freq: freq,
        ms: ms,
        amplitude: amplitude,
        attackFrac: attackFrac,
        releaseFrac: releaseFrac,
      ));

  static Uint8List _twoNote({
    required double f1,
    required int ms1,
    required double f2,
    required int ms2,
  }) =>
      _wav([
        ..._sine(freq: f1, ms: ms1),
        ..._sine(freq: f2, ms: ms2),
      ]);

  static Uint8List _arpeggio({
    required List<double> freqs,
    required int noteDuration,
    required int gapMs,
    required int lastDuration,
    double amplitude = 0.65,
  }) {
    final gap = List<double>.filled(
      (gapMs * _sr / 1000).round(),
      0.0,
    );
    final samples = <double>[];
    for (int i = 0; i < freqs.length; i++) {
      final dur = i == freqs.length - 1 ? lastDuration : noteDuration;
      samples.addAll(_sine(freq: freqs[i], ms: dur, amplitude: amplitude));
      if (i < freqs.length - 1) samples.addAll(gap);
    }
    return _wav(samples);
  }

  // --- core DSP ---

  static List<double> _sine({
    required double freq,
    required int ms,
    double amplitude = 0.65,
    double attackFrac = 0.06,
    double releaseFrac = 0.30,
  }) {
    final n = (ms * _sr / 1000).round();
    final attack = (n * attackFrac).round().clamp(1, n);
    final release = (n * releaseFrac).round().clamp(1, n);
    final buf = List<double>.filled(n, 0.0);
    for (int i = 0; i < n; i++) {
      final env = i < attack
          ? i / attack
          : i >= n - release
              ? (n - i) / release
              : 1.0;
      buf[i] = amplitude * env * math.sin(2 * math.pi * freq * i / _sr);
    }
    return buf;
  }

  // --- WAV encoding ---

  static Uint8List _wav(List<double> samples) {
    final dataSize = samples.length * 2;
    final buf = ByteData(44 + dataSize);
    int o = 0;

    void str(String s) {
      for (final c in s.codeUnits) {
        buf.setUint8(o++, c);
      }
    }

    void u16(int v) { buf.setUint16(o, v, Endian.little); o += 2; }
    void u32(int v) { buf.setUint32(o, v, Endian.little); o += 4; }

    str('RIFF'); u32(36 + dataSize); str('WAVE');
    str('fmt '); u32(16); u16(1); u16(1);        // PCM, mono
    u32(_sr); u32(_sr * 2); u16(2); u16(16);     // sampleRate, byteRate, blockAlign, bitsPerSample
    str('data'); u32(dataSize);

    for (final s in samples) {
      buf.setInt16(o, (s.clamp(-1.0, 1.0) * 32767).round(), Endian.little);
      o += 2;
    }

    return buf.buffer.asUint8List();
  }
}
