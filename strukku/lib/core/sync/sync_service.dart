import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:http/http.dart' as http;
import '../db/app_database.dart';
import '../db/transaction_dao.dart';

class SyncService {
  final AppDatabase db;
  final TransactionDao dao;
  final String baseUrl;

  SyncService({
    required this.db,
    required this.dao,
    this.baseUrl = 'http://10.0.2.2:8000',
  });

  /// Ambil transaksi dari backend → upsert ke Drift → tandai synced.
  Future<void> pull() async {
    final response = await http
        .get(Uri.parse('$baseUrl/api/transactions'))
        .timeout(const Duration(seconds: 25));

    if (response.statusCode != 200) return;

    final List<dynamic> list = jsonDecode(response.body);
    await db.transaction(() async {
      for (final raw in list) {
        final id = raw['id'].toString();
        final deletedAt = raw['deleted_at'];
        final tanggal = DateTime.tryParse(raw['tanggal']?.toString() ?? '');

        // Soft-delete lokal jika dihapus di remote
        if (deletedAt != null) {
          await (db.update(db.transactions)
                ..where((t) => t.id.equals(id)))
              .write(TransactionsCompanion(
                deletedAt: Value(DateTime.parse(deletedAt)),
                updatedAt: Value(DateTime.now()),
              ));
          continue;
        }

        final exists = await (db.select(db.transactions)
              ..where((t) => t.id.equals(id)))
            .getSingleOrNull();

        final items = (raw['items'] as List? ?? [])
            .map((i) => {
                  'id': i['id']?.toString(),
                  'transaction_id': id,
                  'nama_item': i['nama_item'],
                  'qty': i['qty'] ?? 1,
                  'harga_satuan': i['harga_satuan'] ?? 0,
                  'subtotal': i['subtotal'] ?? 0,
                })
            .toList();

        if (exists == null) {
          await db.into(db.transactions).insert(TransactionsCompanion(
            id: Value(id),
            walletId: Value(raw['wallet_id']?.toString() ?? 'wallet-tunai'),
            categoryId: Value(
                raw['category_id']?.toString() ?? 'cat-lainnya'),
            tipe: Value(raw['tipe'] ?? 'keluar'),
            total: Value(raw['total'] ?? 0),
            tanggal: Value(tanggal ?? DateTime.now()),
            namaToko: Value(raw['nama_toko']?.toString()),
            catatan: Value(raw['catatan']?.toString()),
            sumber: Value(raw['sumber'] ?? 'manual'),
            confidence: Value((raw['confidence'] as num?)?.toDouble()),
            syncedAt: Value(DateTime.now()),
            createdAt: Value(
                DateTime.tryParse(raw['created_at']?.toString() ?? '') ?? DateTime.now()),
            updatedAt: Value(
                DateTime.tryParse(raw['updated_at']?.toString() ?? '') ?? DateTime.now()),
          ));
        } else {
          await (db.update(db.transactions)
                ..where((t) => t.id.equals(id)))
              .write(TransactionsCompanion(
                walletId: Value(raw['wallet_id']?.toString() ?? 'wallet-tunai'),
                categoryId: Value(
                    raw['category_id']?.toString() ?? 'cat-lainnya'),
                tipe: Value(raw['tipe'] ?? 'keluar'),
                total: Value(raw['total'] ?? 0),
                tanggal: Value(tanggal ?? DateTime.now()),
                namaToko: Value(raw['nama_toko']?.toString()),
                catatan: Value(raw['catatan']?.toString()),
                sumber: Value(raw['sumber'] ?? 'manual'),
                confidence: Value((raw['confidence'] as num?)?.toDouble()),
                updatedAt: Value(
                    DateTime.tryParse(raw['updated_at']?.toString() ?? '') ?? DateTime.now()),
                syncedAt: Value(DateTime.now()),
              ));
        }

        // Hapus item lama, insert ulang dari remote
        await (db.delete(db.transactionItems)
              ..where((i) => i.transactionId.equals(id))).go();
        for (final it in items) {
          await db.into(db.transactionItems).insert(TransactionItemsCompanion(
            id: Value(it['id'] != null ? it['id'].toString() : TransactionDao.newId()),
            transactionId: Value(it['transaction_id']),
            namaItem: Value(it['nama_item']),
            qty: Value(it['qty']),
            hargaSatuan: Value(it['harga_satuan']),
            subtotal: Value(it['subtotal']),
          ));
        }
      }
    });
  }

  /// Kirim transaksi lokal belum sinkron ke backend → tandai synced.
  Future<void> push() async {
    final unsynced = await dao.getUnsynced();
    for (final tx in unsynced) {
      final items = await dao.getItems(tx.id);
      final body = {
        'id': tx.id,
        'wallet_id': tx.walletId,
        'category_id': tx.categoryId,
        'tipe': tx.tipe,
        'total': tx.total,
        'tanggal': '${tx.tanggal.year}-${tx.tanggal.month.toString().padLeft(2, '0')}-${tx.tanggal.day.toString().padLeft(2, '0')}',
        'nama_toko': tx.namaToko,
        'catatan': tx.catatan,
        'sumber': tx.sumber,
        'confidence': tx.confidence,
        'items': items
            .map((i) => {
                  'id': i.id,
                  'nama_item': i.namaItem,
                  'qty': i.qty,
                  'harga_satuan': i.hargaSatuan,
                  'subtotal': i.subtotal,
                })
            .toList(),
      };

      try {
        final response = await http.post(
          Uri.parse('$baseUrl/api/transactions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(body),
        ).timeout(const Duration(seconds: 25));

        if (response.statusCode == 200 || response.statusCode == 201) {
          await dao.markSynced(tx.id);
        }
      } catch (_) {
        // Biarkan syncedAt null, coba lagi pada sinkronisasi berikutnya
      }
    }
  }

  /// Sinkronisasi 2 arah: pull dulu, baru push.
  Future<void> sync() async {
    await pull();
    await push();
  }
}
