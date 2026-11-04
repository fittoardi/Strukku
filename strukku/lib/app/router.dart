import 'package:go_router/go_router.dart';
import '../features/dashboard/home_screen.dart';
import '../features/scan/receipt_parser.dart';
import '../features/scan/review_screen.dart';
import '../features/scan/scanner_screen.dart';
import '../features/transactions/transaction_form_screen.dart';
import '../features/transactions/history_screen.dart';

final GoRouter router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/transaksi/tambah',
      builder: (context, state) => const TransactionFormScreen(),
    ),
    GoRoute(
      path: '/transaksi/ubah/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionFormScreen(transactionId: id);
      },
    ),
    GoRoute(
      path: '/riwayat',
      builder: (context, state) => const HistoryScreen(),
    ),
    GoRoute(
      path: '/scan',
      builder: (context, state) => const ScannerScreen(),
    ),
    GoRoute(
      path: '/scan/review',
      builder: (context, state) => ReviewScreen(
        receipt: state.extra is ParsedReceipt
            ? state.extra! as ParsedReceipt
            : const ParsedReceipt(items: [], total: 0),
      ),
    ),
  ],
);
