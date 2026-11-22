import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/bee_store.dart';
import '../../widgets/bee_backdrop.dart';
import '../../widgets/common.dart';
import '../../widgets/scroll_reveal.dart';

class HomePage extends StatefulWidget {
  const HomePage(
      {super.key,
      required this.services,
      required this.onService,
      this.onExplore,
      this.actionLabel,
      this.onAction,
      this.loading = false,
      this.error,
      this.retry});
  final List<RecordData> services;
  final ValueChanged<RecordData> onService;
  final VoidCallback? onExplore, onAction, retry;
  final String? actionLabel, error;
  final bool loading;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final servicesKey = GlobalKey();
  void explore() {
    if (widget.onExplore != null) {
      widget.onExplore!();
      return;
    }
    final section = servicesKey.currentContext;
    if (section != null) {
      Scrollable.ensureVisible(section,
          duration: MediaQuery.disableAnimationsOf(context)
              ? Duration.zero
              : const Duration(milliseconds: 360),
          curve: Curves.easeOut);
    }
  }

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 650;
    final services = [...widget.services.where((s) => s['active'] == true)]
      ..sort((a, b) => '${a['name']}'.compareTo('${b['name']}'));
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Container(
          alignment: Alignment.centerLeft,
          constraints: BoxConstraints(minHeight: narrow ? 355 : 405),
          padding: EdgeInsets.symmetric(
              horizontal: narrow ? 23 : 52, vertical: narrow ? 28 : 45),
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: Colors.white30),
              gradient: const LinearGradient(colors: [
                Color(0xF0183028),
                Color(0xCF20372B),
                Color(0x40213225)
              ], stops: [
                0,
                .43,
                1
              ])),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 530),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Chăm sóc nhà,\nnhẹ ngày của bạn.',
                        style: TextStyle(
                            fontFamily: 'Playfair Display',
                            fontSize: narrow ? 43 : 63,
                            height: 1.09,
                            letterSpacing: -1.5,
                            color: const Color(0xFFFFF7E7),
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 18),
                    const Text(
                        'Tìm người giúp việc cho ngôi nhà của bạn. Chọn dịch vụ, xem giá và hẹn lịch ngay trên BeeHome.',
                        style: TextStyle(
                            color: Color(0xFFFFF6E8),
                            fontSize: 16,
                            height: 1.5)),
                    const SizedBox(height: 26),
                    Wrap(
                        spacing: 12,
                        runSpacing: 10,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          FilledButton.icon(
                              onPressed: explore,
                              style: FilledButton.styleFrom(
                                  backgroundColor: honey, foregroundColor: ink),
                              icon:
                                  const Icon(Icons.grid_view_rounded, size: 18),
                              label: const Text('Khám phá dịch vụ')),
                          if (widget.onAction != null)
                            TextButton(
                                onPressed: widget.onAction,
                                style: TextButton.styleFrom(
                                    foregroundColor: Colors.white),
                                child: Text(widget.actionLabel!)),
                        ]),
                  ]))),
      const SizedBox(height: 22),
      ReadingSurface(
          key: servicesKey,
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
            Text('Dịch vụ đang mở',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 16),
            if (widget.loading)
              const LinearProgressIndicator(semanticsLabel: 'Đang tải dịch vụ')
            else if (widget.error != null)
              EmptyView('Chưa tải được danh mục', widget.error!,
                  action: TextButton(
                      onPressed: widget.retry, child: const Text('Thử lại')))
            else if (services.isEmpty)
              const EmptyView('Chưa có dịch vụ đang mở',
                  'Các dịch vụ sẽ xuất hiện khi BeeHome mở nhận lịch.',
                  icon: Icons.spa_outlined)
            else
              LayoutBuilder(builder: (context, box) {
                final n = box.maxWidth > 880
                    ? 3
                    : box.maxWidth > 540
                        ? 2
                        : 1;
                final cards =
                    widget.onExplore == null ? services : services.take(6);
                return Wrap(spacing: 12, runSpacing: 12, children: [
                  for (final s in cards)
                    SizedBox(
                        width: (box.maxWidth - (n - 1) * 12) / n,
                        child: Material(
                            color: const Color(0xCEFFFDF6),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(17),
                                side:
                                    const BorderSide(color: Color(0x80FFFFFF))),
                            clipBehavior: Clip.antiAlias,
                            child: InkWell(
                                onTap: () => widget.onService(s),
                                child: Padding(
                                    padding: const EdgeInsets.all(17),
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(children: [
                                            Icon(serviceGlyph(s['icon']),
                                                color: forest, size: 20),
                                            const SizedBox(width: 8),
                                            Expanded(
                                                child: Text(
                                                    '${s['category'] ?? 'Dịch vụ tại nhà'}',
                                                    style: const TextStyle(
                                                        color: muted,
                                                        fontSize: 13))),
                                            const Icon(Icons.arrow_outward,
                                                size: 17, color: forest)
                                          ]),
                                          const SizedBox(height: 12),
                                          Text('${s['name']}',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleLarge),
                                          const SizedBox(height: 7),
                                          Text(
                                              s['price'] is num
                                                  ? '${money(s['price'])} / ${s['unit'] ?? 'gói'}'
                                                  : 'Liên hệ BeeHome',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w600,
                                                  color: forest)),
                                        ])))))
                ]);
              })
          ])),
      const SizedBox(height: 22),
      ScrollReveal(
          child: ReadingSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text('Đặt lịch cùng BeeHome',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 14),
            LayoutBuilder(builder: (context, box) {
              final cols = box.maxWidth >= 700 ? 3 : 1;
              const steps = [
                (
                  Icons.search_rounded,
                  'Chọn dịch vụ',
                  'Xem phạm vi công việc, đơn giá và thời lượng.'
                ),
                (
                  Icons.calendar_today_outlined,
                  'Hẹn ngày làm',
                  'Chọn địa chỉ và giờ bắt đầu, kiểm tra tổng tiền trước khi đặt.'
                ),
                (
                  Icons.fact_check_outlined,
                  'Theo dõi công việc',
                  'Xem người nhận việc, theo dõi tiến độ và đánh giá sau khi hoàn thành.'
                ),
              ];
              return Wrap(spacing: 16, runSpacing: 16, children: [
                for (final v in steps)
                  SizedBox(
                      width: (box.maxWidth - (cols - 1) * 16) / cols,
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(v.$1, color: forest),
                            const SizedBox(height: 8),
                            Text(v.$2,
                                style: Theme.of(context).textTheme.titleLarge),
                            const SizedBox(height: 4),
                            Text(v.$3)
                          ]))
              ]);
            }),
          ])))
    ]);
  }
}
