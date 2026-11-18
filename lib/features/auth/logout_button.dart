import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

/// Nút đăng xuất trên thanh trên cùng (phần của Hào).
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: 'Đăng xuất',
    icon: const Icon(Icons.logout),
    onPressed: () async {
      final ok = await showDialog<bool>(
        context: context,
        builder: (c) => AlertDialog(
          title: const Text('Đăng xuất?'),
          content: const Text('Bạn sẽ cần đăng nhập lại để tiếp tục.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Đăng xuất'),
            ),
          ],
        ),
      );
      // Đăng xuất xong thì "cổng" tự đưa về màn đăng nhập
      if (ok == true) await FirebaseAuth.instance.signOut();
    },
  );
}