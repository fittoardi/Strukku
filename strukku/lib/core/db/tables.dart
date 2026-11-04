import 'package:drift/drift.dart';

class Wallets extends Table {
  TextColumn get id => text()();
  TextColumn get nama => text().withLength(min: 1)();
  TextColumn get tipe => text().withDefault(const Constant('tunai'))();
  IntColumn get saldoAwal => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get nama => text().withLength(min: 1)();
  TextColumn get ikon => text().withDefault(const Constant('category'))();
  TextColumn get warna =>
      text().withDefault(const Constant('FF009688'))();
  TextColumn get tipe =>
      text().withDefault(const Constant('keluar'))(); // masuk|keluar
  BoolColumn get isDefault =>
      boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get walletId => text().references(Wallets, #id)();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get tipe => text()(); // masuk|keluar
  IntColumn get total => integer()();
  DateTimeColumn get tanggal => dateTime()();
  TextColumn get namaToko => text().nullable()();
  TextColumn get catatan => text().nullable()();
  TextColumn get fotoStrukPath => text().nullable()();
  TextColumn get sumber =>
      text().withDefault(const Constant('manual'))(); // scan|manual
  RealColumn get confidence => real().nullable()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get updatedAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();
  DateTimeColumn get syncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class TransactionItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id)();
  TextColumn get namaItem => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  IntColumn get hargaSatuan => integer()();
  IntColumn get subtotal => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

class Budgets extends Table {
  TextColumn get id => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  TextColumn get bulan => text()(); // "2026-10"
  IntColumn get batas => integer()();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();
  DateTimeColumn get deletedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class MerchantRules extends Table {
  TextColumn get id => text()();
  TextColumn get namaTokoNormalized => text()();
  TextColumn get categoryId => text().references(Categories, #id)();
  DateTimeColumn get createdAt =>
      dateTime().withDefault(currentDateAndTime)();

  @override
  Set<Column> get primaryKey => {id};
}
