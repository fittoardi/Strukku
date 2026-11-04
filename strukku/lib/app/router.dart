import 'package:go_router/go_router.dart';
import '../features/dashboard/home_screen.dart';
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
  ],
);
