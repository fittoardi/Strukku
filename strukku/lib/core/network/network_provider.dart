import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'backend_service.dart';

final backendServiceProvider = Provider<BackendService>((ref) {
  // Gunakan 10.0.2.2 untuk Android Emulator, 127.0.0.1 untuk iOS/Web/Desktop
  return BackendService();
});
