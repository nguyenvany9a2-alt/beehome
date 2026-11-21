import 'package:flutter/material.dart';

import '../core/theme.dart';

const roomPhoto = 'assets/images/saigon-living-room.webp';
const mobileRoomPhoto = 'assets/images/saigon-reading-corner.webp';

/// Put the photograph behind the Navigator so scrolling, sheets and route
/// changes share one stationary background.
Widget buildBeeBackdrop(BuildContext context, Widget? navigator) {
  final width = MediaQuery.sizeOf(context).width;
  final mobile = width < 700;
  return Stack(fit: StackFit.expand, children: [
    RepaintBoundary(
      child: ExcludeSemantics(
        child: ColoredBox(
          color: cream,
          child: Stack(fit: StackFit.expand, children: [
            Image.asset(mobile ? mobileRoomPhoto : roomPhoto,
                fit: BoxFit.cover,
                alignment: mobile
                    ? const Alignment(.30, .14)
                    : const Alignment(.20, .48),
                errorBuilder: (_, error, stack) => const SizedBox.shrink()),
            const ColoredBox(color: Color(0x142D2617)),
          ]),
        ),
      ),
    ),
    if (navigator != null) navigator,
  ]);
}

/// Backing for text and controls that were designed to sit on a light page.
class ReadingSurface extends StatelessWidget {
  const ReadingSurface({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xEEFFFCF5),
        border: Border.all(color: const Color(0xB5FFFFFF)),
        borderRadius: BorderRadius.circular(compact ? 20 : 25),
      ),
      child: Padding(padding: EdgeInsets.all(compact ? 13 : 22), child: child),
    );
  }
}
