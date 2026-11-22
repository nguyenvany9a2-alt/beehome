import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../core/locales.dart';
import '../../widgets/common.dart';
import '../../widgets/bee_backdrop.dart';
import '../../data/bee_store.dart';
import '../bee_shell.dart';
import '../home/guest_home.dart';
import '../../widgets/bee_header.dart';
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
  bool signIn = false;
  bool incomplete = false;
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
    bookingNavigatorKey.currentState?.popUntil((r) => r.isFirst);
    old?.removeListener(accountChanged);
    setState(() {
      store = null;
      signIn = false;
      incomplete = false;
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
      s.addListener(accountChanged);
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
          incomplete = e is MissingProfile;
          loading = false;
        });
      }
    }
  }

  void accountChanged() {
    if (!mounted) return;
    if (store?.profile['status'] == 'blocked') {
      bookingNavigatorKey.currentState?.popUntil((r) => r.isFirst);
      FirebaseAuth.instance.signOut();
    }
    setState(() {});
  }

  @override
  void dispose() {
    sub?.cancel();
    store?.removeListener(accountChanged);
    store?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = store;
    return MaterialApp(
      title: 'BeeHome',
      navigatorKey: bookingNavigatorKey,
      locale: beeLocale,
      supportedLocales: beeLocales,
      localizationsDelegates: beeDelegates,
      debugShowCheckedModeBanner: false,
      theme: beeTheme(),
      builder: (c, child) => buildBeeBackdrop(
          c, child, s?.profile['appearance'] as Map? ?? const {}),
      home: s != null
          ? BeeShell(
              key: ValueKey(s.uid),
              store: s,
              onBookingRequested: (draft) => startBooking(s, draft))
          : loading
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
              : incomplete
                  ? _CompleteProfile(
                      done: () =>
                          onUserChanged(FirebaseAuth.instance.currentUser))
                  : error != null
                      ? _ErrorView(
                          error!,
                          () =>
                              onUserChanged(FirebaseAuth.instance.currentUser))
                      : !signIn
                          ? GuestHome(
                              login: () => setState(() => signIn = true))
                          : Scaffold(
                              body: Column(children: [
                              BeeHeader(
                                  signedIn: false,
                                  home: () => setState(() => signIn = false),
                                  account: () {},
                                  alerts: () {}),
                              Expanded(
                                  child: AuthScreen(
                                onSignedIn: () {
                                  if (!loading && store == null) {
                                    onUserChanged(
                                        FirebaseAuth.instance.currentUser);
                                  }
                                },
                                onRegistrationStart: () => registering = true,
                                onRegistrationEnd: (complete) {
                                  registering = false;
                                  if (mounted &&
                                      FirebaseAuth.instance.currentUser !=
                                          null) {
                                    onUserChanged(
                                        FirebaseAuth.instance.currentUser);
                                  }
                                },
                              ))
                            ])),
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

class _CompleteProfile extends StatefulWidget {
  const _CompleteProfile({required this.done});
  final VoidCallback done;
  @override
  State<_CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<_CompleteProfile> {
  final key = GlobalKey<FormState>();
  String name = '', phone = '', role = 'customer';
  bool busy = false;
  String? error;
  Future<void> submit() async {
    if (busy || !key.currentState!.validate()) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    setState(() => busy = true);
    try {
      await saveProfile(user.uid, name.trim(), phone.trim(), user.email!, role);
      if (mounted) widget.done();
    } on FirebaseException catch (e) {
      if (mounted) setState(() => error = 'Chưa lưu được hồ sơ (${e.code}).');
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      body: Center(
          child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: Panel(
                      child: Form(
                          key: key,
                          child: Column(children: [
                            Text('Hoàn tất hồ sơ BeeHome',
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 16),
                            TextFormField(
                                decoration:
                                    const InputDecoration(labelText: 'Họ tên'),
                                onChanged: (v) => name = v,
                                validator: (v) => (v ?? '').trim().isEmpty
                                    ? 'Vui lòng nhập họ tên'
                                    : null),
                            const SizedBox(height: 10),
                            TextFormField(
                                decoration: const InputDecoration(
                                    labelText: 'Số điện thoại'),
                                onChanged: (v) => phone = v,
                                validator: (v) =>
                                    RegExp(r'^0[0-9]{9}$').hasMatch(v ?? '')
                                        ? null
                                        : 'Nhập số điện thoại 10 số'),
                            const SizedBox(height: 10),
                            DropdownButton<String>(
                                value: role,
                                items: const [
                                  DropdownMenuItem(
                                      value: 'customer',
                                      child: Text('Khách hàng')),
                                  DropdownMenuItem(
                                      value: 'worker',
                                      child: Text('Người giúp việc'))
                                ],
                                onChanged: busy
                                    ? null
                                    : (v) => setState(() => role = v!)),
                            if (error != null) Text(error!),
                            FilledButton(
                                onPressed: busy ? null : submit,
                                child: const Text('Lưu hồ sơ')),
                            TextButton(
                                onPressed: busy
                                    ? null
                                    : () => FirebaseAuth.instance.signOut(),
                                child: const Text('Đăng xuất')),
                          ])))))));
}
