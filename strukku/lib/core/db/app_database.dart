import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'tables.dart';

part 'app_database.g.dart';

@DriftDatabase(tables: [
  Wallets,
  Categories,
  Transactions,
  TransactionItems,
  Budgets,
  MerchantRules,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  static QueryExecutor _openConnection() => driftDatabase(name: 'strukku.db');

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _seedDefaults();
      },
      beforeOpen: (details) async {
        if (details.wasCreated) return;
        // Seed jika tabel kosong (install ulang / db lama)
        final count = await categories.count().getSingle();
        if (count == 0) await _seedDefaults();
      },
    );
  }

  Future<void> _seedDefaults() async {
    // Wallets
    await batch((b) {
      b.insertAllOnConflictUpdate(wallets, [
        WalletsCompanion.insert(id: 'wallet-tunai', nama: 'Tunai',
            tipe: const Value('tunai')),
        WalletsCompanion.insert(id: 'wallet-bank', nama: 'Rekening Bank',
            tipe: const Value('bank')),
      ]);
      // Kategori keluar
      b.insertAllOnConflictUpdate(categories, [
        CategoriesCompanion.insert(id: 'cat-makanan', nama: 'Makanan & Minuman',
            ikon: const Value('restaurant'), tipe: const Value('keluar'), isDefault: const Value(true)),
        CategoriesCompanion.insert(id: 'cat-transport', nama: 'Transportasi',
            ikon: const Value('directions_car'), tipe: const Value('keluar')),
        CategoriesCompanion.insert(id: 'cat-belanja', nama: 'Belanja',
            ikon: const Value('shopping_bag'), tipe: const Value('keluar')),
        CategoriesCompanion.insert(id: 'cat-kesehatan', nama: 'Kesehatan',
            ikon: const Value('local_hospital'), tipe: const Value('keluar')),
        CategoriesCompanion.insert(id: 'cat-hiburan', nama: 'Hiburan',
            ikon: const Value('movie'), tipe: const Value('keluar')),
        CategoriesCompanion.insert(id: 'cat-tagihan', nama: 'Tagihan',
            ikon: const Value('receipt'), tipe: const Value('keluar')),
        CategoriesCompanion.insert(id: 'cat-lainnya', nama: 'Lainnya',
            ikon: const Value('category'), tipe: const Value('keluar')),
        // Kategori masuk
        CategoriesCompanion.insert(id: 'cat-gaji', nama: 'Gaji',
            ikon: const Value('payments'), tipe: const Value('masuk')),
        CategoriesCompanion.insert(id: 'cat-bonus', nama: 'Bonus',
            ikon: const Value('card_giftcard'), tipe: const Value('masuk')),
        CategoriesCompanion.insert(id: 'cat-masuk-lain', nama: 'Pemasukan Lain',
            ikon: const Value('attach_money'), tipe: const Value('masuk')),
      ]);
    });
  }

  // Queries untuk Categories & Wallets
  Stream<List<Category>> watchCategories({String? tipe}) {
    final q = select(categories)
      ..where((c) => c.deletedAt.isNull());
    if (tipe != null) q.where((c) => c.tipe.equals(tipe));
    q.orderBy([(c) => OrderingTerm.asc(c.nama)]);
    return q.watch();
  }

  Future<List<Wallet>> getWallets() {
    return (select(wallets)
          ..where((w) => w.deletedAt.isNull())
          ..orderBy([(w) => OrderingTerm.asc(w.nama)]))
        .get();
  }
}
