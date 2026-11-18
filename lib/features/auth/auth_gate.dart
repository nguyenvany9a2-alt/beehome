import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/bee_store.dart';
import '../../main.dart';
import '../booking/booking_flow.dart';
import 'auth_screen.dart';

/// "Cổng": chưa đăng nhập thì hiện màn đăng nhập,
/// đăng nhập rồi thì nạp dữ liệu và mở app của Ý.
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  StreamSubscription<User?>? sub;
  BeeStore? store;
  String? error;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Lắng nghe mỗi lần đăng nhập / đăng xuất
    sub = FirebaseAuth.instance.authStateChanges().listen(onUserChanged);
  }

  Future<void> onUserChanged(User? user) async {
    final old = store;
    setState(() {
      store = null;
      error = null;
      loading = user != null;
    });
    // Dọn dữ liệu của tài khoản cũ sau khi màn hình đã đổi xong
    if (old != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) => old.dispose());
    }
    if (user == null) return;

    try {
      final s = BeeStore(live: true);
      await s.init();
      // Lỡ người dùng đổi tài khoản trong lúc đang nạp thì bỏ
      if (!mounted || FirebaseAuth.instance.currentUser?.uid != user.uid) {
        s.dispose();
        return;
      }
      setState(() {
        store = s;
        loading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e.toString().replaceFirst('Bad state: ', '');
          loading = false;
        });
      }
    }
  }

  @override
  void dispose() {
    sub?.cancel();
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = store;
    if (s != null) {
      return BeeHomeApp(
        store: s,
        onBookingRequested: (draft) => startBooking(s, draft),
      );
    }
    return MaterialApp(
      title: 'BeeHome · Chăm nhà gọn',
      debugShowCheckedModeBanner: false,
      theme: beeTheme(),
      home: loading
          ? const Scaffold(body: Center(child: CircularProgressIndicator()))
          : error != null
          ? _ErrorView(error!)
          : const AuthScreen(),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message);
  final String message;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            SelectableText(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () => FirebaseAuth.instance.signOut(),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      ),
    ),
  );
}