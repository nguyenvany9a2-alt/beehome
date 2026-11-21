import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

/// Fade in once when this section first intersects its vertical viewport.
class ScrollReveal extends StatefulWidget {
  const ScrollReveal({super.key, required this.child});
  final Widget child;

  @override
  State<ScrollReveal> createState() => _ScrollRevealState();
}

class _ScrollRevealState extends State<ScrollReveal>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 300));
  late final _progress =
      _controller.drive(CurveTween(curve: Curves.easeOutCubic));
  ScrollPosition? _position;
  bool _entered = false;
  bool _scheduled = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduced = MediaQuery.disableAnimationsOf(context) ||
        MediaQuery.accessibleNavigationOf(context);
    final next = Scrollable.maybeOf(context, axis: Axis.vertical)?.position;
    if (reduced || next == null) {
      _reveal(immediate: true);
      return;
    }
    if (_entered) return;
    // A taller window can bring a section into view without a scroll event.
    MediaQuery.sizeOf(context);
    if (_position != next) {
      _position?.removeListener(_scheduleCheck);
      _position = next..addListener(_scheduleCheck);
    }
    _scheduleCheck();
  }

  @override
  void didUpdateWidget(ScrollReveal oldWidget) {
    super.didUpdateWidget(oldWidget);
    _scheduleCheck();
  }

  void _scheduleCheck() {
    if (_entered || _scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || _entered) return;
      final box = context.findRenderObject();
      final position = _position;
      if (box is! RenderBox ||
          !box.hasSize ||
          position == null ||
          !position.hasContentDimensions) {
        return;
      }
      final viewport = RenderAbstractViewport.maybeOf(box);
      if (viewport == null) {
        _reveal(immediate: true);
        return;
      }
      final top = viewport.getOffsetToReveal(box, 0).offset;
      final bottom = top + box.size.height;
      if (top < position.pixels + position.viewportDimension &&
          bottom > position.pixels) {
        _reveal();
      }
    });
  }

  void _reveal({bool immediate = false}) {
    _entered = true;
    _position?.removeListener(_scheduleCheck);
    _position = null;
    if (immediate) {
      _controller.value = 1;
    } else {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _position?.removeListener(_scheduleCheck);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _progress,
      alwaysIncludeSemantics: true,
      child: AnimatedBuilder(
        animation: _progress,
        child: widget.child,
        builder: (context, child) => Transform.translate(
          offset: Offset(0, (1 - _progress.value) * 12),
          transformHitTests: false,
          child: child,
        ),
      ),
    );
  }
}
