import 'package:flutter/material.dart';
import '../core/theme.dart';
import 'common.dart';

/// The cover belongs to BeeHome's identity. Actual service images come from Firestore.
class HomeCover extends StatelessWidget {
  const HomeCover(
      {super.key, this.signIn = false, this.tall = false, this.onSearch});
  final bool signIn, tall;
  final VoidCallback? onSearch;
  @override
  Widget build(BuildContext context) => LayoutBuilder(builder: (context, box) {
        final compact = !tall && box.maxWidth < 560;
        final h =
            signIn ? (compact ? 164.0 : 450.0) : (compact ? 202.0 : 255.0);
        return ClipRRect(
            borderRadius: BorderRadius.circular(compact ? 20 : 27),
            child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: h, minWidth: box.maxWidth),
                child: Stack(children: [
                  Positioned.fill(
                      child: Image.asset(roomPhoto,
                          fit: BoxFit.cover,
                          alignment: signIn
                              ? const Alignment(.35, .35)
                              : const Alignment(.4, .38),
                          excludeFromSemantics: true)),
                  const Positioned.fill(
                      child: DecoratedBox(
                          decoration: BoxDecoration(
                              gradient: LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                        Color(0xE8152D23),
                        Color(0xA3183026),
                        Color(0x07183026)
                      ],
                                  stops: [
                        0,
                        .44,
                        1
                      ])))),
                  Padding(
                      padding: EdgeInsets.symmetric(
                          horizontal: compact ? 22 : 34,
                          vertical: compact ? 21 : 29),
                      child: ConstrainedBox(
                          constraints: BoxConstraints(
                              minHeight: h - (compact ? 42 : 58)),
                          child: Column(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (signIn) ...[
                                  const BeeBrand(light: true),
                                  SizedBox(height: compact ? 16 : 130)
                                ],
                                Text('Dịch vụ\nchăm sóc nhà',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineLarge
                                        ?.copyWith(
                                            color: Colors.white,
                                            height: 1.1,
                                            fontSize: compact
                                                ? (signIn ? 29 : 34)
                                                : 47)),
                                if (onSearch != null) ...[
                                  const SizedBox(height: 17),
                                  FilledButton.icon(
                                      onPressed: onSearch,
                                      icon: const Icon(Icons.search, size: 19),
                                      style: FilledButton.styleFrom(
                                          backgroundColor: honey,
                                          foregroundColor: ink),
                                      label: const Text('Tìm dịch vụ'))
                                ],
                              ]))),
                ])));
      });
}
