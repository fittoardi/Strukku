import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import 'app_database.dart';
import 'tables.dart';

part 'transaction_dao.g.dart';

@DriftAccessor(tables: [Transactions, TransactionItems, Categories])
class TransactionDao extends DatabaseAccessor<AppDatabase>
    with _$TransactionDaoMixin {
  TransactionDao(super.db);

  static const _uuid = Uuid();

  // --- CRUD ---

  Future<void> insertTransaction(TransactionsCompanion entry,
      [List<TransactionItemsCompanion>? items]) async {
    await transaction(() async {
      await into(transactions).insert(entry);
      if (items != null) {
        for (final item in items) {
          await into(transactionItems).insert(item);
        }
      }
    });
  }

  Future<void> updateTransaction(String id, TransactionsCompanion entry) async {
    final updated = entry.copyWith(
      updatedAt: Value(DateTime.now()),
    );
    await (update(transactions)..where((t) => t.id.equals(id)))
        .write(updated);
  }

  Future<void> softDelete(String id) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        deletedAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
  }

  Future<Transaction?> getById(String id) {
    return (select(transactions)..where((t) => t.id.equals(id)))
        .getSingleOrNull();
  }

  /// Watch transaksi aktif (belum dihapus) di rentang tanggal, terbaru dulu.
  Stream<List<Transaction>> watchByDateRange(
      DateTime start, DateTime end) {
    return (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() &
              t.tanggal.isBiggerOrEqualValue(start) &
              t.tanggal.isSmallerOrEqualValue(end))
          ..orderBy([(t) => OrderingTerm.desc(t.tanggal)]))
        .watch();
  }

  /// Total per kategori untuk transaksi keluar aktif di rentang tanggal.
  Future<Map<String, int>> totalPerKategori(
      DateTime start, DateTime end) async {
    final query = select(transactions).join([
      innerJoin(categories,
          categories.id.equalsExp(transactions.categoryId)),
    ]);
    query.where(transactions.deletedAt.isNull() &
        transactions.tipe.equals('keluar') &
        transactions.tanggal.isBiggerOrEqualValue(start) &
        transactions.tanggal.isSmallerOrEqualValue(end));

    final rows = await query.get();
    final result = <String, int>{};
    for (final row in rows) {
      final cat = row.readTable(categories);
      final txn = row.readTable(transactions);
      result[cat.nama] = (result[cat.nama] ?? 0) + txn.total;
    }
    return result;
  }

  /// Items untuk suatu transaksi.
  Future<List<TransactionItem>> getItems(String transactionId) {
    return (select(transactionItems)
          ..where((i) => i.transactionId.equals(transactionId)))
        .get();
  }

  /// Watch transaksi aktif, terbaru dulu.
  Stream<List<Transaction>> watchRecent({int? limit}) {
    final query = select(transactions)
      ..where((t) => t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.desc(t.tanggal)]);
    if (limit != null) query.limit(limit);
    return query.watch();
  }

  /// Buat UUID baru.
  static String newId() => _uuid.v4();

  /// Insert transaksi manual sederhana (tanpa items).
  Future<void> insertManual(TransactionsCompanion entry) async {
    await into(transactions).insert(entry);
  }

  /// Transaksi aktif yang belum disinkronkan (syncedAt null).
  Future<List<Transaction>> getUnsynced() {
    return (select(transactions)
          ..where((t) =>
              t.deletedAt.isNull() & t.syncedAt.isNull())
          ..orderBy([(t) => OrderingTerm.asc(t.tanggal)]))
        .get();
  }

  /// Tandai transaksi sebagai sudah sinkron.
  Future<void> markSynced(String id) async {
    await (update(transactions)..where((t) => t.id.equals(id))).write(
      TransactionsCompanion(
        syncedAt: Value(DateTime.now()),
      ),
    );
  }
}
