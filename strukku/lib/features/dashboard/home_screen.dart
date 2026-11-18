import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/utils/format.dart';
import '../transactions/transaction_provider.dart';
import 'dashboard_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider).value ?? [];
    final totals = ref.watch(monthlyCategoryTotalsProvider).value ?? {};
    return Scaffold(
      appBar: AppBar(title: const Text('StrukKu'), actions: [
        IconButton(icon: const Icon(Icons.sync), onPressed: () async {
          await ref.read(syncControllerProvider).sync();
          ref.invalidate(monthlyCategoryTotalsProvider);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi selesai')));
        }),
        IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/transaksi/tambah')),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        _SummaryCard(transactions),
        const SizedBox(height: 16),
        if (totals.isNotEmpty) ...[
          const Text('Pengeluaran per kategori', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(height: 220, child: PieChart(PieChartData(
            centerSpaceRadius: 35,
            sectionsSpace: 2,
            sections: totals.entries.map((e) => PieChartSectionData(
              value: e.value.toDouble(),
              title: '${e.key}\n${formatRupiah(e.value)}',
              radius: 90,
              titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
            )).toList(),
          ))),
          const SizedBox(height: 16),
        ],
        const Text('5 Transaksi Terakhir', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (transactions.isEmpty) const Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Belum ada transaksi'))),
        ...transactions.map((t) => Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            title: Text(t.namaToko ?? '-'),
            subtitle: Text(t.catatan ?? '-'),
            trailing: Text('${t.tipe == 'masuk' ? '+' : '-'}${formatRupiah(t.total)}', style: TextStyle(color: t.tipe == 'masuk' ? Colors.green : Colors.red, fontWeight: FontWeight.bold)),
            onTap: () => context.push('/transaksi/ubah/${t.id}'),
          ),
        )),
      ]),
      floatingActionButton: FloatingActionButton.extended(onPressed: () => context.push('/scan'), label: const Text('Scan'), icon: const Icon(Icons.qr_code_scanner)),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard(this.transactions);
  final List<dynamic> transactions;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    int sum(bool Function(dynamic) test) => transactions.where(test).fold(0, (s, t) => s + t.total as int);
    final today = sum((t) => t.tanggal.year == now.year && t.tanggal.month == now.month && t.tanggal.day == now.day);
    final month = sum((t) => t.tanggal.year == now.year && t.tanggal.month == now.month);
    return Card(child: Padding(padding: const EdgeInsets.all(16), child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
      _value('Hari ini', today), _value('Bulan ini', month),
    ])));
  }

  Widget _value(String label, int value) => Column(children: [Text(label), const SizedBox(height: 4), Text(formatRupiah(value), style: const TextStyle(fontWeight: FontWeight.bold))]);
}
