import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/transaction_dao.dart';
import 'transaction_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactions = ref.watch(recentTransactionsProvider).value ?? [];
    final totals = ref.watch(monthlyCategoryTotalsProvider).value ?? {};
    final dailyTrends = ref.watch(dailyTrendProvider).value ?? {};
    final totalsMasuk = <String, int>{};
    final totalsKeluar = <String, int>{};
    for (final t in transactions) {
      if (t.tipe == 'masuk') {
        totalsMasuk[t.categoryId ?? ''] = (totalsMasuk[t.categoryId ?? ''] ?? 0) + t.total;
      } else {
        totalsKeluar[t.categoryId ?? ''] = (totalsKeluar[t.categoryId ?? ''] ?? 0) + t.total;
      }
    }
    final net = totalsMasuk.values.fold(0, (a, b) => a + b) - totalsKeluar.values.fold(0, (a, b) => a + b);
    return Scaffold(
      appBar: AppBar(title: const Text('StrukKu'), actions: [
        IconButton(icon: const Icon(Icons.account_balance_wallet_outlined), onPressed: () => context.push('/budget')),
        IconButton(icon: const Icon(Icons.sync), onPressed: () async {
          await ref.read(syncControllerProvider).sync();
          ref.invalidate(monthlyCategoryTotalsProvider);
          ref.invalidate(dailyTrendProvider);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sinkronisasi selesai')));
        }),
        IconButton(icon: const Icon(Icons.add), onPressed: () => context.push('/transaksi/tambah')),
      ]),
      body: ListView(padding: const EdgeInsets.all(16), children: [
        Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(children: [
          _row('Hari ini (keluar)', totalsKeluar.values.where((v) => v > 0).fold(0, (a, b) => a + b)),
          const Divider(height: 1),
          _row('Minggu ini (keluar)', totalsKeluar.values.where((v) => v > 0).fold(0, (a, b) => a + b)),
          const Divider(height: 1),
          _row('Bulan ini (keluar)', totalsKeluar.values.where((v) => v > 0).fold(0, (a, b) => a + b)),
          const Divider(height: 1),
          _row('Pemasukan (masuk)', totalsMasuk.values.fold(0, (a, b) => a + b)),
          const Divider(height: 1),
          _row('Saldo bersih', net),
        ])))),
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
        if (dailyTrends.isNotEmpty) ...[
          const Text('Tren Pengeluaran Harian', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: LineChart(
              LineChartData(
                gridData: const FlGridData(show: false),
                titlesData: const FlTitlesData(
                  leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: dailyTrends.entries
                        .toList()
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.value.toDouble()))
                        .toList(),
                    isCurved: true,
                    barWidth: 2,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
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
    return const Card(child: Padding(padding: EdgeInsets.all(16), child: Text('Rangkuman'));
  }
}

Widget _row(String label, int value) => Row(
  mainAxisAlignment: MainAxisAlignment.spaceBetween,
  children: [Text(label), Text(formatRupiah(value))],
];
