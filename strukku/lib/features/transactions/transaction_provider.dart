import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/app_database.dart';
import '../../core/db/transaction_dao.dart';
import '../../core/db/database_provider.dart';

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(databaseProvider));
});

final categoriesProvider = StreamProvider.family<List<Category>, String>((ref, tipe) {
  return ref.watch(databaseProvider).watchCategories(tipe: tipe);
});

final walletsProvider = FutureProvider<List<Wallet>>((ref) {
  return ref.watch(databaseProvider).getWallets();
});

final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionDaoProvider).watchRecent(limit: 5);
});

final transactionControllerProvider =
    Provider.autoDispose<TransactionController>((ref) {
  return TransactionController(ref.watch(transactionDaoProvider));
});

class TransactionController {
  TransactionController(this.dao);

  final TransactionDao dao;

  Future<void> softDelete(String id) async => dao.softDelete(id);
}