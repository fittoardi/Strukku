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
    final dailyTrends = ref.watch(dailyTrendProvider).value ?? {};

    final now = DateTime.now();
    final weekStart = now.subtract(Duration(days: now.weekday - 1));
    final weekStartDate = DateTime(weekStart.year, weekStart.month, weekStart.day);

    int totalHariIni = 0;
    int totalMingguIni = 0;
    int totalBulanIni = 0;
    int totalMasuk = 0;

    for (final t in transactions) {
      if (t.tipe == 'keluar') {
        if (t.tanggal.year == now.year && t.tanggal.month == now.month && t.tanggal.day == now.day) {
          totalHariIni += t.total;
        }
        if (!t.tanggal.isBefore(weekStartDate)) {
          totalMingguIni += t.total;
        }
        if (t.tanggal.year == now.year && t.tanggal.month == now.month) {
          totalBulanIni += t.total;
        }
      } else if (t.tipe == 'masuk') {
        if (t.tanggal.year == now.year && t.tanggal.month == now.month) {
          totalMasuk += t.total;
        }
      }
    }

    final net = totalMasuk - totalBulanIni;

    return Scaffold(
      appBar: AppBar(
        title: const Text('StrukKu'),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_balance_wallet_outlined),
            onPressed: () => context.push('/budget'),
            tooltip: 'Budget',
          ),
          IconButton(
            icon: const Icon(Icons.sync),
            tooltip: 'Sinkronisasi',
            onPressed: () async {
              await ref.read(syncControllerProvider).sync();
              ref.invalidate(monthlyCategoryTotalsProvider);
              ref.invalidate(dailyTrendProvider);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sinkronisasi selesai')),
                );
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Tambah Manual',
            onPressed: () => context.push('/transaksi/tambah'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _row('Hari ini (keluar)', totalHariIni),
                  const Divider(height: 1),
                  _row('Minggu ini (keluar)', totalMingguIni),
                  const Divider(height: 1),
                  _row('Bulan ini (keluar)', totalBulanIni),
                  const Divider(height: 1),
                  _row('Pemasukan (masuk)', totalMasuk),
                  const Divider(height: 1),
                  _row('Saldo bersih', net),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          if (totals.isNotEmpty) ...[
            const Text(
              'Pengeluaran per kategori',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 220,
              child: PieChart(
                PieChartData(
                  centerSpaceRadius: 35,
                  sectionsSpace: 2,
                  sections: totals.entries.map((e) => PieChartSectionData(
                    value: e.value.toDouble(),
                    title: '${e.key}\n${formatRupiah(e.value)}',
                    radius: 90,
                    titleStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                  )).toList(),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (dailyTrends.isNotEmpty) ...[
            const Text(
              'Tren Pengeluaran Harian',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
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
          const Text(
            '5 Transaksi Terakhir',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (transactions.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text('Belum ada transaksi'),
              ),
            ),
          ...transactions.map((t) => Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text(t.namaToko ?? '-'),
              subtitle: Text(t.catatan ?? '-'),
              trailing: Text(
                '${t.tipe == 'masuk' ? '+' : '-'}${formatRupiah(t.total)}',
                style: TextStyle(
                  color: t.tipe == 'masuk' ? Colors.green : Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              onTap: () => context.push('/transaksi/ubah/${t.id}'),
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/scan'),
        label: const Text('Scan'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }

  Widget _row(String label, int value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(
          formatRupiah(value),
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    ),
  );
}
