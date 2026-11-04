import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/utils/format.dart';
import 'transaction_provider.dart';

final historyFilterProvider = StateProvider<DateTimeRange?>((ref) => null);

final filteredTransactionsProvider = StreamProvider<List<dynamic>>((ref) {
  final dao = ref.watch(transactionDaoProvider);
  final filter = ref.watch(historyFilterProvider);
  
  if (filter == null) {
    return dao.watchTransactions(limit: 100);
  }
  return dao.watchTransactions(limit: 100).map((txs) {
    return txs.where((t) {
      return t.tanggal.isAfter(filter.start.subtract(const Duration(days: 1))) &&
             t.tanggal.isBefore(filter.end.add(const Duration(days: 1)));
    }).toList();
  });
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsStream = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(historyFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Riwayat'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () => _showFilterDialog(context, ref, filter),
          ),
          if (filter != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () => ref.read(historyFilterProvider.notifier).state = null,
            ),
        ],
      ),
      body: transactionsStream.when(
        data: (transactions) {
          if (transactions.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada transaksi'),
              ),
            );
          }

          final groupedByDate = <String, List<dynamic>>{};
          for (final t in transactions) {
            final key = formatTanggal(t.tanggal);
            groupedByDate.putIfAbsent(key, () => []).add(t);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: groupedByDate.length,
            itemBuilder: (context, index) {
              final date = groupedByDate.keys.elementAt(index);
              final txs = groupedByDate[date]!;
              final totalDay = txs.fold(0, (sum, t) => sum + (t.tipe == 'masuk' ? t.total : -t.total));

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          date,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        Text(
                          formatRupiah(totalDay),
                          style: TextStyle(
                            color: totalDay >= 0 ? Colors.green : Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...txs.map((t) => _buildTransactionItem(context, ref, t)),
                ],
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildTransactionItem(BuildContext context, WidgetRef ref, dynamic t) {
    final isIncome = t.tipe == 'masuk';
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(t.namaToko ?? '-'),
        subtitle: Text(t.catatan ?? '-'),
        trailing: Text(
          '${isIncome ? '+' : '-'}${formatRupiah(t.total)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => Navigator.pushNamed(context, '/transaksi/ubah/${t.id}'),
      ),
    );
  }

  Future<void> _showFilterDialog(
    BuildContext context,
    WidgetRef ref,
    DateTimeRange? currentFilter,
  ) async {
    final picked = await showDateRangePicker(
      context: context,
      initialDateRange: currentFilter ??
          DateTimeRange(
            start: DateTime.now().subtract(const Duration(days: 7)),
            end: DateTime.now(),
          ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      ref.read(historyFilterProvider.notifier).state = picked;
    }
  }
}
