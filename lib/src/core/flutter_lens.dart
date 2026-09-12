import 'dart:async';

import '../models/network_transaction.dart';
import 'flutter_lens_config.dart';

/// Entry point and in-memory transaction registry for FlutterLens.
///
/// HTTP client integrations call [record] only after their original request has
/// completed. Failures in this observational layer are contained so that the
/// host application's networking behavior remains unaffected.
final class FlutterLens {
  FlutterLens._();

  static FlutterLensConfig _config = const FlutterLensConfig();
  static final List<NetworkTransaction> _transactions = [];
  static final StreamController<List<NetworkTransaction>> _changes =
      StreamController<List<NetworkTransaction>>.broadcast();

  /// Initializes the in-memory capture layer.
  ///
  /// Calling this again replaces the configuration and trims existing history
  /// if the maximum transaction count was reduced.
  static void initialize({
    bool enabled = true,
    int maxTransactions = 200,
    String? environment,
  }) {
    _config = FlutterLensConfig(
      enabled: enabled,
      maxTransactions: maxTransactions,
      environment: environment,
    );
    _trimToLimit();
    _emit();
  }

  /// Current FlutterLens configuration.
  static FlutterLensConfig get config => _config;

  /// A read-only snapshot of captured transactions, newest first.
  static List<NetworkTransaction> get transactions =>
      List<NetworkTransaction>.unmodifiable(_transactions);

  /// Stream of transaction snapshots, newest first.
  static Stream<List<NetworkTransaction>> get transactionChanges => _changes.stream;

  /// Records a completed request lifecycle.
  ///
  /// This method deliberately never throws: integrations must not allow a
  /// capture failure to interfere with the application's original HTTP call.
  static void record(NetworkTransaction transaction) {
    if (!_config.enabled) {
      return;
    }

    try {
      _transactions.insert(0, transaction);
      _trimToLimit();
      _emit();
    } catch (_) {
      // FlutterLens is observational and must stay invisible to the host app.
    }
  }

  /// Removes all in-memory transactions.
  static void clear() {
    _transactions.clear();
    _emit();
  }

  static void _trimToLimit() {
    if (_transactions.length > _config.maxTransactions) {
      _transactions.removeRange(_config.maxTransactions, _transactions.length);
    }
  }

  static void _emit() {
    if (!_changes.isClosed) {
      _changes.add(transactions);
    }
  }
}
