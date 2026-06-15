class DurationFormatter {
  DurationFormatter._();

  /// Formats a duration given in [seconds] to a "MM:SS" string.
  ///
  /// Examples:
  ///   95  → "01:35"
  ///   0   → "00:00"
  ///   3661 → "61:01"
  static String format(int seconds) {
    final int minutes = seconds ~/ 60;
    final int remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  /// Formats a [Duration] object to a "MM:SS" string.
  static String fromDuration(Duration duration) {
    return format(duration.inSeconds);
  }
}
