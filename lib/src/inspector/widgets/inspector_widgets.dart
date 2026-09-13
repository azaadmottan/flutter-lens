part of '../flutter_lens_inspector.dart';

final class _InspectorSearchField extends StatelessWidget {
  const _InspectorSearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
        child: TextField(
          controller: controller,
          onChanged: (_) => onChanged(),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search requests...',
            border: OutlineInputBorder(),
          ),
        ),
      );
}

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

final class _TransactionList extends StatelessWidget {
  const _TransactionList({required this.transactions});

  final List<NetworkTransaction> transactions;

  @override
  Widget build(BuildContext context) => ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        itemCount: transactions.length,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _TransactionTile(
          transaction: transactions[index],
          onTap: () => Navigator.of(context).push<void>(
            MaterialPageRoute<void>(
              builder: (_) => _TransactionDetails(transaction: transactions[index]),
            ),
          ),
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
