import 'package:flutter_lens/flutter_lens.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('records a completed network transaction', () {
    FlutterLens.initialize();
    FlutterLens.clear();

    FlutterLens.record(
      NetworkTransaction(
        id: 'request-1',
        request: NetworkRequest(
          method: 'GET',
          url: Uri.parse('https://api.example.com/profile'),
        ),
        response: NetworkResponse(statusCode: 200),
        timestamp: DateTime.utc(2026),
        duration: const Duration(milliseconds: 120),
      ),
    );

    expect(FlutterLens.transactions.single.statusCode, 200);
  });
}
