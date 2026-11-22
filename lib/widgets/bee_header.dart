import 'dart:ui' show ImageFilter;
import 'package:flutter/material.dart';
import 'common.dart';
import '../core/theme.dart';

class BeeHeader extends StatelessWidget {
  const BeeHeader(
      {super.key,
      required this.home,
      required this.account,
      required this.alerts,
      this.menu,
      this.unread = 0,
      this.signedIn = true});
  final VoidCallback home, account, alerts;
  final VoidCallback? menu;
  final int unread;
  final bool signedIn;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 380;
    return ClipRect(
        child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
            child: Material(
                color: const Color(0xD020382F),
                child: SafeArea(
                    bottom: false,
                    child: SizedBox(
                        height: narrow ? 60 : 66,
                        child: Stack(alignment: Alignment.center, children: [
                          if (menu != null)
                            Positioned(
                                left: 4,
                                child: IconButton(
                                    tooltip: 'Mở menu',
                                    color: Colors.white,
                                    onPressed: menu,
                                    icon: const Icon(Icons.menu_rounded))),
                          Positioned.fill(
                              left: narrow ? 86 : 104,
                              right: narrow ? 86 : 104,
                              child: Center(
                                  child: Tooltip(
                                      message: 'Về trang chủ',
                                      child: TextButton(
                                          onPressed: home,
                                          style: TextButton.styleFrom(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: narrow ? 4 : 14)),
                                          child: const FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: BeeBrand(light: true)))))),
                          Positioned(
                              right: narrow ? 0 : 9,
                              child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    IconButton(
                                        tooltip: 'Thông báo ($unread chưa đọc)',
                                        color: Colors.white,
                                        onPressed: alerts,
                                        icon: Badge(
                                            isLabelVisible: unread > 0,
                                            backgroundColor: honey,
                                            textColor: ink,
                                            label: Text(unread > 99
                                                ? '99+'
                                                : '$unread'),
                                            child: const Icon(Icons
                                                .notifications_none_rounded))),
                                    IconButton(
                                        tooltip:
                                            signedIn ? 'Mở hồ sơ' : 'Đăng nhập',
                                        color: Colors.white,
                                        onPressed: account,
                                        icon: const Icon(
                                            Icons.account_circle_outlined)),
                                  ])),
                        ]))))));
  }
}
