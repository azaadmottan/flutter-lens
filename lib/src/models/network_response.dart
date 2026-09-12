import 'dart:collection';

/// Immutable response information captured after a successful HTTP call.
final class NetworkResponse {
  /// Creates a captured response.
  NetworkResponse({
    required this.statusCode,
    this.statusMessage,
    Map<String, String>? headers,
    this.body,
  }) : headers = UnmodifiableMapView(Map.of(headers ?? const {}));

  /// HTTP status code returned by the server.
  final int statusCode;

  /// Optional HTTP status message.
  final String? statusMessage;

  /// Response headers.
  final Map<String, String> headers;

  /// Response payload.
  final Object? body;
}
