import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../../core/db/app_database.dart';
import '../../core/db/database_provider.dart';
import '../../core/db/transaction_dao.dart';
import '../../core/utils/format.dart';
import '../dashboard/dashboard_provider.dart';
import '../transactions/transaction_provider.dart';

final budgetsProvider = StreamProvider<List<Budget>>((ref) {
  final db = ref.watch(databaseProvider);
  final month = _monthKey(DateTime.now());
  return (db.select(db.budgets)
        ..where((b) => b.bulan.equals(month) & b.deletedAt.isNull())
        ..orderBy([(b) => OrderingTerm.asc(b.createdAt)]))
      .watch();
});

String _monthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

class BudgetStatus {
  final Budget budget;
  final String category;
  final int batas;
  final int used;
  final int percentage;
  final bool reached80;
  final bool reached100;
  const BudgetStatus({
    required this.budget,
    required this.category,
    required this.batas,
    required this.used,
    required this.percentage,
    this.reached80 = false,
    this.reached100 = false,
  });
}

final budgetNotificationProvider = Provider<List<BudgetStatus>>((ref) {
  final budgets = ref.watch(budgetsProvider).value ?? [];
  final totals = ref.watch(monthlyCategoryTotalsProvider).value ?? {};
  return budgets.map((b) {
    final used = totals[b.categoryId] ?? 0;
    final percentage = b.batas > 0 ? ((used / b.batas) * 100).round() : 0;
    return BudgetStatus(
      budget: b,
      category: '-',
      batas: b.batas,
      used: used,
      percentage: percentage,
      reached80: percentage >= 80,
      reached100: percentage >= 100,
    );
  }).toList()
    ..sort((a, b) => b.percentage.compareTo(a.percentage));
});

final flutterLocalNotificationsProvider = Provider<FlutterLocalNotificationsPlugin>(
  (ref) => FlutterLocalNotificationsPlugin(),
);

class BudgetScreen extends ConsumerStatefulWidget {
  const BudgetScreen({super.key});
  @override
  ConsumerState<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends ConsumerState<BudgetScreen> {
  final _notified = <String>{};

  @override
  void initState() {
    super.initState();
    _requestPermission();
  }

  Future<void> _requestPermission() async {
    final android = ref.read(flutterLocalNotificationsProvider)
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (android != null) {
      await android.requestNotificationsPermission();
    }
  }

  void _checkNotifications(List<BudgetStatus> statuses) {
    for (final s in statuses) {
      final id = s.budget.id;
      if (s.reached80 && !_notified.contains('$id:80')) {
        _trigger(id, 'Budget 80% ditempuh', 'Kategori ${s.category} sudah ${formatRupiah(s.used)} dari ${formatRupiah(s.batas)}');
        _notified.add('$id:80');
      }
      if (s.reached100 && !_notified.contains('$id:100')) {
        _trigger(id, 'Budget Habis!', 'Kategori ${s.category} mencapai batas ${formatRupiah(s.batas)}');
        _notified.add('$id:100');
      }
    }
  }

  Future<void> _trigger(String id, String title, String body) async {
    final plugin = ref.read(flutterLocalNotificationsProvider);
    await plugin.initialize(const InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
      iOS: DarwinInitializationSettings(),
    ));
    await plugin.show(
      id.hashCode & 0xFFFF,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'budget',
          'Budget Notifications',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: false,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final ref = this.ref;
    final budgets = ref.watch(budgetsProvider).value ?? [];
    final statuses = ref.watch(budgetNotificationProvider);
    _checkNotifications(statuses);
    final categories = ref.watch(categoriesProvider('keluar')).value ?? [];
    return Scaffold(
      appBar: AppBar(title: const Text('Budget Bulanan')),
      body: budgets.isEmpty
          ? const Center(child: Text('Belum ada budget bulan ini'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: budgets.length,
              itemBuilder: (context, index) {
                final budget = budgets[index];
                final name = categories
                    .where((category) => category.id == budget.categoryId)
                    .map((category) => category.nama)
                    .firstOrNull ?? '-';
                return Card(
                  child: ListTile(
                    title: Text(name),
                    subtitle: Text('Batas: Rp ${budget.batas}'),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline),
                      onPressed: () async {
                        await (ref.read(databaseProvider).update(ref.read(databaseProvider).budgets)
                              ..where((b) => b.id.equals(budget.id)))
                            .write(BudgetsCompanion(deletedAt: Value(DateTime.now())));
                      },
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context, ref, categories),
        icon: const Icon(Icons.add),
        label: const Text('Tambah budget'),
      ),
    );
  }

  Future<void> _showAddDialog(
      BuildContext context, WidgetRef ref, List<Category> categories) async {
    if (categories.isEmpty) return;
    final amountController = TextEditingController();
    String categoryId = categories.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Tambah budget'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
              initialValue: categoryId,
              items: categories
                  .map((category) => DropdownMenuItem(
                      value: category.id, child: Text(category.nama)))
                  .toList(),
              onChanged: (value) => setState(() => categoryId = value!),
              decoration: const InputDecoration(labelText: 'Kategori'),
            ),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Batas (Rp)'),
            ),
          ]),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal')),
            FilledButton(
              onPressed: () async {
                final amount = int.tryParse(amountController.text);
                if (amount == null || amount <= 0) return;
                await ref.read(databaseProvider).into(ref.read(databaseProvider).budgets).insert(
                      BudgetsCompanion.insert(
                        id: TransactionDao.newId(),
                        categoryId: categoryId,
                        bulan: _monthKey(DateTime.now()),
                        batas: amount,
                      ),
                    );
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
    amountController.dispose();
  }
}
