import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/locales.dart';
import '../../widgets/common.dart';
import '../../widgets/bee_backdrop.dart';
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
  bool registering = false;
  String? loadingUid;
  int generation = 0;

  @override
  void initState() {
    super.initState();
    // Lắng nghe mỗi lần đăng nhập / đăng xuất
    sub = FirebaseAuth.instance.authStateChanges().listen(onUserChanged);
  }

  Future<void> onUserChanged(User? user) async {
    if (registering || !mounted) return;
    if (user != null && (user.uid == loadingUid || user.uid == store?.uid)) {
      return;
    }
    final current = ++generation;
    loadingUid = user?.uid;
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

    final s = BeeStore();
    try {
      await s.init();
      // Lỡ người dùng đổi tài khoản trong lúc đang nạp thì bỏ
      if (!mounted ||
          current != generation ||
          FirebaseAuth.instance.currentUser?.uid != user.uid) {
        s.dispose();
        return;
      }
      setState(() {
        loadingUid = null;
        store = s;
        loading = false;
      });
    } catch (e) {
      s.dispose();
      if (mounted &&
          current == generation &&
          FirebaseAuth.instance.currentUser?.uid == user.uid) {
        setState(() {
          loadingUid = null;
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
      title: 'BeeHome',
      locale: beeLocale,
      supportedLocales: beeLocales,
      localizationsDelegates: beeDelegates,
      debugShowCheckedModeBanner: false,
      theme: beeTheme(),
      builder: buildBeeBackdrop,
      home: loading
          ? const Scaffold(
              body: Center(
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
              ReadingSurface(child: BeeBrand()),
              SizedBox(height: 22),
              SizedBox(
                  width: 96,
                  child: LinearProgressIndicator(
                      semanticsLabel: 'Đang tải tài khoản'))
            ])))
          : error != null
              ? _ErrorView(error!,
                  () => onUserChanged(FirebaseAuth.instance.currentUser))
              : AuthScreen(
                  onSignedIn: () {
                    if (!loading && store == null) {
                      onUserChanged(FirebaseAuth.instance.currentUser);
                    }
                  },
                  onRegistrationStart: () => registering = true,
                  onRegistrationEnd: (complete) {
                    registering = false;
                    if (complete && mounted) {
                      onUserChanged(FirebaseAuth.instance.currentUser);
                    }
                  },
                ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView(this.message, this.retry);
  final String message;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => Scaffold(
          body: SafeArea(
              child: Center(
        child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Panel(
                  child: Column(children: [
                const BeeBrand(),
                const SizedBox(height: 20),
                Text('Chưa tải được tài khoản',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium),
                const SizedBox(height: 12),
                SelectableText(message, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Wrap(alignment: WrapAlignment.center, spacing: 8, children: [
                  FilledButton.icon(
                      onPressed: retry,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Thử lại')),
                  TextButton(
                      onPressed: () => FirebaseAuth.instance.signOut(),
                      child: const Text('Đăng xuất')),
                ]),
              ])),
            )),
      )));
}
