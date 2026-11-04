import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/db/app_database.dart';
import '../../core/utils/format.dart';
import 'transaction_provider.dart';

final databaseProvider = Provider<AppDatabase>((ref) => AppDatabase());

class TransactionFormScreen extends ConsumerStatefulWidget {
  final String? transactionId;
  
  const TransactionFormScreen({super.key, this.transactionId});

  @override
  ConsumerState<TransactionFormScreen> createState() => _TransactionFormScreenState();
}

class _TransactionFormScreenState extends ConsumerState<TransactionFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaTokoController = TextEditingController();
  final _totalController = TextEditingController();
  final _catatanController = TextEditingController();
  
  DateTime _selectedDate = DateTime.now();
  String _tipe = 'keluar';
  
  @override
  void initState() {
    super.initState();
    if (widget.transactionId != null) {
      _loadTransaction();
    }
  }

  Future<void> _loadTransaction() async {
    final dao = ref.read(transactionDaoProvider);
    final tx = await dao.getById(widget.transactionId!);
    if (tx != null) {
      setState(() {
        _namaTokoController.text = tx.namaToko ?? '';
        _totalController.text = tx.total.toString();
        _catatanController.text = tx.catatan ?? '';
        _selectedDate = tx.tanggal;
        _tipe = tx.tipe;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.transactionId == null ? 'Tambah Transaksi' : 'Ubah Transaksi'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'keluar', label: Text('Pengeluaran')),
                ButtonSegment(value: 'masuk', label: Text('Pemasukan')),
              ],
              selected: {_tipe},
              onSelectionChanged: (Set<String> value) {
                setState(() => _tipe = value.first);
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _namaTokoController,
              decoration: const InputDecoration(labelText: 'Nama Toko'),
              validator: (v) => (v?.isEmpty ?? true) ? 'Wajib diisi' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _totalController,
              decoration: const InputDecoration(
                labelText: 'Total (Rp)',
                prefixText: 'Rp ',
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Wajib diisi';
                if (int.tryParse(v!) == null) return 'Harus angka';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              title: const Text('Tanggal'),
              subtitle: Text(formatTanggal(_selectedDate)),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) {
                  setState(() => _selectedDate = picked);
                }
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _catatanController,
              decoration: const InputDecoration(labelText: 'Catatan'),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _save,
              child: const Text('Simpan'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final dao = ref.read(transactionDaoProvider);
    final total = int.parse(_totalController.text);

    if (widget.transactionId == null) {
      await dao.insertManual(
        namaToko: _namaTokoController.text,
        total: total,
        tipe: _tipe,
        tanggal: _selectedDate,
        catatan: _catatanController.text.isEmpty ? null : _catatanController.text,
      );
    } else {
      // ponytail: update hanya total, perlu method updateTransaction lengkap
      await dao.updateTotal(widget.transactionId!, total);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi disimpan')),
      );
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _totalController.dispose();
    _catatanController.dispose();
    super.dispose();
  }
}
