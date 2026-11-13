import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/utils/format.dart';
import '../transactions/transaction_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final recentStream = ref.watch(recentTransactionsProvider);
    final transactions = recentStream.value;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StrukKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await ref.read(syncControllerProvider).sync();
              messenger.showSnackBar(
                const SnackBar(content: Text('Sinkronisasi selesai')),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => context.push('/transaksi/tambah'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(transactions ?? []),
          const SizedBox(height: 16),
          const Text('5 Transaksi Terakhir'),
          const SizedBox(height: 8),
          if ((transactions?.length ?? 0) > 0)
            ...transactions!.map((t) => _buildTransactionItem(context, ref, t)),
          if ((transactions?.length ?? 0) == 0)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada transaksi'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        label: const Text('Scan'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _buildSummaryCard(List<dynamic> transactions) {
    final totalToday = transactions
        .where((t) => t.tanggal.day == DateTime.now().day)
        .fold<int>(0, (sum, t) => sum + (t.total as int));

    final totalMonth = transactions
        .where((t) =>
            t.tanggal.year == DateTime.now().year &&
            t.tanggal.month == DateTime.now().month)
        .fold<int>(0, (sum, t) => sum + (t.total as int));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hari ini: ${formatRupiah(totalToday)}'),
            Text('Bulan ini: ${formatRupiah(totalMonth)}'),
          ],
        ),
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
          '${isIncome ? '+' : '-'}${formatRupiah(t.total as int)}',
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.red,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => context.push('/transaksi/ubah/${t.id}'),
        onLongPress: () => _showDeleteDialog(context, ref, t.id),
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, String id) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Hapus'),
        content: const Text('Hapus transaksi ini?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              final messenger = ScaffoldMessenger.of(context);
              ref.read(transactionControllerProvider).softDelete(id).then(
                    (_) => messenger.showSnackBar(
                      const SnackBar(content: Text('Transaksi dihapus')),
                    ),
                  );
              Navigator.pop(context);
            },
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }
}
