import 'dart:convert';

import 'package:flutter/material.dart';

import '../core/flutter_lens.dart';
import '../models/network_transaction.dart';

/// Full-screen, in-app UI for browsing captured network transactions.
final class FlutterLensInspector extends StatefulWidget {
  /// Creates the FlutterLens inspector.
  const FlutterLensInspector({super.key});

  @override
  State<FlutterLensInspector> createState() => _FlutterLensInspectorState();
}

final class _FlutterLensInspectorState extends State<FlutterLensInspector> {
  final TextEditingController _searchController = TextEditingController();
  _TransactionFilter _filter = _TransactionFilter.all;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('FlutterLens'),
          actions: [
            IconButton(
              tooltip: 'Clear network history',
              icon: const Icon(Icons.delete_outline),
              onPressed: _confirmClear,
            ),
          ],
        ),
        body: StreamBuilder<List<NetworkTransaction>>(
          stream: FlutterLens.transactionChanges,
          initialData: FlutterLens.transactions,
          builder: (context, snapshot) {
            final transactions = snapshot.data ?? const <NetworkTransaction>[];
            final visible = _filterTransactions(transactions);
            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.search),
                      hintText: 'Search requests...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                _FilterBar(
                  selected: _filter,
                  onChanged: (filter) => setState(() => _filter = filter),
                ),
                Expanded(
                  child: visible.isEmpty
                      ? _EmptyState(hasHistory: transactions.isNotEmpty)
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                          itemCount: visible.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 8),
                          itemBuilder: (context, index) => _TransactionTile(
                            transaction: visible[index],
                            onTap: () => Navigator.of(context).push<void>(
                              MaterialPageRoute<void>(
                                builder: (_) => _TransactionDetails(
                                  transaction: visible[index],
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ],
            );
          },
        ),
      );

  List<NetworkTransaction> _filterTransactions(
    List<NetworkTransaction> transactions,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    return transactions.where((transaction) {
      final matchesFilter = switch (_filter) {
        _TransactionFilter.all => true,
        _TransactionFilter.success => !transaction.isError &&
            (transaction.statusCode == null || transaction.statusCode! < 400),
        _TransactionFilter.errors => transaction.isError ||
            (transaction.statusCode != null && transaction.statusCode! >= 400),
      };
      if (!matchesFilter || query.isEmpty) {
        return matchesFilter;
      }
      final searchable = [
        transaction.request.method,
        transaction.request.url.toString(),
        transaction.request.url.path,
        transaction.statusCode?.toString() ?? '',
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList(growable: false);
  }

  Future<void> _confirmClear() async {
    if (FlutterLens.transactions.isEmpty) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear network history?'),
        content: const Text('This removes all captured requests from this device.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Clear'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) {
      FlutterLens.clear();
    }
  }
}

enum _TransactionFilter { all, success, errors }

final class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.selected, required this.onChanged});

  final _TransactionFilter selected;
  final ValueChanged<_TransactionFilter> onChanged;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: _TransactionFilter.values
              .map(
                (filter) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(switch (filter) {
                      _TransactionFilter.all => 'All',
                      _TransactionFilter.success => 'Success',
                      _TransactionFilter.errors => 'Errors',
                    }),
                    selected: filter == selected,
                    onSelected: (_) => onChanged(filter),
                  ),
                ),
              )
              .toList(growable: false),
        ),
      );
}

final class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.hasHistory});

  final bool hasHistory;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.network_check, size: 48, color: Theme.of(context).colorScheme.primary),
              const SizedBox(height: 16),
              Text(
                hasHistory ? 'No matching requests' : 'No network requests yet',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              Text(
                hasHistory
                    ? 'Try changing the search or filter.'
                    : 'API requests made by your application will appear here.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
}

final class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.transaction, required this.onTap});

  final NetworkTransaction transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = transaction.statusCode;
    final isFailure = transaction.isError || (status != null && status >= 400);
    final color = isFailure ? Theme.of(context).colorScheme.error : Colors.green;
    return Card(
      child: ListTile(
        onTap: onTap,
        leading: Icon(isFailure ? Icons.error_outline : Icons.check_circle_outline, color: color),
        title: Row(
          children: [
            _MethodLabel(method: transaction.request.method),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _pathWithQuery(transaction.request.url),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        subtitle: Text('${_durationLabel(transaction.duration)} · ${_timeLabel(transaction.timestamp)}'),
        trailing: Text(
          status?.toString() ?? 'Error',
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

final class _TransactionDetails extends StatelessWidget {
  const _TransactionDetails({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => DefaultTabController(
        length: 4,
        child: Scaffold(
          appBar: AppBar(
            title: Text('${transaction.request.method} ${_pathWithQuery(transaction.request.url)}'),
            bottom: const TabBar(
              isScrollable: true,
              tabs: [
                Tab(text: 'Overview'),
                Tab(text: 'Request'),
                Tab(text: 'Response'),
                Tab(text: 'Headers'),
              ],
            ),
          ),
          body: TabBarView(
            children: [
              _OverviewTab(transaction: transaction),
              _RequestTab(transaction: transaction),
              _ResponseTab(transaction: transaction),
              _HeadersTab(transaction: transaction),
            ],
          ),
        ),
      );
}

final class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailItem('Method', transaction.request.method),
          _DetailItem('URL', transaction.request.url.toString()),
          _DetailItem('Status', transaction.statusCode?.toString() ?? transaction.error?.type ?? 'Unknown'),
          _DetailItem('Duration', _durationLabel(transaction.duration)),
          _DetailItem('Timestamp', _fullTimeLabel(transaction.timestamp)),
          if (transaction.error != null) _DetailItem('Error', transaction.error!.message),
        ],
      );
}

final class _RequestTab extends StatelessWidget {
  const _RequestTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailItem('URL', transaction.request.url.toString()),
          _DetailItem('Method', transaction.request.method),
          _DetailItem('Query parameters', _prettyValue(transaction.request.queryParameters)),
          _DetailItem('Body', _prettyValue(transaction.request.body)),
        ],
      );
}

final class _ResponseTab extends StatelessWidget {
  const _ResponseTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailItem('Status', transaction.statusCode?.toString() ?? 'No response received'),
          _DetailItem('Status message', transaction.response?.statusMessage ?? ''),
          _DetailItem('Body', _prettyValue(transaction.response?.body)),
        ],
      );
}

final class _HeadersTab extends StatelessWidget {
  const _HeadersTab({required this.transaction});

  final NetworkTransaction transaction;

  @override
  Widget build(BuildContext context) => _DetailsList(
        children: [
          _DetailItem('Request headers', _prettyValue(transaction.request.headers)),
          _DetailItem('Response headers', _prettyValue(transaction.response?.headers ?? const {})),
        ],
      );
}

final class _DetailsList extends StatelessWidget {
  const _DetailsList({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => ListView(
        padding: const EdgeInsets.all(16),
        children: children,
      );
}

final class _DetailItem extends StatelessWidget {
  const _DetailItem(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label.toUpperCase(), style: Theme.of(context).textTheme.labelMedium),
            const SizedBox(height: 6),
            SelectableText(value.isEmpty ? '—' : value),
          ],
        ),
      );
}

final class _MethodLabel extends StatelessWidget {
  const _MethodLabel({required this.method});

  final String method;

  @override
  Widget build(BuildContext context) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          child: Text(method, style: Theme.of(context).textTheme.labelSmall),
        ),
      );
}

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
