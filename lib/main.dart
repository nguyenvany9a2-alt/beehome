import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'core/locales.dart';
import 'core/theme.dart';
import 'data/bee_store.dart';
import 'features/auth/auth_gate.dart';
import 'features/bee_shell.dart';
import 'features/booking/booking_flow.dart';
import 'widgets/common.dart';
import 'widgets/bee_backdrop.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const options = FirebaseOptions(
    apiKey: String.fromEnvironment('FIREBASE_API_KEY'),
    appId: String.fromEnvironment('FIREBASE_APP_ID'),
    messagingSenderId: String.fromEnvironment('FIREBASE_SENDER_ID'),
    projectId: String.fromEnvironment('FIREBASE_PROJECT_ID'),
    authDomain: String.fromEnvironment('FIREBASE_AUTH_DOMAIN'),
  );
  const enabled = bool.fromEnvironment('BEE_FIREBASE');
  if (!enabled ||
      [
        options.apiKey,
        options.appId,
        options.messagingSenderId,
        options.projectId
      ].any((s) => s.trim().isEmpty)) {
    runApp(const StartupNotice());
    return;
  }
  try {
    await Firebase.initializeApp(options: options);
    if (const bool.fromEnvironment('BEE_EMULATORS')) {
      const host = String.fromEnvironment('BEE_EMULATOR_HOST',
          defaultValue: '127.0.0.1');
      await FirebaseAuth.instance.useAuthEmulator(host, 9099);
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);
    }
    runApp(const AuthGate());
  } catch (_) {
    runApp(const StartupNotice(connectionFailed: true));
  }
}

class StartupNotice extends StatelessWidget {
  const StartupNotice({super.key, this.connectionFailed = false});
  final bool connectionFailed;
  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'BeeHome',
        debugShowCheckedModeBanner: false,
        theme: beeTheme(),
        builder: buildBeeBackdrop,
        locale: beeLocale,
        supportedLocales: beeLocales,
        localizationsDelegates: beeDelegates,
        home: Scaffold(
            body: SafeArea(
                child: Center(
                    child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const ReadingSurface(child: BeeBrand()),
                const SizedBox(height: 24),
                EmptyView(
                    connectionFailed
                        ? 'Chưa thể kết nối BeeHome'
                        : 'Chưa có cấu hình Firebase',
                    connectionFailed
                        ? 'Kiểm tra kết nối mạng và cấu hình Firebase của dự án, rồi mở lại ứng dụng.'
                        : 'Khởi chạy lại BeeHome với tệp firebase.local.json của nhóm và bật BEE_FIREBASE.',
                    icon: Icons.cloud_off_outlined),
              ])),
        )))),
      );
}

class BeeHomeApp extends StatelessWidget {
  const BeeHomeApp({super.key, required this.store, this.onBookingRequested});
  final BeeStore store;
  final ValueChanged<Map<String, dynamic>>? onBookingRequested;
  @override
  Widget build(BuildContext context) => ListenableBuilder(
      listenable: store,
      builder: (context, _) => MaterialApp(
            title: 'BeeHome',
            debugShowCheckedModeBanner: false,
            navigatorKey: bookingNavigatorKey,
            theme: beeTheme(),
            builder: (c, child) => buildBeeBackdrop(
                c, child, store.profile['appearance'] as Map? ?? const {}),
            locale: beeLocale,
            supportedLocales: beeLocales,
            localizationsDelegates: beeDelegates,
            home: BeeShell(
                store: store,
                onBookingRequested: onBookingRequested ??
                    (draft) => startBooking(store, draft)),
          ));
}
