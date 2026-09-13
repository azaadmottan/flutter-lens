part of '../flutter_lens_inspector.dart';

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
