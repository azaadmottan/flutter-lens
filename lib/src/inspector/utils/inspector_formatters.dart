part of '../flutter_lens_inspector.dart';

String _pathWithQuery(Uri uri) => uri.hasQuery ? '${uri.path}?${uri.query}' : uri.path;

String _durationLabel(Duration duration) => duration.inMilliseconds < 1000
    ? '${duration.inMilliseconds} ms'
    : '${(duration.inMilliseconds / 1000).toStringAsFixed(2)} s';

String _timeLabel(DateTime timestamp) =>
    '${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}:${timestamp.second.toString().padLeft(2, '0')}';

String _fullTimeLabel(DateTime timestamp) =>
    '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${_timeLabel(timestamp)}';

String _prettyValue(Object? value) {
  if (value == null) {
    return '';
  }
  if (value is String) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(value));
    } on FormatException {
      return value;
    }
  }
  try {
    return const JsonEncoder.withIndent('  ').convert(value);
  } on JsonUnsupportedObjectError {
    return value.toString();
  }
}
