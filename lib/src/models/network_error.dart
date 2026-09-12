/// Immutable information about a failed HTTP call.
final class NetworkError {
  /// Creates a captured error.
  const NetworkError({
    required this.type,
    required this.message,
    this.stackTrace,
  });

  /// Client-defined error category, such as `timeout` or `network`.
  final String type;

  /// Human-readable error message.
  final String message;

  /// Stack trace captured by the HTTP client, when available.
  final StackTrace? stackTrace;
}
