import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/app_database.dart';
import '../../core/db/database_provider.dart';
import '../../core/db/transaction_dao.dart';
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

class BudgetScreen extends ConsumerWidget {
  const BudgetScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budgets = ref.watch(budgetsProvider).value ?? [];
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
