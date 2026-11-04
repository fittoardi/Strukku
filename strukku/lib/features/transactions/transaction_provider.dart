import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/transaction_dao.dart';
import '../../core/db/app_database.dart';

final transactionDaoProvider = Provider<TransactionDao>((ref) {
  return TransactionDao(ref.watch(databaseProvider));
});

final recentTransactionsProvider = StreamProvider<List<Transaction>>((ref) {
  return ref.watch(transactionDaoProvider).watchTransactions(limit: 5);
});

final transactionControllerProvider =
    Provider.autoDispose<TransactionController>((ref) {
  return TransactionController(ref.watch(transactionDaoProvider));
});

class TransactionController {
  TransactionController(this.dao);

  final TransactionDao dao;

  Future<void> softDelete(String id) async => dao.softDelete(id);
  Future<void> updateTotal(String id, int total) async =>
      dao.updateTotal(id, total);
}