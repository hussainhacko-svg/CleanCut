/// Formats microseconds as `m:ss` or `h:mm:ss` for display.
///
/// Negative values are treated as zero.
String formatDurationUs(int micros) {
  final totalSeconds = (micros < 0 ? 0 : micros) ~/ 1000000;
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  if (hours > 0) {
    return '$hours:${minutes.toString().padLeft(2, '0')}:$seconds';
  }
  return '$minutes:$seconds';
}

/// Formats microseconds as a zero-padded clock, `mm:ss` or `h:mm:ss`, as
/// in the editor's "00:06 / 00:12" readout.
///
/// Negative values are treated as zero.
String formatClockUs(int micros) {
  final totalSeconds = (micros < 0 ? 0 : micros) ~/ 1000000;
  final hours = totalSeconds ~/ 3600;
  final minutes = ((totalSeconds % 3600) ~/ 60).toString().padLeft(2, '0');
  final seconds = (totalSeconds % 60).toString().padLeft(2, '0');
  return hours > 0 ? '$hours:$minutes:$seconds' : '$minutes:$seconds';
}
