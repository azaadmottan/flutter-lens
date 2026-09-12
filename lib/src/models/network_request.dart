import 'dart:collection';

/// Immutable request information captured before an HTTP call completes.
final class NetworkRequest {
  /// Creates a captured request.
  NetworkRequest({
    required this.method,
    required this.url,
    Map<String, String>? headers,
    Map<String, Object?>? queryParameters,
    this.body,
  })  : headers = UnmodifiableMapView(Map.of(headers ?? const {})),
        queryParameters = UnmodifiableMapView(
          Map.of(queryParameters ?? const {}),
        );

  /// HTTP method, such as `GET` or `POST`.
  final String method;

  /// Complete request URL.
  final Uri url;

  /// Request headers.
  final Map<String, String> headers;

  /// Query parameters supplied by the client.
  final Map<String, Object?> queryParameters;

  /// Request payload, when supplied by the client.
  final Object? body;
}
