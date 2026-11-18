// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:strukku/main.dart';
import 'package:strukku/core/db/app_database.dart';
import 'package:strukku/core/db/database_provider.dart';
import 'package:strukku/features/transactions/transaction_provider.dart';

void main() {
  testWidgets('StrukkuApp smoke test', (WidgetTester tester) async {
    final testDatabase = AppDatabase();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDatabase),
          recentTransactionsProvider.overrideWithValue(AsyncValue.data(<Transaction>[])),
        ],
        child: MaterialApp(home: StrukkuApp()),
      ),
    );

    expect(find.text('StrukKu'), findsOneWidget);
    addTearDown(testDatabase.close);
  });
}
