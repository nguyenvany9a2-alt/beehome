import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Màn đăng nhập / đăng ký (phần của Hào).
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

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
    if (!formKey.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final auth = FirebaseAuth.instance;
      if (register) {
        final cred = await auth.createUserWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
        await saveProfile(cred.user!.uid);
      } else {
        await auth.signInWithEmailAndPassword(
          email: email.text.trim(),
          password: password.text,
        );
      }
      // Đăng nhập thành công thì "cổng" tự chuyển sang app, không cần làm gì thêm.
    } on FirebaseAuthException catch (e) {
      error = message(e.code);
    } catch (e) {
      error = '$e';
    }
    if (mounted) setState(() => busy = false);
  }

  /// Lưu hồ sơ người dùng vào Firestore lúc đăng ký.
  Future<void> saveProfile(String uid) async {
    final db = FirebaseFirestore.instance;
    await db.collection('users').doc(uid).set({
      'name': name.text.trim(),
      'email': email.text.trim(),
      'phone': phone.text.trim(),
      'avatarUrl': '',
      'role': role,
      'status': 'active',
      'createdAt': DateTime.now().toIso8601String(),
    });
    // Người giúp việc có thêm hồ sơ nghề nghiệp, chờ admin duyệt.
    if (role == 'worker') {
      await db.collection('worker_profiles').doc(uid).set({
        'name': name.text.trim(),
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
      setState(() => error = message(x.code));
    }
  }

  /// Đổi mã lỗi Firebase sang tiếng Việt.
  String message(String code) => switch (code) {
    'invalid-email' => 'Email không hợp lệ.',
    'invalid-credential' ||
    'wrong-password' ||
    'user-not-found' => 'Email hoặc mật khẩu không đúng.',
    'email-already-in-use' => 'Email này đã được đăng ký.',
    'weak-password' => 'Mật khẩu cần ít nhất 6 ký tự.',
    'too-many-requests' => 'Thử sai quá nhiều lần, vui lòng đợi một lát.',
    'network-request-failed' => 'Không có kết nối mạng.',
    _ => 'Có lỗi xảy ra ($code).',
  };

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 14);
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hive_outlined,
                    size: 56,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'BeeHome',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  Text(
                    register ? 'Tạo tài khoản mới' : 'Đăng nhập để tiếp tục',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  const SizedBox(height: 28),
                  if (register) ...[
                    TextFormField(
                      controller: name,
                      decoration: const InputDecoration(labelText: 'Họ tên'),
                      validator: (v) => (v ?? '').trim().isEmpty
                          ? 'Vui lòng nhập họ tên'
                          : null,
                    ),
                    gap,
                    TextFormField(
                      controller: phone,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại',
                      ),
                      validator: (v) =>
                          RegExp(r'^0\d{9}$').hasMatch((v ?? '').trim())
                          ? null
                          : 'Số điện thoại gồm 10 số, bắt đầu bằng 0',
                    ),
                    gap,
                  ],
                  TextFormField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => (v ?? '').contains('@')
                        ? null
                        : 'Email không hợp lệ',
                  ),
                  gap,
                  TextFormField(
                    controller: password,
                    obscureText: hidePassword,
                    decoration: InputDecoration(
                      labelText: 'Mật khẩu',
                      suffixIcon: IconButton(
                        onPressed: () =>
                            setState(() => hidePassword = !hidePassword),
                        icon: Icon(
                          hidePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (v) => (v ?? '').length < 6
                        ? 'Mật khẩu cần ít nhất 6 ký tự'
                        : null,
                    onFieldSubmitted: (_) => submit(),
                  ),
                  if (register) ...[
                    const SizedBox(height: 20),
                    const Text('Bạn đăng ký với vai trò'),
                    const SizedBox(height: 8),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'customer',
                          label: Text('Khách hàng'),
                          icon: Icon(Icons.home_outlined),
                        ),
                        ButtonSegment(
                          value: 'worker',
                          label: Text('Người giúp việc'),
                          icon: Icon(Icons.cleaning_services_outlined),
                        ),
                      ],
                      selected: {role},
                      onSelectionChanged: (v) => setState(() => role = v.first),
                    ),
                  ],
                  if (error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Text(
                        error!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  const SizedBox(height: 22),
                  FilledButton(
                    onPressed: busy ? null : submit,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Text(
                        busy
                            ? 'Đang xử lý…'
                            : register
                            ? 'Đăng ký'
                            : 'Đăng nhập',
                      ),
                    ),
                  ),
                  if (!register)
                    TextButton(
                      onPressed: busy ? null : forgotPassword,
                      child: const Text('Quên mật khẩu?'),
                    ),
                  TextButton(
                    onPressed: busy
                        ? null
                        : () => setState(() {
                            register = !register;
                            error = null;
                          }),
                    child: Text(
                      register
                          ? 'Đã có tài khoản? Đăng nhập'
                          : 'Chưa có tài khoản? Đăng ký',
                    ),
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