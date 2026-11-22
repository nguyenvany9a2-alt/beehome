import 'package:flutter/material.dart';

import '../core/theme.dart';

import 'scroll_reveal.dart';

class BeeBrand extends StatelessWidget {
  const BeeBrand({super.key, this.light = false});
  final bool light;
  @override
  Widget build(BuildContext context) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        ExcludeSemantics(
            child: Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                    color: honey, borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.hive_outlined, color: ink, size: 25))),
        const SizedBox(width: 9),
        Text('BeeHome',
            style: TextStyle(
                fontFamily: 'Work Sans',
                fontSize: 22,
                letterSpacing: -.9,
                height: 1.12,
                fontWeight: FontWeight.w800,
                color: light ? Colors.white : ink)),
      ]);
}

class Panel extends StatelessWidget {
  const Panel(
      {super.key, required this.child, this.padding = 22, this.reveal = false});
  final Widget child;
  final double padding;
  final bool reveal;
  @override
  Widget build(BuildContext context) {
    final panel = SizedBox(
        width: double.infinity,
        child: Material(
            color: const Color(0xDAFFFEFA),
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: line)),
            child: Padding(padding: EdgeInsets.all(padding), child: child)));
    return reveal ? ScrollReveal(child: panel) : panel;
  }
}

class Tag extends StatelessWidget {
  const Tag(this.text, {super.key, this.color = forest});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
        decoration: BoxDecoration(
            color: Color.alphaBlend(color.withValues(alpha: .09), Colors.white),
            borderRadius: BorderRadius.circular(20)),
        child: Text(text,
            style: TextStyle(
                fontSize: 12,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: color)),
      );
}

class EmptyView extends StatelessWidget {
  const EmptyView(this.title, this.subtitle,
      {super.key, this.icon = Icons.inbox_outlined, this.action});
  final String title, subtitle;
  final IconData icon;
  final Widget? action;
  @override
  Widget build(BuildContext context) => Panel(
          child: Column(children: [
        DecoratedBox(
            decoration:
                const BoxDecoration(shape: BoxShape.circle, color: leaf),
            child: Padding(
                padding: const EdgeInsets.all(14),
                child: Icon(icon, size: 26, color: forest))),
        const SizedBox(height: 14),
        Text(title,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 6),
        ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Text(subtitle,
                textAlign: TextAlign.center,
                style: const TextStyle(color: muted))),
        if (action != null) ...[const SizedBox(height: 12), action!],
      ]));
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.icon, this.label, this.value, {super.key});
  final IconData icon;
  final String label, value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(icon, color: muted, size: 20),
        const SizedBox(width: 12),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: muted)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ])),
      ]));
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

Color statusColor(Object? value) => switch (value) {
      'pending' || 'unpaid' => const Color(0xFF795411),
      'working' || 'accepted' => const Color(0xFF225D75),
      'cancelled' || 'rejected' || 'blocked' => danger,
      _ => forest,
    };
