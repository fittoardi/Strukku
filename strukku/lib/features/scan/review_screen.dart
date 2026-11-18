import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'receipt_parser.dart';
import '../../core/db/app_database.dart';
import '../../core/db/transaction_dao.dart';
import '../../core/sync/sync_provider.dart';
import '../../core/utils/format.dart';
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
  final List<TextEditingController> _itemNamaCtrl = [];
  final List<TextEditingController> _itemQtyCtrl = [];
  final List<TextEditingController> _itemHargaCtrl = [];

  DateTime _selectedDate = DateTime.now();
  String? _categoryId;
  String? _walletId;
  bool _initializedDefaults = false;

  @override
  void initState() {
    super.initState();
    _storeCtrl = TextEditingController(text: widget.receipt.namaToko ?? '');
    _selectedDate = widget.receipt.tanggal ?? DateTime.now();
    _tanggalCtrl = TextEditingController(text: formatTanggal(_selectedDate));
    _catatanCtrl = TextEditingController(text: widget.receipt.catatanParser ?? '');
    _totalCtrl = TextEditingController(
      text: widget.receipt.total > 0 ? widget.receipt.total.toString() : '',
    );

    for (final item in widget.receipt.items) {
      _addItemRow(
        nama: item.nama,
        qty: item.qty.toString(),
        harga: item.hargaSatuan.toString(),
      );
    }
  }

  void _addItemRow({String nama = '', String qty = '1', String harga = '0'}) {
    setState(() {
      _itemNamaCtrl.add(TextEditingController(text: nama));
      _itemQtyCtrl.add(TextEditingController(text: qty));
      _itemHargaCtrl.add(TextEditingController(text: harga));
    });
  }

  void _removeItemRow(int index) {
    setState(() {
      _itemNamaCtrl[index].dispose();
      _itemQtyCtrl[index].dispose();
      _itemHargaCtrl[index].dispose();
      _itemNamaCtrl.removeAt(index);
      _itemQtyCtrl.removeAt(index);
      _itemHargaCtrl.removeAt(index);
    });
  }

  Future<void> _initCategoryAndWallet(
    List<Category> categories,
    List<Wallet> wallets,
  ) async {
    if (_initializedDefaults) return;
    _initializedDefaults = true;

    // 1. Cek aturan toko sebelumnya (merchant rules)
    final dao = ref.read(transactionDaoProvider);
    String? matchedCategory = await dao.getCategoryByMerchant(_storeCtrl.text);

    // 2. Jika tidak ada, cocokkan dengan saran LLM/AI (kategoriSaran)
    if (matchedCategory == null && widget.receipt.kategoriSaran != null) {
      final saran = widget.receipt.kategoriSaran!.toLowerCase();
      final found = categories.where((c) =>
          c.nama.toLowerCase().contains(saran) ||
          saran.contains(c.nama.toLowerCase())).firstOrNull;
      matchedCategory = found?.id;
    }

    // 3. Fallback ke kategori pertama atau cat-lainnya
    matchedCategory ??= categories.where((c) => c.id == 'cat-lainnya').firstOrNull?.id ??
        categories.firstOrNull?.id;

    // Dompet default
    final matchedWallet = wallets.where((w) => w.id == 'wallet-tunai').firstOrNull?.id ??
        wallets.firstOrNull?.id;

    if (mounted) {
      setState(() {
        _categoryId = matchedCategory;
        _walletId = matchedWallet;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(categoriesProvider('keluar'));
    final walletsAsync = ref.watch(walletsProvider);

    final categories = categoriesAsync.value ?? [];
    final wallets = walletsAsync.value ?? [];

    if (categories.isNotEmpty && !_initializedDefaults) {
      _initCategoryAndWallet(categories, wallets);
    }

    final isLowConfidence = widget.receipt.confidence > 0 && widget.receipt.confidence < 0.6;
    final isTotalZero = (int.tryParse(_totalCtrl.text) ?? 0) <= 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Hasil Scan')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (isLowConfidence || isTotalZero)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.amber.shade400),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber.shade800),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        widget.receipt.catatanParser ??
                            'Beberapa bagian struk tidak terbaca jelas. Mohon periksa kembali total dan daftar item.',
                        style: TextStyle(fontSize: 13, color: Colors.amber.shade900),
                      ),
                    ),
                  ],
                ),
              ),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextFormField(
                      controller: _storeCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Toko / Merchant',
                        prefixIcon: Icon(Icons.storefront),
                      ),
                    ),
                    const SizedBox(height: 12),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
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
                          setState(() {
                            _selectedDate = picked;
                            _tanggalCtrl.text = formatTanggal(picked);
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _totalCtrl,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Total Tagihan (Rp)',
                        prefixText: 'Rp ',
                        fillColor: isTotalZero ? Colors.amber.shade50 : null,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _categoryId,
                      decoration: const InputDecoration(
                        labelText: 'Kategori',
                        prefixIcon: Icon(Icons.category),
                      ),
                      items: categories
                          .map((c) => DropdownMenuItem(value: c.id, child: Text(c.nama)))
                          .toList(),
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: _walletId,
                      decoration: const InputDecoration(
                        labelText: 'Dompet / Sumber Dana',
                        prefixIcon: Icon(Icons.account_balance_wallet),
                      ),
                      items: wallets
                          .map((w) => DropdownMenuItem(value: w.id, child: Text(w.nama)))
                          .toList(),
                      onChanged: (v) => setState(() => _walletId = v),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _catatanCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        labelText: 'Catatan',
                        hintText: 'Catatan tambahan struk...',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Rincian Item Produk',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        TextButton.icon(
                          onPressed: () => _addItemRow(),
                          icon: const Icon(Icons.add, size: 18),
                          label: const Text('Tambah Item'),
                        ),
                      ],
                    ),
                    const Divider(),
                    if (_itemNamaCtrl.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Tidak ada rincian item. Anda bisa menambahkannya secara manual.',
                            style: TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ),
                    ..._buildItemRows(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () => context.pop(),
                child: const Text('Batal'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: _saveTransaction,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Simpan Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildItemRows() {
    final rows = <Widget>[];
    for (var i = 0; i < _itemNamaCtrl.length; i++) {
      rows.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                flex: 4,
                child: TextField(
                  controller: _itemNamaCtrl[i],
                  decoration: const InputDecoration(
                    hintText: 'Nama Produk',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _itemQtyCtrl[i],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    hintText: 'Qty',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _itemHargaCtrl[i],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    prefixText: 'Rp ',
                    isDense: true,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.redAccent, size: 20),
                onPressed: () => _removeItemRow(i),
              ),
            ],
          ),
        ),
      );
    }
    return rows;
  }

  Future<void> _saveTransaction() async {
    final totalText = _totalCtrl.text.replaceAll(RegExp(r'[^0-9]'), '');
    final total = totalText.isEmpty ? 0 : int.parse(totalText);
    if (total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Total tagihan harus lebih dari 0')),
      );
      return;
    }

    if (_categoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Silakan pilih kategori')),
      );
      return;
    }

    final dao = ref.read(transactionDaoProvider);
    final txId = TransactionDao.newId();
    final storeName = _storeCtrl.text.trim();

    final items = <TransactionItemsCompanion>[];
    for (var i = 0; i < _itemNamaCtrl.length; i++) {
      final name = _itemNamaCtrl[i].text.trim();
      if (name.isEmpty) continue;

      final qty = int.tryParse(_itemQtyCtrl[i].text) ?? 1;
      final priceClean = _itemHargaCtrl[i].text.replaceAll(RegExp(r'[^0-9]'), '');
      final price = int.tryParse(priceClean) ?? 0;

      items.add(TransactionItemsCompanion.insert(
        id: TransactionDao.newId(),
        transactionId: txId,
        namaItem: name,
        qty: Value(qty),
        hargaSatuan: price,
        subtotal: price * qty,
      ));
    }

    // 1. Simpan Transaksi ke Drift SQLite
    await dao.insertTransaction(
      TransactionsCompanion.insert(
        id: txId,
        walletId: _walletId ?? 'wallet-tunai',
        categoryId: _categoryId!,
        tipe: 'keluar',
        total: total,
        tanggal: _selectedDate,
        namaToko: Value(storeName.isNotEmpty ? storeName : null),
        catatan: Value(_catatanCtrl.text.trim().isNotEmpty ? _catatanCtrl.text.trim() : null),
        sumber: const Value('scan'),
        confidence: Value(widget.receipt.confidence),
      ),
      items,
    );

    // 2. Simpan aturan toko -> kategori untuk scan berikutnya (merchant rules)
    if (storeName.isNotEmpty) {
      await dao.saveMerchantRule(storeName, _categoryId!);
    }

    // 3. Pemicu sinkronisasi ke PostgreSQL backend
    ref.read(syncControllerProvider).sync();

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi struk berhasil disimpan')),
      );
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
