import 'package:flutter_lens/flutter_lens.dart';
import 'package:flutter_test/flutter_test.dart';

NetworkTransaction transaction(String id) => NetworkTransaction(
      id: id,
      request: NetworkRequest(method: 'GET', url: Uri.parse('https://example.com/$id')),
      response: NetworkResponse(statusCode: 200),
      timestamp: DateTime.utc(2026),
      duration: const Duration(milliseconds: 10),
    );

void main() {
  setUp(() {
    FlutterLens.initialize(maxTransactions: 2);
    FlutterLens.clear();
  });

  test('keeps newest transactions within its configured limit', () {
    FlutterLens.record(transaction('one'));
    FlutterLens.record(transaction('two'));
    FlutterLens.record(transaction('three'));

    expect(FlutterLens.transactions.map((item) => item.id), ['three', 'two']);
  });

  test('does not capture while disabled', () {
    FlutterLens.initialize(enabled: false);

    FlutterLens.record(transaction('one'));

    expect(FlutterLens.transactions, isEmpty);
  });
}
