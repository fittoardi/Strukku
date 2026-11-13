import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'receipt_parser.dart';
import '../../core/db/app_database.dart';
import '../../core/db/transaction_dao.dart';
import '../../core/sync/sync_provider.dart';
import '../../features/transactions/transaction_provider.dart';

class ReviewScreen extends ConsumerStatefulWidget {
  const ReviewScreen({super.key, required this.receipt});

  final ParsedReceipt receipt;

  @override
  ConsumerState<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends ConsumerState<ReviewScreen> {
  late final TextEditingController _storeCtrl;
  late final TextEditingController _tanggalCtrl;
  late final TextEditingController _catatanCtrl;
  late final TextEditingController _totalCtrl;
  late final List<TextEditingController> _itemNamaCtrl;
  late final List<TextEditingController> _itemQtyCtrl;
  late final List<TextEditingController> _itemHargaCtrl;

  @override
  void initState() {
    super.initState();
    _storeCtrl = TextEditingController(text: widget.receipt.namaToko ?? '');
    _tanggalCtrl = TextEditingController(text: widget.receipt.tanggal?.toIso8601String().substring(0, 10) ?? '${DateTime.now().year}-${DateTime.now().month}-${DateTime.now().day}');
    _catatanCtrl = TextEditingController(text: '');
    _totalCtrl = TextEditingController(text: widget.receipt.total > 0 ? widget.receipt.total.toString() : '');

    final names = widget.receipt.items.map((i) => i.nama).toList();
    final qtys = widget.receipt.items.map((i) => i.qty.toString()).toList();
    final prices = widget.receipt.items.map((i) => i.hargaSatuan.toString()).toList();
    _itemNamaCtrl = names.map((e) => TextEditingController(text: e)).toList();
    _itemQtyCtrl = qtys.map((e) => TextEditingController(text: e)).toList();
    _itemHargaCtrl = prices.map((e) => TextEditingController(text: e)).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Review')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Nama Toko', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      TextField(controller: _storeCtrl, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tanggal', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      TextField(controller: _tanggalCtrl, readOnly: true, decoration: const InputDecoration(prefixIcon: Padding(padding: EdgeInsets.all(8), child: Icon(Icons.calendar_today)))),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Total', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      TextField(controller: _totalCtrl, keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: 'Rp ')),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catatan', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      TextField(controller: _catatanCtrl, maxLines: 2, decoration: const InputDecoration(hintText: 'Tambahan catatan')),
                    ],
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(children: [
                const Text('Items', style: TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ..._buildItemRows(),
              ]),
            ),
          ),
        ]),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        color: Theme.of(context).colorScheme.surface,
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
          TextButton(onPressed: () => context.pop(), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () => _done(),
            child: const Text('Simpan', style: TextStyle(fontSize: 16)),
          ),
        ]),
      ),
    );
  }

  List<Widget> _buildItemRows() {
    final rows = <Widget>[];
    for (var i = 0; i < _itemNamaCtrl.length; i++) {
      rows.add(Flexible(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(children: [
            Expanded(child: TextField(controller: _itemNamaCtrl[i], decoration: const InputDecoration(hintText: 'Nama item'))),
            const SizedBox(width: 4),
            Expanded(child: TextField(controller: _itemQtyCtrl[i], keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Qty', isDense: true))),
            const SizedBox(width: 4),
            Expanded(child: TextField(controller: _itemHargaCtrl[i], keyboardType: TextInputType.number, decoration: const InputDecoration(prefixText: 'Rp '))),
          ]),
        ),
      ));
    }
    return rows;
  }

  Future<void> _done() async {
    final totalText = _totalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final total = totalText.isEmpty ? 0 : int.parse(totalText);
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Total minimal 1')));
      return;
    }

    final dao = ref.read(transactionDaoProvider);
    final txId = TransactionDao.newId();
    
    final items = <TransactionItemsCompanion>[];
    for (var i = 0; i < _itemNamaCtrl.length; i++) {
      if (_itemNamaCtrl[i].text.trim().isEmpty) continue;
      items.add(TransactionItemsCompanion.insert(
        id: TransactionDao.newId(),
        transactionId: txId,
        namaItem: _itemNamaCtrl[i].text.trim(),
        qty: Value(int.tryParse(_itemQtyCtrl[i].text) ?? 1),
        hargaSatuan: int.tryParse(_itemHargaCtrl[i].text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
        subtotal: int.tryParse(_itemHargaCtrl[i].text.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0,
      ));
    }
    
    await dao.insertTransaction(
      TransactionsCompanion.insert(
        id: txId,
        walletId: 'wallet-tunai',
        categoryId: 'cat-lainnya',
        tipe: 'keluar',
        total: total,
        tanggal: widget.receipt.tanggal ?? DateTime.now(),
        namaToko: Value(_storeCtrl.text.trim()),
        sumber: const Value('scan'),
        confidence: Value(widget.receipt.confidence),
      ),
      items,
    );

    ref.read(syncControllerProvider).sync();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Transaksi tersimpan')));
      context.go('/');
    }
  }

  @override
  void dispose() {
    _storeCtrl.dispose();
    _tanggalCtrl.dispose();
    _catatanCtrl.dispose();
    _totalCtrl.dispose();
    for (final c in _itemNamaCtrl) {
      c.dispose();
    }
    for (final c in _itemQtyCtrl) {
      c.dispose();
    }
    for (final c in _itemHargaCtrl) {
      c.dispose();
    }
    super.dispose();
  }
}
