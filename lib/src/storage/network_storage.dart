import '../models/network_transaction.dart';

/// Persistent storage contract for captured network transactions.
abstract interface class NetworkStorage {
  /// Reads all saved transactions, ordered newest first.
  Future<List<NetworkTransaction>> readAll();

  /// Replaces the saved transaction history.
  Future<void> writeAll(List<NetworkTransaction> transactions);

  /// Deletes all saved transactions.
  Future<void> clear();
}
