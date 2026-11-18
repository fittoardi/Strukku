import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/database_provider.dart';
import '../../core/db/transaction_dao.dart';

final monthlyCategoryTotalsProvider = FutureProvider<Map<String, int>>((ref) {
  final now = DateTime.now();
  return TransactionDao(ref.watch(databaseProvider)).totalPerKategori(
    DateTime(now.year, now.month),
    DateTime(now.year, now.month + 1, 0, 23, 59, 59),
  );
});
