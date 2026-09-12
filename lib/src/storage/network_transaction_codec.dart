import 'dart:convert';

import '../models/network_error.dart';
import '../models/network_request.dart';
import '../models/network_response.dart';
import '../models/network_transaction.dart';

/// Converts network transactions to a JSON-safe representation for storage.
final class NetworkTransactionCodec {
  NetworkTransactionCodec._();

  /// Encodes [transaction] as a JSON string.
  static String encode(NetworkTransaction transaction) =>
      jsonEncode(_transactionToJson(transaction));

  /// Decodes a transaction previously produced by [encode].
  static NetworkTransaction decode(String source) {
    final value = jsonDecode(source);
    if (value is! Map<String, dynamic>) {
      throw const FormatException('Transaction must be a JSON object.');
    }

    final request = _map(value['request'], 'request');
    final responseValue = value['response'];
    final errorValue = value['error'];

    return NetworkTransaction(
      id: _string(value['id'], 'id'),
      request: NetworkRequest(
        method: _string(request['method'], 'request.method'),
        url: Uri.parse(_string(request['url'], 'request.url')),
        headers: _stringMap(request['headers']),
        queryParameters: _objectMap(request['queryParameters']),
        body: request['body'],
      ),
      response: responseValue == null ? null : _responseFromJson(_map(responseValue, 'response')),
      error: errorValue == null ? null : _errorFromJson(_map(errorValue, 'error')),
      timestamp: DateTime.parse(_string(value['timestamp'], 'timestamp')),
      duration: Duration(microseconds: _int(value['durationMicros'], 'durationMicros')),
    );
  }

  static Map<String, Object?> _transactionToJson(NetworkTransaction transaction) => {
        'id': transaction.id,
        'timestamp': transaction.timestamp.toIso8601String(),
        'durationMicros': transaction.duration.inMicroseconds,
        'request': {
          'method': transaction.request.method,
          'url': transaction.request.url.toString(),
          'headers': transaction.request.headers,
          'queryParameters': _jsonSafe(transaction.request.queryParameters),
          'body': _jsonSafe(transaction.request.body),
        },
        'response': transaction.response == null
            ? null
            : {
                'statusCode': transaction.response!.statusCode,
                'statusMessage': transaction.response!.statusMessage,
                'headers': transaction.response!.headers,
                'body': _jsonSafe(transaction.response!.body),
              },
        'error': transaction.error == null
            ? null
            : {
                'type': transaction.error!.type,
                'message': transaction.error!.message,
                'stackTrace': transaction.error!.stackTrace?.toString(),
              },
      };

  static NetworkResponse _responseFromJson(Map<String, dynamic> value) => NetworkResponse(
        statusCode: _int(value['statusCode'], 'response.statusCode'),
        statusMessage: value['statusMessage'] as String?,
        headers: _stringMap(value['headers']),
        body: value['body'],
      );

  static NetworkError _errorFromJson(Map<String, dynamic> value) => NetworkError(
        type: _string(value['type'], 'error.type'),
        message: _string(value['message'], 'error.message'),
        stackTrace: value['stackTrace'] is String
            ? StackTrace.fromString(value['stackTrace'] as String)
            : null,
      );

  static Object? _jsonSafe(Object? value) {
    if (value == null || value is num || value is bool || value is String) {
      return value;
    }
    if (value is DateTime) {
      return value.toIso8601String();
    }
    if (value is Uri) {
      return value.toString();
    }
    if (value is Iterable<Object?>) {
      return value.map(_jsonSafe).toList();
    }
    if (value is Map<Object?, Object?>) {
      return value.map((key, item) => MapEntry(key.toString(), _jsonSafe(item)));
    }
    return value.toString();
  }

  static Map<String, dynamic> _map(Object? value, String field) {
    if (value is! Map<String, dynamic>) {
      throw FormatException('$field must be a JSON object.');
    }
    return value;
  }

  static Map<String, String> _stringMap(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const {};
    }
    return value.map((key, item) => MapEntry(key, item.toString()));
  }

  static Map<String, Object?> _objectMap(Object? value) {
    if (value is! Map<String, dynamic>) {
      return const {};
    }
    return Map<String, Object?>.from(value);
  }

  static String _string(Object? value, String field) {
    if (value is! String) {
      throw FormatException('$field must be a string.');
    }
    return value;
  }

  static int _int(Object? value, String field) {
    if (value is! int) {
      throw FormatException('$field must be an integer.');
    }
    return value;
  }
}
