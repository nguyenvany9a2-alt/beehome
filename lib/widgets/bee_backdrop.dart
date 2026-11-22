import 'package:flutter/material.dart';
import '../core/theme.dart';

const roomPhoto = 'assets/images/saigon-living-room.webp';
const mobileRoomPhoto = 'assets/images/saigon-reading-corner.webp';

Widget buildBeeBackdrop(BuildContext context, Widget? navigator,
    [Map settings = const {}]) {
  final mobile = MediaQuery.sizeOf(context).width < 700;
  final scene = settings['scene'] ?? 'auto';
  final photo = scene == 'corner' || (scene == 'auto' && mobile)
      ? mobileRoomPhoto
      : roomPhoto;
  final tint = switch (settings['tint']) {
    'sage' => const Color(0xFF759079),
    'stone' => const Color(0xFF7C8B9B),
    _ => const Color(0xFFAF8F65)
  };
  final media = MediaQuery.of(context);
  final factor = (settings['scale'] as num?)?.toDouble() ?? 1;
  return Stack(fit: StackFit.expand, children: [
    RepaintBoundary(
        child: ExcludeSemantics(
            child: ColoredBox(
                color: Color.alphaBlend(tint.withValues(alpha: .35), cream),
                child: scene == 'plain'
                    ? null
                    : Stack(fit: StackFit.expand, children: [
                        Image.asset(photo,
                            fit: BoxFit.cover,
                            alignment: mobile
                                ? const Alignment(.30, .14)
                                : const Alignment(.20, .48),
                            errorBuilder: (_, e, st) =>
                                const SizedBox.shrink()),
                        ColoredBox(
                            color: tint.withValues(
                                alpha: settings['tint'] == null ||
                                        settings['tint'] == 'warm'
                                    ? .08
                                    : .31))
                      ])))),
    if (navigator != null)
      MediaQuery(
          data: media.copyWith(
              textScaler: factor == 1
                  ? media.textScaler
                  : _ScaledText(media.textScaler, factor),
              disableAnimations:
                  media.disableAnimations || settings['still'] == true),
          child: navigator),
  ]);
}

class _ScaledText extends TextScaler {
  const _ScaledText(this.source, this.factor);
  final TextScaler source;
  final double factor;
  @override
  double scale(double size) => source.scale(size) * factor;
  @override
  double get textScaleFactor => scale(14) / 14;
  @override
  bool operator ==(Object other) =>
      other is _ScaledText && other.source == source && other.factor == factor;
  @override
  int get hashCode => Object.hash(source, factor);
}

class ReadingSurface extends StatelessWidget {
  const ReadingSurface({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final compact = MediaQuery.sizeOf(context).width < 700;
    return DecoratedBox(
        decoration: BoxDecoration(
            color: const Color(0xD5FFFCF5),
            border: Border.all(color: const Color(0xB5FFFFFF)),
            borderRadius: BorderRadius.circular(compact ? 20 : 25)),
        child:
            Padding(padding: EdgeInsets.all(compact ? 13 : 22), child: child));
  }
}
