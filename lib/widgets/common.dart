import 'package:flutter/material.dart';

import '../core/theme.dart';

class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.padding = 24});
  final Widget child;
  final double padding;
  @override
  Widget build(BuildContext c) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      border: Border.all(color: const Color(0xFFE3E8E1)),
      borderRadius: BorderRadius.circular(20),
    ),
    child: child,
  );
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = ink});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext c) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
    decoration: BoxDecoration(
      color: color.withOpacity(.09),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color),
    ),
  );
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.title, this.subtitle, {super.key});
  final String title, subtitle;
  @override
  Widget build(BuildContext c) => Panel(
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          children: [
            const Icon(Icons.inbox_outlined, size: 46, color: muted),
            const SizedBox(height: 15),
            Text(title, style: Theme.of(c).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(subtitle, textAlign: TextAlign.center),
          ],
        ),
      ),
    ),
  );
}

String statusLabel(dynamic value) =>
    {
      'pending': 'Chờ nhận',
      'accepted': 'Đã nhận',
      'working': 'Đang làm',
      'completed': 'Hoàn thành',
      'cancelled': 'Đã hủy',
      'approved': 'Đã duyệt',
      'rejected': 'Từ chối',
      'active': 'Hoạt động',
      'blocked': 'Đã khóa',
      'paid': 'Đã thanh toán',
      'unpaid': 'Chưa thanh toán',
    }[value] ??
    value.toString();

class HouseArt extends StatelessWidget {
  const HouseArt({super.key});
  @override
  Widget build(BuildContext c) =>
      CustomPaint(size: const Size(330, 230), painter: _HousePainter());
}

class _HousePainter extends CustomPainter {
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = const Color(0xFFEBD895);
    c.drawCircle(Offset(s.width * .54, s.height * .5), s.height * .45, p);
    p.color = const Color(0xFFFFFEF5);
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .24,
          s.height * .35,
          s.width * .55,
          s.height * .52,
        ),
        const Radius.circular(8),
      ),
      p,
    );
    p.color = ink;
    final roof = Path()
      ..moveTo(s.width * .16, s.height * .38)
      ..lineTo(s.width * .52, s.height * .1)
      ..lineTo(s.width * .87, s.height * .38)
      ..close();
    c.drawPath(roof, p);
    p.color = honey;
    c.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          s.width * .46,
          s.height * .57,
          s.width * .14,
          s.height * .3,
        ),
        const Radius.circular(3),
      ),
      p,
    );
    p.color = const Color(0xFF99BCAD);
    for (final x in [.3, .66]) {
      c.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            s.width * x,
            s.height * .49,
            s.width * .08,
            s.height * .13,
          ),
          const Radius.circular(3),
        ),
        p,
      );
    }
    p.color = ink;
    c.drawLine(
      Offset(s.width * .12, s.height * .89),
      Offset(s.width * .92, s.height * .89),
      p..strokeWidth = 3,
    );
    c.drawLine(
      Offset(s.width * .13, s.height * .88),
      Offset(s.width * .13, s.height * .55),
      p,
    );
    p.color = const Color(0xFF688F75);
    c.drawOval(
      Rect.fromLTWH(
        s.width * .04,
        s.height * .49,
        s.width * .11,
        s.height * .22,
      ),
      p,
    );
    c.drawOval(
      Rect.fromLTWH(
        s.width * .12,
        s.height * .56,
        s.width * .09,
        s.height * .16,
      ),
      p,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
