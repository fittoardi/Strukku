import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/legacy.dart';
import 'package:postgres/postgres.dart';

class PostgresConfig {
  final String host;
  final int port;
  final String database;
  final String username;
  final String password;
  final bool useSsl;

  const PostgresConfig({
    required this.host,
    this.port = 5432,
    this.database = 'strukku',
    this.username = 'postgres',
    this.password = 'postgres',
    this.useSsl = false,
  });

  /// Otomatis memilih host sesuai platform
  /// - Android Emulator -> 10.0.2.2
  /// - Windows / Desktop -> 127.0.0.1
  /// - HP Fisik di Wi-Fi lokal -> ganti dengan IP laptop Anda (misal 192.168.1.19)
  factory PostgresConfig.defaultLocal({
    String? customHost,
    String password = 'postgres',
    String username = 'postgres',
    String database = 'strukku',
  }) {
    String host = customHost ?? '127.0.0.1';
    if (customHost == null && Platform.isAndroid) {
      host = '10.0.2.2';
    }
    return PostgresConfig(
      host: host,
      port: 5432,
      database: database,
      username: username,
      password: password,
      useSsl: false,
    );
  }
}

class PostgresService {
  final PostgresConfig config;
  Connection? _connection;

  PostgresService(this.config);

  /// Membuka atau menggunakan koneksi yang ada
  Future<Connection> getConnection() async {
    if (_connection != null && _connection!.isOpen) {
      return _connection!;
    }

    _connection = await Connection.open(
      Endpoint(
        host: config.host,
        port: config.port,
        database: config.database,
        username: config.username,
        password: config.password,
      ),
      settings: ConnectionSettings(
        sslMode: config.useSsl ? SslMode.require : SslMode.disable,
      ),
    );

    return _connection!;
  }

  /// Tes koneksi ke database PostgreSQL
  Future<Map<String, dynamic>> testConnection() async {
    try {
      final conn = await getConnection();
      final result = await conn.execute('SELECT version()');
      final version = result.first[0].toString();
      return {
        'success': true,
        'message': 'Berhasil terhubung ke PostgreSQL',
        'version': version,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal terhubung: $e',
      };
    }
  }

  /// Ambil kategori dari PostgreSQL
  Future<List<Map<String, dynamic>>> getCategories() async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named('SELECT id, nama, ikon, warna, tipe FROM categories WHERE deleted_at IS NULL ORDER BY nama ASC'),
    );

    return result.map((row) => {
      'id': row[0],
      'nama': row[1],
      'ikon': row[2],
      'warna': row[3],
      'tipe': row[4],
    }).toList();
  }

  /// Ambil transaksi terbaru dari PostgreSQL
  Future<List<Map<String, dynamic>>> getTransactions({int limit = 20}) async {
    final conn = await getConnection();
    final result = await conn.execute(
      Sql.named(
        'SELECT id, tipe, total, tanggal, nama_toko, catatan, sumber FROM transactions WHERE deleted_at IS NULL ORDER BY tanggal DESC LIMIT @limit',
      ),
      parameters: {'limit': limit},
    );

    return result.map((row) => {
      'id': row[0],
      'tipe': row[1],
      'total': row[2],
      'tanggal': row[3],
      'nama_toko': row[4],
      'catatan': row[5],
      'sumber': row[6],
    }).toList();
  }

  /// Simpan transaksi baru langsung ke PostgreSQL
  Future<void> insertTransaction({
    required String id,
    required String userId,
    required String tipe,
    required int total,
    required DateTime tanggal,
    String? namaToko,
    String? catatan,
    String sumber = 'manual',
    double? confidence,
  }) async {
    final conn = await getConnection();
    await conn.execute(
      Sql.named('''
        INSERT INTO transactions (id, user_id, tipe, total, tanggal, nama_toko, catatan, sumber, confidence)
        VALUES (@id, @user_id, @tipe, @total, @tanggal, @nama_toko, @catatan, @sumber, @confidence)
      '''),
      parameters: {
        'id': id,
        'user_id': userId,
        'tipe': tipe,
        'total': total,
        'tanggal': tanggal.toIso8601String().substring(0, 10),
        'nama_toko': namaToko,
        'catatan': catatan,
        'sumber': sumber,
        'confidence': confidence,
      },
    );
  }

  /// Tutup koneksi saat tidak dipakai
  Future<void> close() async {
    if (_connection != null && _connection!.isOpen) {
      await _connection!.close();
      _connection = null;
    }
  }
}

/// Provider konfigurasi database PostgreSQL
final postgresConfigProvider = StateProvider<PostgresConfig>((ref) {
  // Ubah password sesuai password akun postgres di komputer Anda
  return PostgresConfig.defaultLocal(
    password: 'postgres', // default password postgres lokal Anda
  );
});

/// Provider service PostgreSQL
final postgresServiceProvider = Provider<PostgresService>((ref) {
  final config = ref.watch(postgresConfigProvider);
  final service = PostgresService(config);
  ref.onDispose(() => service.close());
  return service;
});

