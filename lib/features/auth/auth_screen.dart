import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../widgets/home_cover.dart';

/// Màn đăng nhập / đăng ký (phần của Hào).
class AuthScreen extends StatefulWidget {
  const AuthScreen(
      {super.key,
      this.onRegistrationStart,
      this.onRegistrationEnd,
      this.onSignedIn});
  final VoidCallback? onRegistrationStart;
  final VoidCallback? onSignedIn;
  final ValueChanged<bool>? onRegistrationEnd;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();

  bool register = false; // false = đăng nhập, true = đăng ký
  bool busy = false;
  bool hidePassword = true;
  String role = 'customer';
  String? error;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  /// Bấm nút Đăng nhập / Đăng ký
  Future<void> submit() async {
    if (busy || !formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    final signingUp = register;
    var complete = false;
    var accountCreated = false;
    final onEnd = widget.onRegistrationEnd;
    final onSignIn = widget.onSignedIn;
    if (signingUp) widget.onRegistrationStart?.call();
    try {
      final auth = FirebaseAuth.instance;
      if (register) {
        final profileName = name.text.trim();
        final profilePhone = phone.text.trim();
        final profileEmail = email.text.trim();
        final profileRole = role;
        final cred = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        accountCreated = true;
        await saveProfile(cred.user!.uid, profileName, profilePhone,
            profileEmail, profileRole);
      } else {
        await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      complete = true;
    } on FirebaseAuthException catch (e) {
      error = message(e.code);
    } catch (e) {
      error = '$e';
    }
    if (accountCreated && !complete) {
      // Auth can succeed before Firestore finishes creating the profile.
      // Keep the email visible and surface the failure instead of registering twice.
      error =
          'Tài khoản đã được tạo nhưng chưa lưu được hồ sơ. Liên hệ quản trị viên BeeHome. ${error ?? ''}';
      register = false;
    }
    if (signingUp) onEnd?.call(complete);
    if (!signingUp && complete && mounted) onSignIn?.call();
    if (mounted) setState(() => busy = false);
  }

  /// Lưu hồ sơ người dùng vào Firestore lúc đăng ký.
  Future<void> saveProfile(String uid, String fullName, String phoneNumber,
      String mail, String accountRole) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(uid).set({
      'name': fullName,
      'email': mail,
      'phone': phoneNumber,
      'avatarUrl': '',
      'role': accountRole,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    });
    // Người giúp việc có thêm hồ sơ nghề nghiệp, chờ admin duyệt.
    if (accountRole == 'worker') {
      await db.collection('worker_profiles').doc(uid).set({
        'name': fullName,
        'skills': '',
        'area': 'TP. Hồ Chí Minh',
        'experience': '',
        'bio': '',
        'approval': 'pending',
        'reason': '',
        'rating': 0,
        'reviewCount': 0,
      });
    }
  }

  /// Gửi mail đặt lại mật khẩu.
  Future<void> forgotPassword() async {
    final e = email.text.trim();
    if (!e.contains('@')) {
      setState(() => error = 'Nhập email trước rồi bấm "Quên mật khẩu".');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: e);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Đã gửi mail đặt lại mật khẩu tới $e')),
      );
    } on FirebaseAuthException catch (x) {
      if (mounted) setState(() => error = message(x.code));
    }
  }

  /// Đổi mã lỗi Firebase sang tiếng Việt.
  String message(String code) => switch (code) {
        'invalid-email' => 'Email không hợp lệ.',
        'invalid-credential' ||
        'wrong-password' ||
        'user-not-found' =>
          'Email hoặc mật khẩu không đúng.',
        'email-already-in-use' => 'Email này đã được đăng ký.',
        'weak-password' => 'Mật khẩu cần ít nhất 6 ký tự.',
        'too-many-requests' => 'Thử sai quá nhiều lần, vui lòng đợi một lát.',
        'network-request-failed' => 'Không có kết nối mạng.',
        _ => 'Có lỗi xảy ra ($code).',
      };

  @override
  Widget build(BuildContext context) {
    final form = AutofillGroup(
        child: Form(
            key: formKey,
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(register ? 'Tạo tài khoản' : 'Đăng nhập',
                      style: Theme.of(context).textTheme.headlineMedium),
                  const SizedBox(height: 7),
                  Text(
                      register
                          ? 'Chọn vai trò và nhập thông tin liên hệ của bạn.'
                          : 'Dùng email đã đăng ký với BeeHome.',
                      style: const TextStyle(color: muted)),
                  const SizedBox(height: 24),
                  if (register) ...[
                    DropdownButtonFormField<String>(
                        initialValue: role,
                        isExpanded: true,
                        decoration: const InputDecoration(
                            labelText: 'Loại tài khoản',
                            prefixIcon: Icon(Icons.badge_outlined)),
                        items: const [
                          DropdownMenuItem(
                              value: 'customer', child: Text('Khách hàng')),
                          DropdownMenuItem(
                              value: 'worker', child: Text('Người giúp việc'))
                        ],
                        onChanged: busy
                            ? null
                            : (v) => setState(() => role = v ?? role)),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: name,
                        enabled: !busy,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.name],
                        textCapitalization: TextCapitalization.words,
                        decoration: const InputDecoration(
                            labelText: 'Họ tên',
                            prefixIcon: Icon(Icons.person_outline)),
                        validator: (v) => (v ?? '').trim().isEmpty
                            ? 'Vui lòng nhập họ tên'
                            : null),
                    const SizedBox(height: 14),
                    TextFormField(
                        controller: phone,
                        enabled: !busy,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.telephoneNumber],
                        decoration: const InputDecoration(
                            labelText: 'Số điện thoại',
                            prefixIcon: Icon(Icons.phone_outlined)),
                        validator: (v) =>
                            RegExp(r'^0\d{9}$').hasMatch((v ?? '').trim())
                                ? null
                                : 'Nhập 10 chữ số, bắt đầu bằng 0'),
                    const SizedBox(height: 14),
                  ],
                  TextFormField(
                      controller: email,
                      enabled: !busy,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      autocorrect: false,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.alternate_email)),
                      validator: (v) => (v ?? '').trim().contains('@')
                          ? null
                          : 'Nhập địa chỉ email hợp lệ'),
                  const SizedBox(height: 14),
                  TextFormField(
                      key: ValueKey(register),
                      controller: password,
                      enabled: !busy,
                      obscureText: hidePassword,
                      autofillHints: [
                        register
                            ? AutofillHints.newPassword
                            : AutofillHints.password
                      ],
                      onFieldSubmitted: (_) => submit(),
                      decoration: InputDecoration(
                          labelText: 'Mật khẩu',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                              tooltip: hidePassword
                                  ? 'Hiện mật khẩu'
                                  : 'Ẩn mật khẩu',
                              icon: Icon(hidePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined),
                              onPressed: () => setState(
                                  () => hidePassword = !hidePassword))),
                      validator: (v) => (v ?? '').length < 6
                          ? 'Mật khẩu cần ít nhất 6 ký tự'
                          : null),
                  if (!register)
                    Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                            onPressed: busy ? null : forgotPassword,
                            child: const Text('Quên mật khẩu?'))),
                  if (error != null)
                    Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 8),
                        child: Semantics(
                            liveRegion: true,
                            child: Text(error!,
                                style: const TextStyle(color: danger)))),
                  SizedBox(height: register ? 20 : 4),
                  FilledButton.icon(
                      onPressed: busy ? null : submit,
                      icon: busy
                          ? const SizedBox.square(
                              dimension: 17,
                              child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.arrow_forward_rounded, size: 18),
                      label: Text(busy
                          ? 'Đang xử lý…'
                          : register
                              ? 'Tạo tài khoản'
                              : 'Đăng nhập')),
                  const SizedBox(height: 8),
                  Center(
                      child: TextButton(
                          onPressed: busy
                              ? null
                              : () => setState(() {
                                    register = !register;
                                    error = null;
                                    hidePassword = true;
                                    formKey.currentState?.reset();
                                    password.clear();
                                  }),
                          child: Text(register
                              ? 'Đã có tài khoản? Đăng nhập'
                              : 'Chưa có tài khoản? Đăng ký'))),
                ])));
    return Scaffold(
        body: SafeArea(child: LayoutBuilder(builder: (context, box) {
      final wide = box.maxWidth >= 800;
      return Center(
          child: SingleChildScrollView(
        padding: EdgeInsets.symmetric(
            horizontal: wide ? 36 : 16, vertical: wide ? 40 : 16),
        child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: wide ? 1050 : 490),
            child: wide
                ? Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    const Expanded(
                        flex: 6, child: HomeCover(signIn: true, tall: true)),
                    const SizedBox(width: 34),
                    Expanded(flex: 5, child: Panel(padding: 28, child: form)),
                  ])
                : Column(children: [
                    const HomeCover(signIn: true),
                    const SizedBox(height: 16),
                    Panel(padding: 20, child: form),
                  ])),
      ));
    })));
  }
}
