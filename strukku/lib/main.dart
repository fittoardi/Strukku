import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
  await flutterLocalNotificationsPlugin.initialize(
    const InitializationSettings(
      android: AndroidInitializationSettings('notification_icon'),
      iOS: DarwinInitializationSettings(),
    ),
  );
  // Android 8+ channel (API 26+)
  await flutterLocalNotificationsPlugin
      .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(const AndroidNotificationChannel(
    'budget',
    'Budget Notifications',
    description: 'Pengingat penggunaan budget: 80% dan 100%.',
    importance: Importance.max,
  ));
  runApp(const ProviderScope(child: StrukkuApp()));
}

class StrukkuApp extends ConsumerWidget {
  const StrukkuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      routerConfig: router,
      theme: lightTheme,
      darkTheme: darkTheme,
      debugShowCheckedModeBanner: false,
    );
  }
}
