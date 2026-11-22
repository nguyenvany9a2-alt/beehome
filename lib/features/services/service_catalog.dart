import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../../data/bee_store.dart';
import '../../widgets/common.dart';
import '../../widgets/home_cover.dart';
import '../../widgets/bee_backdrop.dart';
import '../../widgets/scroll_reveal.dart';

class ServiceCatalog extends StatefulWidget {
  const ServiceCatalog(
      {super.key,
      required this.records,
      required this.onDetails,
      this.onManage});
  final List<RecordData> records;
  final ValueChanged<RecordData> onDetails;
  final VoidCallback? onManage;
  @override
  State<ServiceCatalog> createState() => _ServiceCatalogState();
}

class _ServiceCatalogState extends State<ServiceCatalog> {
  final search = TextEditingController();
  final focus = FocusNode();
  final searchAnchor = GlobalKey();
  final selected = <String>{};
  String category = '', unit = '', sort = '';
  double? maxPrice;
  String taskFilter = '';

  @override
  void dispose() {
    search.dispose();
    focus.dispose();
    super.dispose();
  }

  void clear() => setState(() {
        search.clear();
        taskFilter = '';
        category = '';
        unit = '';
        sort = '';
        maxPrice = null;
      });

  void searchServices() {
    final anchor = searchAnchor.currentContext;
    if (anchor == null) return;
    focus.requestFocus();
    Scrollable.ensureVisible(anchor,
        alignment: .08,
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 200));
  }

  void toggle(String id) {
    if (!selected.contains(id) && selected.length == 3) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Bạn có thể so sánh tối đa 3 dịch vụ.')));
      return;
    }
    setState(() {
      if (!selected.remove(id)) selected.add(id);
    });
  }

  List<RecordData> get active =>
      widget.records.where((r) => r['active'] == true).toList();

  @override
  void didUpdateWidget(ServiceCatalog oldWidget) {
    super.didUpdateWidget(oldWidget);
    final all = active;
    if (taskFilter.isNotEmpty &&
        !all.any((r) => includedTasks(r).contains(taskFilter))) {
      taskFilter = '';
    }
    selected.retainAll(all.map((r) => r['id'].toString()));
    if (!all.any((r) => r['category'] == category)) category = '';
    if (!all.any((r) => r['unit'] == unit)) {
      unit = '';
      sort = '';
    }
  }

  Iterable<String> includedTasks(RecordData record) {
    final items = record['includes'];
    if (items is! List) return const [];
    return items
        .whereType<String>()
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
  }

  Future<void> chooseTask(List<String> tasks) async {
    final choice = await showModalBottomSheet<String>(
        context: context,
        useSafeArea: true,
        showDragHandle: true,
        constraints: const BoxConstraints(maxWidth: 520),
        builder: (sheet) => Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
                      child: Text('Bạn cần làm việc gì?',
                          style: Theme.of(sheet).textTheme.titleLarge)),
                  Flexible(
                      child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: tasks.length,
                          itemBuilder: (_, i) => ListTile(
                              leading: const Icon(Icons.task_alt),
                              title: Text(tasks[i]),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () => Navigator.pop(sheet, tasks[i])))),
                ]));
    if (choice == null || !mounted) return;
    setState(() {
      search.clear();
      category = '';
      unit = '';
      sort = '';
      maxPrice = null;
      taskFilter = choice;
    });
  }

  Future<void> filters(List<RecordData> all) async {
    final units = all
        .map((r) => '${r['unit'] ?? ''}')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final top = all
        .map((r) => (r['price'] as num?)?.toDouble() ?? 0.0)
        .fold<double>(0, (a, b) => a > b ? a : b);
    var nextUnit = unit, nextSort = sort;
    double? limit = maxPrice?.clamp(0, top).toDouble();
    final result = await showModalBottomSheet<bool>(
        context: context,
        showDragHandle: true,
        useSafeArea: true,
        isScrollControlled: true,
        constraints: const BoxConstraints(maxWidth: 540),
        builder: (sheet) => StatefulBuilder(builder: (sheet, update) {
              final canSort = nextUnit.isNotEmpty || units.length == 1;
              return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                      22, 0, 22, 20 + MediaQuery.viewInsetsOf(sheet).bottom),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Lọc dịch vụ',
                            style: Theme.of(sheet).textTheme.headlineMedium),
                        const SizedBox(height: 20),
                        const Text('Đơn vị tính',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        const SizedBox(height: 8),
                        Wrap(spacing: 7, runSpacing: 4, children: [
                          for (final u in ['', ...units])
                            ChoiceChip(
                                label: Text(u.isEmpty ? 'Tất cả' : 'Theo $u'),
                                selected: u == nextUnit,
                                onSelected: (_) => update(() {
                                      nextUnit = u;
                                      if (u.isEmpty && units.length != 1) {
                                        nextSort = '';
                                      }
                                    })),
                        ]),
                        if (top > 0) ...[
                          const SizedBox(height: 18),
                          Text(
                              limit == null
                                  ? 'Đơn giá tối đa · Không giới hạn'
                                  : 'Đơn giá tối đa · ${money(limit!)}',
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                          Slider(
                              value: limit ?? top,
                              max: top,
                              semanticFormatterCallback: (v) => money(v),
                              onChanged: (v) => update(() => limit = v >= top
                                  ? null
                                  : v
                                      .roundToDouble()
                                      .clamp(0, top)
                                      .toDouble())),
                        ],
                        if (canSort) ...[
                          const SizedBox(height: 12),
                          DropdownButtonFormField<String>(
                              initialValue: nextSort,
                              decoration:
                                  const InputDecoration(labelText: 'Sắp xếp'),
                              isExpanded: true,
                              items: const [
                                DropdownMenuItem(
                                    value: '', child: Text('Mặc định')),
                                DropdownMenuItem(
                                    value: 'asc', child: Text('Giá tăng dần')),
                                DropdownMenuItem(
                                    value: 'desc', child: Text('Giá giảm dần'))
                              ],
                              onChanged: (v) =>
                                  update(() => nextSort = v ?? ''))
                        ],
                        const SizedBox(height: 18),
                        Wrap(
                            alignment: WrapAlignment.end,
                            spacing: 10,
                            runSpacing: 6,
                            children: [
                              TextButton(
                                  onPressed: () => update(() {
                                        nextUnit = '';
                                        nextSort = '';
                                        limit = null;
                                      }),
                                  child: const Text('Đặt lại')),
                              FilledButton(
                                  onPressed: () => Navigator.pop(sheet, true),
                                  child: const Text('Áp dụng'))
                            ]),
                      ]));
            }));
    if (result == true && mounted) {
      setState(() {
        unit = nextUnit;
        sort = nextSort;
        maxPrice = limit;
      });
    }
  }

  void compare(List<RecordData> all) {
    final records = all.where((r) => selected.contains(r['id'])).toList();
    showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
                scrollable: true,
                title: const Text('So sánh dịch vụ'),
                content: SizedBox(
                    width: 480,
                    child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final r in records)
                            Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: Panel(
                                    padding: 14,
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text('${r['name']}',
                                              style: Theme.of(c)
                                                  .textTheme
                                                  .titleLarge),
                                          Text(
                                              '${money(r['price'])} / ${r['unit']}'),
                                          if (r['duration'] != null)
                                            Text(
                                                'Thời lượng · ${r['duration']} giờ'),
                                          if (r['includes'] is List &&
                                              (r['includes'] as List)
                                                  .isNotEmpty)
                                            Text(
                                                (r['includes'] as List)
                                                    .join(' · '),
                                                style: const TextStyle(
                                                    color: muted)),
                                        ]))),
                        ])),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Đóng'))
                ]));
  }

  @override
  Widget build(BuildContext context) {
    final all = active;
    final cats = all
        .map((r) => '${r['category'] ?? ''}')
        .where((v) => v.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    final tasks = all.expand(includedTasks).toSet().toList()..sort();
    final query = folded(search.text.trim());
    final list = all
        .where((r) =>
            (taskFilter.isEmpty || includedTasks(r).contains(taskFilter)) &&
            (category.isEmpty || r['category'] == category) &&
            (unit.isEmpty || r['unit'] == unit) &&
            (maxPrice == null ||
                (r['price'] is num && r['price'] <= maxPrice)) &&
            folded("${r['name'] ?? ''} ${r['category'] ?? ''}").contains(query))
        .toList();
    if (sort.isNotEmpty) {
      list.sort((a, b) =>
          ((a['price'] as num? ?? 0).compareTo(b['price'] as num? ?? 0)) *
          (sort == 'asc' ? 1 : -1));
    }
    final filtered = taskFilter.isNotEmpty ||
        query.isNotEmpty ||
        category.isNotEmpty ||
        unit.isNotEmpty ||
        maxPrice != null ||
        sort.isNotEmpty;
    final advanced = unit.isNotEmpty || maxPrice != null || sort.isNotEmpty;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      HomeCover(onSearch: all.isEmpty ? null : searchServices),
      const SizedBox(height: 22),
      ScrollReveal(
          child: ReadingSurface(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
            Text('Danh mục dịch vụ',
                style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 12),
            if (all.isEmpty)
              EmptyView(
                  'Chưa có dịch vụ đang mở',
                  widget.onManage == null
                      ? 'Dịch vụ sẽ xuất hiện tại đây khi BeeHome mở nhận đặt lịch.'
                      : 'Thêm hoặc mở một dịch vụ trong mục Quản lý dịch vụ.',
                  icon: Icons.spa_outlined,
                  action: widget.onManage == null
                      ? null
                      : OutlinedButton(
                          onPressed: widget.onManage,
                          child: const Text('Quản lý dịch vụ')))
            else ...[
              Row(key: searchAnchor, children: [
                Expanded(
                    child: TextField(
                        controller: search,
                        focusNode: focus,
                        textInputAction: TextInputAction.search,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                            hintText: 'Tìm tên dịch vụ',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: search.text.isEmpty
                                ? null
                                : IconButton(
                                    tooltip: 'Xóa từ khóa',
                                    icon: const Icon(Icons.close),
                                    onPressed: () => setState(search.clear))))),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                    tooltip: 'Bộ lọc',
                    onPressed: () => filters(all),
                    style: IconButton.styleFrom(
                        backgroundColor: advanced ? forest : leaf,
                        foregroundColor: advanced ? Colors.white : ink,
                        minimumSize: const Size(50, 50),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14))),
                    icon: const Icon(Icons.tune_rounded)),
              ]),
              if (cats.isNotEmpty)
                Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Wrap(spacing: 7, runSpacing: 2, children: [
                      for (final c in ['', ...cats])
                        ChoiceChip(
                            showCheckmark: false,
                            label: Text(c.isEmpty ? 'Tất cả' : c),
                            selected: c == category,
                            onSelected: (_) => setState(() => category = c))
                    ])),
              const SizedBox(height: 12),
              Wrap(
                  spacing: 9,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Semantics(
                        liveRegion: true,
                        child: Text('${list.length} dịch vụ',
                            style: const TextStyle(color: muted))),
                    if (tasks.isNotEmpty)
                      TextButton.icon(
                          onPressed: () => chooseTask(tasks),
                          icon: const Icon(Icons.checklist_rounded, size: 18),
                          label: Text(taskFilter.isEmpty
                              ? 'Chọn theo công việc'
                              : taskFilter)),
                    if (advanced && unit.isNotEmpty) Tag('Theo $unit'),
                    if (advanced && maxPrice != null)
                      Tag('Đến ${money(maxPrice!)}'),
                    if (filtered)
                      TextButton(
                          onPressed: clear, child: const Text('Xóa bộ lọc')),
                    if (selected.isNotEmpty)
                      OutlinedButton.icon(
                          onPressed: () => compare(all),
                          icon: const Icon(Icons.compare_arrows),
                          label: Text('So sánh (${selected.length}/3)')),
                  ]),
            ],
          ]))),
      if (all.isNotEmpty) ...[
        const SizedBox(height: 14),
        if (list.isEmpty)
          EmptyView('Chưa tìm thấy dịch vụ',
              'Thử từ khóa ngắn hơn hoặc mở rộng bộ lọc.',
              icon: Icons.search_off_outlined,
              action: OutlinedButton(
                  onPressed: clear, child: const Text('Hiện tất cả dịch vụ')))
        else
          LayoutBuilder(builder: (c, box) {
            final cols =
                box.maxWidth >= 940 ? 3 : (box.maxWidth >= 580 ? 2 : 1);
            final width = (box.maxWidth - (cols - 1) * 14) / cols;
            return Wrap(spacing: 14, runSpacing: 14, children: [
              for (final r in list)
                SizedBox(
                    key: ValueKey(r['id']),
                    width: width,
                    child: ScrollReveal(
                        child: _ServiceCard(
                            record: r,
                            selected: selected.contains(r['id']),
                            onCompare: () => toggle(r['id']),
                            onOpen: () => widget.onDetails(r))))
            ]);
          }),
      ],
    ]);
  }
}

class _ServiceCard extends StatelessWidget {
  const _ServiceCard(
      {required this.record,
      required this.selected,
      required this.onCompare,
      required this.onOpen});
  final RecordData record;
  final bool selected;
  final VoidCallback onCompare, onOpen;

  @override
  Widget build(BuildContext context) {
    final r = record;
    final image = '${r['imageUrl'] ?? ''}'.trim();
    final label = '${r['name'] ?? 'Dịch vụ'}';
    final icon = serviceGlyph(r['icon']);
    Widget fallback() => Container(
        color: leaf,
        alignment: Alignment.center,
        child: Icon(icon, color: forest, size: 44));
    final category = '${r['category'] ?? ''}';
    final tag = '${r['tag'] ?? ''}'.trim();
    return Material(
        color: const Color(0xDFFFFEF9),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: selected ? forest : line)),
        clipBehavior: Clip.antiAlias,
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          SizedBox(
              height: image.isEmpty ? 82 : 144,
              child: Stack(fit: StackFit.expand, children: [
                InkWell(
                    onTap: onOpen,
                    child: image.isEmpty
                        ? fallback()
                        : Image.network(image,
                            fit: BoxFit.cover,
                            errorBuilder: (_, e, t) => fallback(),
                            excludeFromSemantics: true)),
                if (tag.isNotEmpty)
                  Positioned(
                      left: 10,
                      top: 10,
                      right: 66,
                      child: Align(
                          alignment: Alignment.centerLeft, child: Tag(tag))),
                Positioned(
                    right: 7,
                    top: 7,
                    child: IconButton.filled(
                        tooltip:
                            selected ? 'Bỏ so sánh $label' : 'So sánh $label',
                        onPressed: onCompare,
                        style: IconButton.styleFrom(
                            backgroundColor: selected ? forest : Colors.white,
                            foregroundColor: selected ? Colors.white : forest),
                        icon: Icon(
                            selected ? Icons.check : Icons.compare_arrows))),
              ])),
          Padding(
              padding: const EdgeInsets.fromLTRB(17, 14, 17, 15),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (category.isNotEmpty)
                      Text(category,
                          style: const TextStyle(
                              color: muted,
                              fontSize: 12,
                              fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text(label, style: Theme.of(context).textTheme.titleLarge),
                    if ((r['description'] ?? '').toString().isNotEmpty)
                      Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text('${r['description']}',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style:
                                  const TextStyle(color: muted, fontSize: 14))),
                    const SizedBox(height: 12),
                    Text(
                        r['price'] is num
                            ? '${money(r['price'])} / ${r['unit'] ?? ''}'
                            : 'Chưa cập nhật giá',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 18)),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                        onPressed: onOpen,
                        icon: const Icon(Icons.arrow_forward, size: 17),
                        label: const Text('Xem chi tiết')),
                  ])),
        ]));
  }
}
