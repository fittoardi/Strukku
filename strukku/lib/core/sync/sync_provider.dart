import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/database_provider.dart';
import '../../core/db/transaction_dao.dart';
import 'sync_service.dart';

final syncServiceProvider = Provider<SyncService>((ref) {
  final db = ref.watch(databaseProvider);
  final dao = TransactionDao(db);
  return SyncService(db: db, dao: dao);
});

final syncControllerProvider =
    Provider.autoDispose<SyncController>((ref) {
  return SyncController(ref.watch(syncServiceProvider));
});

class SyncController {
  SyncController(this.service);
  final SyncService service;
  Future<void> sync() => service.sync();
}
