/// Configuration for FlutterLens' in-memory capture layer.
final class FlutterLensConfig {
  /// Creates configuration for FlutterLens.
  const FlutterLensConfig({
    this.enabled = true,
    this.maxTransactions = 200,
    this.environment,
  }) : assert(maxTransactions > 0, 'maxTransactions must be greater than zero.');

  /// Whether new transactions should be captured.
  final bool enabled;

  /// Maximum number of most-recent transactions kept in memory.
  final int maxTransactions;

  /// Optional label supplied by the host app, for example `staging`.
  final String? environment;
}
