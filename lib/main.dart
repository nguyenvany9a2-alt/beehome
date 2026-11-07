import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'core/theme.dart';
import 'data/bee_store.dart';
import 'features/bee_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const live = bool.fromEnvironment('BEE_FIREBASE');
  try {
    if (live) {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
          appId: String.fromEnvironment('FIREBASE_APP_ID'),
          messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
          projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
          authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
        ),
      );
    }
    final store = BeeStore(live: live);
    await store.init();
    runApp(BeeHomeApp(store: store));
  } catch (e) {
    runApp(
      MaterialApp(
        theme: beeTheme(),
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.cloud_off, size: 48),
                  const SizedBox(height: 16),
                  const Text('BeeHome chưa kết nối được dữ liệu'),
                  const SizedBox(height: 12),
                  SelectableText('$e'),
                  const SizedBox(height: 12),
                  const Text(
                    'Chạy không có BEE_FIREBASE để xem bản demo, hoặc kiểm tra cấu hình và phiên đăng nhập. Không tự chuyển sang dữ liệu giả khi kết nối thật lỗi.',
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class BeeHomeApp extends StatelessWidget {
  const BeeHomeApp({super.key, required this.store, this.onBookingRequested});
  final BeeStore store;
  final ValueChanged<Map<String, dynamic>>? onBookingRequested;
  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'BeeHome · Chăm nhà gọn',
    debugShowCheckedModeBanner: false,
    theme: beeTheme(),
    home: BeeShell(store: store, onBookingRequested: onBookingRequested),
  );
}
