import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../data/bee_store.dart';
import '../widgets/common.dart';

class BeeShell extends StatefulWidget {
  const BeeShell({super.key, required this.store, this.onBookingRequested});
  final BeeStore store;
  final ValueChanged<Map<String, dynamic>>? onBookingRequested;
  @override
  State<BeeShell> createState() => _BeeShellState();
}

class _BeeShellState extends State<BeeShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final searchController = TextEditingController();
  BeeStore get s => widget.store;
  String page = 'services',
      search = '',
      category = 'Tất cả',
      unit = 'Tất cả',
      sort = 'Đề xuất',
      orderFilter = 'Tất cả';
  bool unread = false;
  double maxPrice = 1000000;
  final selected = <String>{};
  String? error;
  bool busy = false;
  @override
  void initState() {
    super.initState();
    s.addListener(changed);
    page = s.admin
        ? 'dashboard'
        : s.role == 'worker'
        ? 'profile'
        : 'services';
  }

  void changed() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    s.removeListener(changed);
    searchController.dispose();
    super.dispose();
  }

  void go(String p) {
    scaffoldKey.currentState?.closeDrawer();
    searchController.clear();
    setState(() {
      page = p;
      search = '';
      error = null;
    });
  }

  void toast(String t) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t), behavior: SnackBarBehavior.floating),
      );
  }

  Future<void> task(
    Future<void> Function() fn, {
    String success = 'Đã lưu thay đổi',
  }) async {
    if (busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await fn();
      toast(success);
    } catch (e) {
      setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  List<(String, String, IconData)> get nav => s.admin
      ? [
          ('dashboard', 'Tổng quan', Icons.dashboard_outlined),
          ('manage_services', 'Quản lý dịch vụ', Icons.grid_view_outlined),
          ('users', 'Người dùng', Icons.people_outline),
          ('workers', 'Duyệt người giúp việc', Icons.verified_user_outlined),
          ('orders', 'Quản lý đơn hàng', Icons.receipt_long_outlined),
          ('services', 'Xem cửa hàng', Icons.storefront_outlined),
        ]
      : s.role == 'worker'
      ? [
          ('profile', 'Hồ sơ của tôi', Icons.person_outline),
          ('orders', 'Công việc của tôi', Icons.work_outline),
          ('notifications', 'Thông báo', Icons.notifications_outlined),
        ]
      : [
          ('services', 'Khám phá dịch vụ', Icons.grid_view_outlined),
          ('orders', 'Đơn của tôi', Icons.receipt_long_outlined),
          ('addresses', 'Địa chỉ của tôi', Icons.location_on_outlined),
          ('workers', 'Người giúp việc', Icons.people_outline),
          ('reviews', 'Đánh giá', Icons.star_outline),
          ('notifications', 'Thông báo', Icons.notifications_outlined),
          ('profile', 'Hồ sơ cá nhân', Icons.person_outline),
        ];
  @override
  Widget build(BuildContext c) {
    final wide = MediaQuery.sizeOf(c).width >= 1040;
    final count = s
        .rows('notifications')
        .where((n) => n['userId'] == s.uid && n['read'] != true)
        .length;
    return Scaffold(
      key: scaffoldKey,
      drawer: wide ? null : Drawer(child: sidebar()),
      body: Row(
        children: [
          if (wide) SizedBox(width: 250, child: sidebar()),
          Expanded(
            child: Column(
              children: [
                Container(
                  height: 82,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(color: Color(0xFFE3E8E1)),
                    ),
                  ),
                  child: Row(
                    children: [
                      if (!wide)
                        Builder(
                          builder: (c) => IconButton(
                            onPressed: () => Scaffold.of(c).openDrawer(),
                            icon: const Icon(Icons.menu),
                          ),
                        ),
                      if (MediaQuery.sizeOf(c).width >= 600)
                        const Icon(
                          Icons.location_on_outlined,
                          size: 19,
                          color: muted,
                        ),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          MediaQuery.sizeOf(c).width >= 600
                              ? 'TP. Hồ Chí Minh'
                              : 'BeeHome',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                      if (!s.live)
                        const Tag('BẢN DEMO', color: Color(0xFF916400)),
                      IconButton(
                        tooltip: 'Thông báo ($count chưa đọc)',
                        onPressed: () => go('notifications'),
                        icon: Badge(
                          isLabelVisible: count > 0,
                          label: Text('$count'),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        backgroundColor: honey,
                        child: Text(
                          s.role == 'worker' ? 'A' : 'Ý',
                          style: const TextStyle(color: ink),
                        ),
                      ),
                      if (wide) ...[
                        const SizedBox(width: 10),
                        Text(s.profile['name'] ?? 'Thành viên'),
                      ],
                    ],
                  ),
                ),
                if (busy) const LinearProgressIndicator(minHeight: 3),
                Expanded(
                  child: SingleChildScrollView(
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1370),
                        child: Padding(
                          padding: EdgeInsets.all(wide ? 32 : 18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (error != null || s.syncError != null)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 18),
                                  child: MaterialBanner(
                                    content: Text(error ?? s.syncError!),
                                    actions: [
                                      TextButton(
                                        onPressed: () =>
                                            setState(() => error = null),
                                        child: const Text('Đóng'),
                                      ),
                                    ],
                                  ),
                                ),
                              content(),
                              const SizedBox(height: 40),
                              Text(
                                s.live
                                    ? 'BeeHome · Chăm nhà gọn, sống thảnh thơi.'
                                    : 'Dữ liệu minh họa · Thay đổi được lưu trên trình duyệt này. Không tạo đơn hoặc giao dịch thật.',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget sidebar() => Container(
    color: Colors.white,
    padding: const EdgeInsets.fromLTRB(20, 30, 20, 24),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: honey,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hive_outlined, size: 27, color: ink),
            ),
            const SizedBox(width: 10),
            const Text(
              'BeeHome',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w800,
                color: ink,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Chăm nhà gọn. Sống thảnh thơi.',
          style: TextStyle(fontSize: 11, color: muted),
        ),
        const SizedBox(height: 38),
        Text(
          s.admin ? 'KHÔNG GIAN QUẢN TRỊ' : 'TỔ ẤM CỦA BẠN',
          style: const TextStyle(
            color: muted,
            fontSize: 10,
            letterSpacing: 1.5,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: ListView(
            children: nav
                .map(
                  (n) => Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: ListTile(
                      dense: true,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      selected: page == n.$1,
                      selectedTileColor: const Color(0xFFFFF2CD),
                      selectedColor: ink,
                      leading: Icon(n.$3, size: 21),
                      title: Text(
                        n.$2,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      onTap: () {
                        go(n.$1);
                      },
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        if (!s.live) ...[
          const Divider(),
          const Text(
            'Chuyển vai trò để xem demo',
            style: TextStyle(fontSize: 11, color: muted),
          ),
          DropdownButton<String>(
            isExpanded: true,
            value: s.role,
            items: const [
              DropdownMenuItem(value: 'customer', child: Text('Khách hàng')),
              DropdownMenuItem(value: 'worker', child: Text('Người giúp việc')),
              DropdownMenuItem(value: 'admin', child: Text('Quản trị viên')),
            ],
            onChanged: (v) {
              s.demoRole(v!);
              go(
                v == 'admin'
                    ? 'dashboard'
                    : v == 'worker'
                    ? 'profile'
                    : 'services',
              );
            },
          ),
          TextButton.icon(
            onPressed: () => confirm(
              'Khôi phục dữ liệu demo?',
              'Các thay đổi thử nghiệm trên trình duyệt này sẽ được thay bằng dữ liệu mẫu.',
              () => task(s.reset),
            ),
            icon: const Icon(Icons.restart_alt, size: 17),
            label: const Text('Đặt lại demo'),
          ),
        ],
      ],
    ),
  );
  Widget content() => switch (page) {
    'addresses' => addresses(),
    'profile' => profile(),
    'workers' => workers(),
    'orders' => orders(),
    'reviews' => reviews(),
    'notifications' => notifications(),
    'dashboard' => dashboard(),
    'manage_services' => manageServices(),
    'users' => users(),
    _ => services(),
  };
  Widget heading(String title, String subtitle, {Widget? action}) => Padding(
    padding: const EdgeInsets.only(bottom: 25),
    child: Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 24,
      runSpacing: 14,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 7),
            Text(subtitle, style: const TextStyle(color: muted)),
          ],
        ),
        if (action != null) action,
      ],
    ),
  );
  Widget grid(List<Widget> children, {double width = 320}) => LayoutBuilder(
    builder: (c, b) {
      final cols = (b.maxWidth / (width + 18)).floor().clamp(1, 4);
      final w = (b.maxWidth - (cols - 1) * 18) / cols;
      return Wrap(
        spacing: 18,
        runSpacing: 18,
        children: children.map((e) => SizedBox(width: w, child: e)).toList(),
      );
    },
  );
  Widget select(String value, List<String> opts, ValueChanged<String> change) =>
      DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          items: opts
              .map(
                (v) => DropdownMenuItem(
                  value: v,
                  child: Text(v, style: const TextStyle(fontSize: 14)),
                ),
              )
              .toList(),
          onChanged: (v) => change(v!),
        ),
      );
  IconData serviceIcon(RecordData r) => r['icon'] == 'laundry'
      ? Icons.local_laundry_service_outlined
      : r['icon'] == 'sparkles'
      ? Icons.auto_awesome_outlined
      : Icons.cottage_outlined;
  Widget services() {
    var list = s
        .rows('services')
        .where(
          (r) =>
              r['active'] == true &&
              folded(r['name']).contains(folded(search)) &&
              (category == 'Tất cả' || r['category'] == category) &&
              (unit == 'Tất cả' || r['unit'] == unit) &&
              (r['price'] as num) <= maxPrice,
        )
        .toList();
    if (sort != 'Đề xuất') {
      list.sort(
        (a, b) =>
            (a['price'] as num).compareTo(b['price'] as num) *
            (sort == 'Giá tăng dần' ? 1 : -1),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: const Color(0xFFF9EDC8),
            borderRadius: BorderRadius.circular(24),
          ),
          child: LayoutBuilder(
            builder: (c, b) => Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Tag('THÊM THỜI GIAN CHO ĐIỀU BẠN YÊU'),
                      const SizedBox(height: 19),
                      Text(
                        'Nhà gọn hơn.\nNgày nhẹ nhàng hơn.',
                        style: Theme.of(c).textTheme.headlineLarge
                            ?.copyWith(fontSize: b.maxWidth < 600 ? 30 : 42),
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Tìm dịch vụ phù hợp với tổ ấm của bạn.\nPhạm vi rõ ràng, lựa chọn dễ dàng.',
                        style: TextStyle(color: muted),
                      ),
                      const SizedBox(height: 21),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          FilledButton.icon(
                            onPressed: () => guide(),
                            icon: const Icon(Icons.tune, size: 18),
                            label: const Text('Tìm dịch vụ phù hợp'),
                          ),
                          OutlinedButton(
                            onPressed: () => go('workers'),
                            child: const Text('Gặp người giúp việc'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (b.maxWidth > 720)
                  const SizedBox(width: 300, height: 230, child: HouseArt()),
              ],
            ),
          ),
        ),
        const SizedBox(height: 28),
        heading(
          'Một chút giúp đỡ, nhiều thảnh thơi',
          'Dịch vụ cho từng nhu cầu trong ngôi nhà của bạn.',
        ),
        Panel(
          padding: 16,
          child: Column(
            children: [
              TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'Bạn cần giúp việc gì hôm nay?',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 24,
                runSpacing: 8,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  select(category, [
                    'Tất cả',
                    'Dọn dẹp',
                    'Giặt ủi',
                  ], (v) => setState(() => category = v)),
                  select(
                    unit,
                    ['Tất cả', 'giờ', 'gói'],
                    (v) => setState(() {
                      unit = v;
                      sort = 'Đề xuất';
                    }),
                  ),
                  select(
                    sort,
                    unit == 'Tất cả'
                        ? ['Đề xuất']
                        : ['Đề xuất', 'Giá tăng dần', 'Giá giảm dần'],
                    (v) => setState(() => sort = v),
                  ),
                  SizedBox(
                    width: 240,
                    child: Column(
                      children: [
                        Text(
                          'Đơn giá tối đa: ${money(maxPrice)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        Slider(
                          value: maxPrice,
                          min: 50000,
                          max: 1000000,
                          divisions: 19,
                          onChanged: (v) => setState(() => maxPrice = v),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      category = 'Tất cả';
                      unit = 'Tất cả';
                      sort = 'Đề xuất';
                      maxPrice = 1000000;
                      search = '';
                    }),
                    child: const Text('Xóa bộ lọc'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Text(
              '${list.length} dịch vụ',
              style: const TextStyle(color: muted),
            ),
            const Spacer(),
            if (selected.isNotEmpty)
              TextButton.icon(
                onPressed: compare,
                icon: const Icon(Icons.compare_arrows),
                label: Text('So sánh (${selected.length}/3)'),
              ),
          ],
        ),
        const SizedBox(height: 15),
        if (list.isEmpty)
          const EmptyView(
            'Không tìm thấy dịch vụ',
            'Thử thay đổi từ khóa hoặc xóa bộ lọc.',
          )
        else
          grid(list.map(serviceCard).toList()),
      ],
    );
  }

  Widget serviceCard(RecordData r) => Panel(
    padding: 0,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 145,
          decoration: const BoxDecoration(
            color: Color(0xFFEEF2E7),
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Stack(
            children: [
              Center(
                child: (r['imageUrl'] ?? '').toString().startsWith('https://')
                    ? Image.network(
                        r['imageUrl'],
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Icon(serviceIcon(r), size: 70, color: ink),
                      )
                    : Icon(serviceIcon(r), size: 70, color: ink),
              ),
              Positioned(left: 16, top: 15, child: Tag(r['tag'] ?? 'BeeHome')),
              Positioned(
                right: 10,
                bottom: 7,
                child: Checkbox(
                  value: selected.contains(r['id']),
                  semanticLabel: 'So sánh ${r['name']}',
                  onChanged: (v) => setState(() {
                    if (v == true) {
                      if (selected.length < 3) {
                        selected.add(r['id']);
                      } else {
                        toast('Chọn tối đa 3 dịch vụ.');
                      }
                    } else {
                      selected.remove(r['id']);
                    }
                  }),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(21),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(r['name'], style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 9),
              Text(
                r['description'],
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: muted, fontSize: 13),
              ),
              const SizedBox(height: 20),
              Text(
                '${money(r['price'])} / ${r['unit']}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 22,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'Tối thiểu ${r['duration']} giờ${s.live ? '' : ' · Giá minh họa'}',
                style: const TextStyle(fontSize: 11, color: muted),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => details(r),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Khám phá dịch vụ'),
                      Icon(Icons.arrow_forward, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  Future<void> modal(String title, Widget body, {List<Widget>? actions}) =>
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(child: body),
          ),
          actions:
              actions ??
              [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Đóng'),
                ),
              ],
        ),
      );
  void details(RecordData r) {
    modal(
      r['name'],
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(r['description']),
          const SizedBox(height: 20),
          Text(
            '${money(r['price'])} / ${r['unit']}',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 20),
          const Text(
            'Công việc bao gồm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...(r['includes'] as List).map(
            (x) => ListTile(
              dense: true,
              leading: const Icon(Icons.check_circle_outline, color: ink),
              title: Text('$x'),
            ),
          ),
          const Text(
            'Không bao gồm',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          ...(r['excludes'] as List).map(
            (x) => ListTile(
              dense: true,
              leading: const Icon(Icons.remove_circle_outline, color: muted),
              title: Text('$x'),
            ),
          ),
          const Text(
            'Phạm vi thử nghiệm: TP. Hồ Chí Minh. Giá cuối cùng cần được backend xác nhận khi đặt dịch vụ.',
            style: TextStyle(color: muted, fontSize: 12),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Đóng'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.pop(context);
            booking(r);
          },
          child: const Text('Chọn dịch vụ'),
        ),
      ],
    );
  }

  void compare() {
    final rs = s
        .rows('services')
        .where((r) => selected.contains(r['id']))
        .toList();
    modal(
      'So sánh dịch vụ',
      Column(
        children: rs
            .map(
              (r) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(r['name']),
                subtitle: Text(
                  '${money(r['price'])}/${r['unit']} · ${r['duration']} giờ\n${(r['includes'] as List).join(' · ')}',
                ),
                isThreeLine: true,
              ),
            )
            .toList(),
      ),
    );
  }

  void guide() {
    modal(
      'Chọn theo nhu cầu của bạn',
      Column(
        children:
            [
                  ('Dọn dẹp thường xuyên', 's1'),
                  ('Cần làm sạch toàn diện', 's2'),
                  ('Cần chăm sóc quần áo', 's3'),
                ]
                .map(
                  (x) => ListTile(
                    title: Text(x.$1),
                    trailing: const Icon(Icons.arrow_forward),
                    onTap: () {
                      Navigator.pop(context);
                      final r = s.find('services', x.$2);
                      if (r != null && r['active'] == true) {
                        details(r);
                      } else {
                        toast('Dịch vụ này hiện chưa được cung cấp.');
                      }
                    },
                  ),
                )
                .toList(),
      ),
    );
  }

  void booking(RecordData r) {
    final own = s.rows('addresses').where((a) => a['userId'] == s.uid).toList();
    if (own.isEmpty) {
      go('addresses');
      toast('Thêm địa chỉ trước khi chọn dịch vụ.');
      return;
    }
    String aid = (own.firstWhere(
      (a) => a['default'] == true,
      orElse: () => own.first,
    )['id']);
    int hours = (r['duration'] as num).toInt();
    showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: const Text('Chuẩn bị yêu cầu đặt dịch vụ'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'], style: Theme.of(c).textTheme.titleLarge),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  value: aid,
                  isExpanded: true,
                  items: own
                      .map(
                        (a) => DropdownMenuItem<String>(
                          value: a['id'],
                          child: Text(
                            '${a['label']} · ${a['detail']}',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (v) => set(() => aid = v!),
                  decoration: const InputDecoration(labelText: 'Địa chỉ'),
                ),
                const SizedBox(height: 15),
                if (r['unit'] == 'giờ')
                  Row(
                    children: [
                      const Text('Thời lượng'),
                      const Spacer(),
                      IconButton(
                        onPressed: hours > (r['duration'] as num)
                            ? () => set(() => hours--)
                            : null,
                        icon: const Icon(Icons.remove),
                      ),
                      Text('$hours giờ'),
                      IconButton(
                        onPressed: hours < 8 ? () => set(() => hours++) : null,
                        icon: const Icon(Icons.add),
                      ),
                    ],
                  ),
                const SizedBox(height: 18),
                Text(
                  'Ước tính: ${money((r['price'] as num) * (r['unit'] == 'giờ' ? hours : 1))}',
                  style: Theme.of(c).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Bạn sẽ chọn lịch và xác nhận giá ở bước đặt dịch vụ. Bản demo hiện chỉ chuẩn bị yêu cầu, chưa tạo đơn.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Quay lại'),
            ),
            FilledButton(
              onPressed: () {
                final draft = {
                  'serviceId': r['id'],
                  'addressId': aid,
                  'duration': hours,
                };
                Navigator.pop(c);
                if (widget.onBookingRequested != null) {
                  widget.onBookingRequested!(draft);
                } else {
                  modal(
                    'Yêu cầu đã sẵn sàng',
                    SelectableText(
                      'Dịch vụ: ${r['name']}\nMã dịch vụ: ${r['id']}\nMã địa chỉ: $aid\nThời lượng: $hours giờ\n\nChưa có đơn mới. Luồng đặt lịch sẽ được bổ sung khi hoàn tất tích hợp.',
                    ),
                  );
                }
              },
              child: const Text('Tiếp tục'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> confirm(String title, String text, VoidCallback yes) =>
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: Text(text),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c),
              child: const Text('Hủy'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(c);
                yes();
              },
              child: const Text('Xác nhận'),
            ),
          ],
        ),
      );
  void form(
    String title,
    Map<String, String> initial,
    Map<String, String> labels,
    Future<void> Function(Map<String, String>) save, {
    Set<String> optional = const {},
    Set<String> numbers = const {},
  }) {
    final key = GlobalKey<FormState>();
    final cs = initial.map(
      (k, v) => MapEntry(k, TextEditingController(text: v)),
    );
    showDialog<void>(
      context: context,
      builder: (c) {
        bool saving = false;
        String? message;
        return StatefulBuilder(
          builder: (c, set) => AlertDialog(
            title: Text(title),
            content: SizedBox(
              width: 540,
              child: SingleChildScrollView(
                child: Form(
                  key: key,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (message != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            message!,
                            style: const TextStyle(color: Colors.red),
                          ),
                        ),
                      ...labels.entries.map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: TextFormField(
                            controller: cs[e.key],
                            maxLines:
                                e.key == 'description' ||
                                    e.key == 'bio' ||
                                    e.key == 'includes' ||
                                    e.key == 'excludes'
                                ? 3
                                : 1,
                            keyboardType: numbers.contains(e.key)
                                ? TextInputType.number
                                : TextInputType.text,
                            decoration: InputDecoration(labelText: e.value),
                            validator: (v) {
                              v = v?.trim() ?? '';
                              if (v.isEmpty && !optional.contains(e.key))
                                return 'Vui lòng nhập ${e.value.toLowerCase()}';
                              if (v.length > 1500)
                                return 'Nội dung tối đa 1.500 ký tự';
                              if (numbers.contains(e.key) &&
                                  (num.tryParse(v) == null ||
                                      num.parse(v) <= 0))
                                return 'Nhập số lớn hơn 0';
                              if (e.key == 'phone' &&
                                  !RegExp(r'^0\d{9}$').hasMatch(v))
                                return 'Số điện thoại gồm 10 số, bắt đầu bằng 0';
                              if ((e.key == 'imageUrl' ||
                                      e.key == 'avatarUrl') &&
                                  v.isNotEmpty &&
                                  !v.startsWith('https://'))
                                return 'Dùng liên kết ảnh HTTPS';
                              return null;
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: saving ? null : () => Navigator.pop(c),
                child: const Text('Hủy'),
              ),
              FilledButton(
                onPressed: saving
                    ? null
                    : () async {
                        if (!key.currentState!.validate()) return;
                        set(() => saving = true);
                        try {
                          await save(
                            cs.map((k, v) => MapEntry(k, v.text.trim())),
                          );
                          if (c.mounted) {
                            Navigator.pop(c);
                            toast('Đã lưu thay đổi');
                          }
                        } catch (e) {
                          if (c.mounted) set(() => message = e.toString());
                        } finally {
                          if (c.mounted) set(() => saving = false);
                        }
                      },
                child: Text(saving ? 'Đang lưu…' : 'Lưu thay đổi'),
              ),
            ],
          ),
        );
      },
    ).then((_) {
      for (final c in cs.values) {
        c.dispose();
      }
    });
  }

  Widget addresses() {
    final list = s
        .rows('addresses')
        .where((a) => a['userId'] == s.uid)
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Địa chỉ của tôi',
          'Để BeeHome tìm đến đúng tổ ấm của bạn.',
          action: FilledButton.icon(
            onPressed: () => editAddress(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm địa chỉ'),
          ),
        ),
        if (list.isEmpty)
          const EmptyView(
            'Bạn chưa có địa chỉ',
            'Thêm địa chỉ đầu tiên để chuẩn bị đặt dịch vụ.',
          )
        else
          grid(
            list
                .map(
                  (a) => Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.home_outlined),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                a['label'],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                            if (a['default'] == true) const Tag('Mặc định'),
                          ],
                        ),
                        const SizedBox(height: 20),
                        Text(a['detail']),
                        Text(a['area'], style: const TextStyle(color: muted)),
                        const SizedBox(height: 15),
                        Text(
                          '${a['contact']} · ${a['phone']}',
                          style: const TextStyle(fontSize: 13),
                        ),
                        if ((a['note'] ?? '').isNotEmpty)
                          Text(
                            a['note'],
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                        const SizedBox(height: 16),
                        Wrap(
                          children: [
                            TextButton(
                              onPressed: () => editAddress(a),
                              child: const Text('Chỉnh sửa'),
                            ),
                            if (a['default'] != true)
                              TextButton(
                                onPressed: () => task(
                                  () => s.saveAddress({...a, 'default': true}),
                                ),
                                child: const Text('Đặt mặc định'),
                              ),
                            IconButton(
                              tooltip: 'Xóa địa chỉ',
                              onPressed: () => confirm(
                                'Xóa địa chỉ?',
                                'Địa chỉ trong các đơn đã đặt vẫn được giữ nguyên.',
                                () => task(() => s.deleteAddress(a['id'])),
                              ),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
            width: 420,
          ),
      ],
    );
  }

  void editAddress([RecordData? a]) {
    a ??= {
      'label': 'Nhà riêng',
      'contact': s.profile['name'],
      'phone': s.profile['phone'],
      'detail': '',
      'area': 'TP. Hồ Chí Minh',
      'note': '',
      'default': false,
    };
    final row = a;
    form(
      'Địa chỉ của bạn',
      {
        for (final k in ['label', 'contact', 'phone', 'detail', 'area', 'note'])
          k: '${row[k] ?? ''}',
      },
      {
        'label': 'Tên gợi nhớ',
        'contact': 'Người liên hệ',
        'phone': 'Số điện thoại',
        'detail': 'Địa chỉ chi tiết',
        'area': 'Khu vực',
        'note': 'Hướng dẫn tìm nhà',
      },
      (v) => s.saveAddress({...row, ...v}),
      optional: {'note'},
    );
  }

  Widget profileAvatar(RecordData p) {
    final url = (p['avatarUrl'] ?? '').toString();
    return CircleAvatar(
      radius: 35,
      backgroundColor: honey,
      child: url.startsWith('https://')
          ? ClipOval(
              child: Image.network(
                url,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    const Icon(Icons.person_outline, size: 40, color: ink),
              ),
            )
          : const Icon(Icons.person_outline, size: 40, color: ink),
    );
  }

  Widget profile() {
    final p = s.profile;
    final w = s.find('worker_profiles', s.uid);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Hồ sơ của tôi',
          'Thông tin chính xác giúp mọi trải nghiệm thuận tiện hơn.',
        ),
        grid([
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                profileAvatar(p),
                const SizedBox(height: 18),
                Text(p['name'], style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                Text(p['email'] ?? '', style: const TextStyle(color: muted)),
                Text(p['phone'] ?? ''),
                const SizedBox(height: 20),
                FilledButton.icon(
                  onPressed: () => form(
                    'Chỉnh sửa hồ sơ',
                    {
                      for (final k in ['name', 'phone', 'avatarUrl'])
                        k: '${p[k] ?? ''}',
                    },
                    {
                      'name': 'Họ tên',
                      'phone': 'Số điện thoại',
                      'avatarUrl': 'Liên kết ảnh đại diện HTTPS',
                    },
                    (v) => s.save(
                      'users',
                      s.live ? {'id': s.uid, ...v} : {...p, ...v},
                    ),
                    optional: {'avatarUrl'},
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Chỉnh sửa hồ sơ'),
                ),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Không gian cá nhân',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 15),
                const Text(
                  'Thông tin liên hệ chỉ được dùng trong phạm vi tài khoản và công việc liên quan.',
                ),
                const SizedBox(height: 18),
                if (s.role == 'customer')
                  OutlinedButton.icon(
                    onPressed: () => go('addresses'),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Quản lý địa chỉ'),
                  ),
                const SizedBox(height: 10),
                const Text(
                  'Các thay đổi email và mật khẩu được thực hiện trong phần bảo mật tài khoản sau khi tích hợp.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ], width: 400),
        if (s.role == 'worker') ...[
          const SizedBox(height: 24),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Hồ sơ nghề nghiệp',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Tag(statusLabel(w?['approval'] ?? 'pending')),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Kỹ năng: ${w?['skills'] ?? ''}'),
                Text('Khu vực: ${w?['area'] ?? ''}'),
                Text('Kinh nghiệm: ${w?['experience'] ?? ''}'),
                Text(w?['bio'] ?? ''),
                if (w?['approval'] == 'rejected')
                  Text(
                    'Lý do: ${w?['reason']}',
                    style: const TextStyle(color: Colors.red),
                  ),
                const SizedBox(height: 18),
                OutlinedButton(
                  onPressed: () => form(
                    'Cập nhật hồ sơ nghề nghiệp',
                    {
                      for (final k in ['skills', 'area', 'experience', 'bio'])
                        k: '${w?[k] ?? ''}',
                    },
                    {
                      'skills': 'Kỹ năng',
                      'area': 'Khu vực hoạt động',
                      'experience': 'Kinh nghiệm',
                      'bio': 'Giới thiệu',
                    },
                    (v) => s.save('worker_profiles', {
                      'id': s.uid,
                      ...v,
                      'name': p['name'],
                      'approval': 'pending',
                      'reason': '',
                    }),
                  ),
                  child: const Text('Chỉnh sửa và gửi duyệt'),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget workers() {
    final list = s
        .rows('worker_profiles')
        .where(
          (w) =>
              (s.admin || w['approval'] == 'approved') &&
              folded(w['name']).contains(folded(search)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          s.admin ? 'Duyệt người giúp việc' : 'Người giúp việc BeeHome',
          s.admin
              ? 'Kiểm tra hồ sơ trước khi cho phép nhận việc.'
              : 'Kỹ năng rõ ràng. Trải nghiệm được ghi nhận.',
        ),
        TextField(
          controller: searchController,
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Tìm theo tên',
          ),
        ),
        const SizedBox(height: 20),
        if (list.isEmpty)
          const EmptyView('Chưa có hồ sơ phù hợp', 'Thử tìm kiếm với tên khác.')
        else
          grid(
            list
                .map(
                  (w) => Panel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const CircleAvatar(
                              backgroundColor: Color(0xFFEAF0E6),
                              child: Icon(Icons.person_outline, color: ink),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                w['name'],
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 15),
                        Tag(statusLabel(w['approval'])),
                        const SizedBox(height: 12),
                        Text(
                          '${w['experience']} kinh nghiệm · ${w['area']}',
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        Text(w['skills']),
                        Text(
                          w['bio'],
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          (w['reviewCount'] ?? 0) == 0
                              ? 'Chưa có đánh giá'
                              : '★ ${(w['rating'] as num).toStringAsFixed(1)} · ${w['reviewCount']} đánh giá',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (s.admin) ...[
                          const SizedBox(height: 15),
                          Wrap(
                            spacing: 8,
                            children: [
                              FilledButton(
                                onPressed: w['approval'] == 'approved'
                                    ? null
                                    : () => task(
                                        () => s.approve(w['id'], true, ''),
                                      ),
                                child: const Text('Duyệt'),
                              ),
                              OutlinedButton(
                                onPressed: () => form(
                                  'Từ chối hồ sơ',
                                  {'reason': ''},
                                  {'reason': 'Lý do từ chối'},
                                  (v) =>
                                      s.approve(w['id'], false, v['reason']!),
                                ),
                                child: const Text('Từ chối'),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                )
                .toList(),
            width: 360,
          ),
      ],
    );
  }

  Widget orders() {
    final list = s
        .rows('orders')
        .where(
          (o) =>
              (s.admin ||
                  o[s.role == 'worker' ? 'workerId' : 'customerId'] == s.uid) &&
              (orderFilter == 'Tất cả' || o['status'] == orderFilter) &&
              folded('${o['id']} ${o['serviceName']}').contains(folded(search)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          s.admin ? 'Quản lý đơn hàng' : 'Đơn dịch vụ của tôi',
          'Theo dõi thông tin và trạng thái trong một nơi.',
        ),
        Wrap(
          spacing: 20,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 300,
              child: TextField(
                controller: searchController,
                onChanged: (v) => setState(() => search = v),
                decoration: const InputDecoration(
                  hintText: 'Tìm mã đơn, dịch vụ',
                  prefixIcon: Icon(Icons.search),
                ),
              ),
            ),
            DropdownButton<String>(
              value: orderFilter,
              items:
                  [
                        'Tất cả',
                        'pending',
                        'accepted',
                        'working',
                        'completed',
                        'cancelled',
                      ]
                      .map(
                        (v) => DropdownMenuItem(
                          value: v,
                          child: Text(v == 'Tất cả' ? v : statusLabel(v)),
                        ),
                      )
                      .toList(),
              onChanged: (v) => setState(() => orderFilter = v!),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (list.isEmpty)
          const EmptyView(
            'Chưa có đơn phù hợp',
            'Các đơn dịch vụ sẽ xuất hiện tại đây.',
          )
        else
          ...list.map(
            (o) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Panel(
                padding: 20,
                child: Wrap(
                  spacing: 20,
                  runSpacing: 15,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SizedBox(
                      width: 270,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            o['serviceName'],
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${o['id']} · ${o['date']}',
                            style: const TextStyle(color: muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    Tag(statusLabel(o['status'])),
                    Text(
                      money(o['total']),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    OutlinedButton(
                      onPressed: () => orderDetail(o),
                      child: const Text('Chi tiết'),
                    ),
                    if (o['customerId'] == s.uid &&
                        o['status'] == 'completed' &&
                        s.find('reviews', o['id']) == null)
                      FilledButton(
                        onPressed: () => reviewDialog(o),
                        child: const Text('Đánh giá'),
                      ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }

  void orderDetail(RecordData o) => modal(
    'Đơn ${o['id']}',
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(o['serviceName'], style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 16),
        Text('Ngày làm: ${o['date']}'),
        Text('Người giúp việc: ${o['workerName'] ?? 'Chưa có'}'),
        Text('Địa chỉ lúc đặt: ${o['addressSnapshot']}'),
        Text('Giá đã chốt: ${money(o['total'])}'),
        Text('Công việc: ${statusLabel(o['status'])}'),
        Text('Thanh toán: ${statusLabel(o['paymentStatus'])}'),
        const SizedBox(height: 20),
        const Text(
          'Màn hình hiện hỗ trợ xem thông tin đơn. Các thao tác nhận việc, hủy và cập nhật tiến độ sẽ được mở khi hoàn tất tích hợp.',
          style: TextStyle(fontSize: 12, color: muted),
        ),
      ],
    ),
  );
  Widget reviews() {
    final done = s
        .rows('orders')
        .where((o) => o['customerId'] == s.uid && o['status'] == 'completed')
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Trải nghiệm của bạn',
          'Mỗi nhận xét giúp BeeHome chăm nhà tốt hơn.',
        ),
        if (done.isEmpty)
          const EmptyView(
            'Chưa có đơn để đánh giá',
            'Bạn có thể đánh giá sau khi công việc hoàn thành.',
          )
        else
          ...done.map((o) {
            final r = s.find('reviews', o['id']);
            return Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Panel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      o['serviceName'],
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Text(
                      '${o['id']} · ${o['workerName']}',
                      style: const TextStyle(color: muted),
                    ),
                    const SizedBox(height: 15),
                    if (r == null)
                      FilledButton(
                        onPressed: () => reviewDialog(o),
                        child: const Text('Chia sẻ đánh giá'),
                      )
                    else ...[
                      Text(
                        '★' * (r['stars'] as num).toInt(),
                        style: const TextStyle(
                          color: Color(0xFFAA7600),
                          fontSize: 25,
                        ),
                      ),
                      Text(r['comment']),
                      const SizedBox(height: 8),
                      const Tag('Đã đánh giá'),
                    ],
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }

  void reviewDialog(RecordData o) {
    int stars = 0;
    String? err;
    bool sending = false;
    final text = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (c, set) => AlertDialog(
          title: Text('Đánh giá ${o['workerName']}'),
          content: SizedBox(
            width: 430,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('${o['serviceName']} · ${o['id']}'),
                const SizedBox(height: 18),
                Wrap(
                  children: List.generate(
                    5,
                    (i) => IconButton(
                      tooltip: '${i + 1} sao',
                      onPressed: () => set(() => stars = i + 1),
                      icon: Icon(
                        i < stars ? Icons.star : Icons.star_border,
                        color: const Color(0xFFAA7600),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: text,
                  maxLines: 4,
                  maxLength: 1000,
                  decoration: const InputDecoration(
                    hintText: 'Điều gì làm bạn hài lòng?',
                  ),
                ),
                if (err != null)
                  Text(err!, style: const TextStyle(color: Colors.red)),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: sending ? null : () => Navigator.pop(c),
              child: const Text('Để sau'),
            ),
            FilledButton(
              onPressed: sending
                  ? null
                  : () async {
                      if (stars == 0) {
                        set(() => err = 'Vui lòng chọn số sao.');
                        return;
                      }
                      set(() => sending = true);
                      try {
                        await s.review(o['id'], stars, text.text);
                        if (c.mounted) {
                          Navigator.pop(c);
                          toast('Cảm ơn bạn đã chia sẻ trải nghiệm!');
                        }
                      } catch (e) {
                        if (c.mounted) set(() => err = '$e');
                      } finally {
                        if (c.mounted) set(() => sending = false);
                      }
                    },
              child: Text(sending ? 'Đang gửi…' : 'Gửi đánh giá'),
            ),
          ],
        ),
      ),
    ).then((_) => text.dispose());
  }

  Widget notifications() {
    final list =
        s
            .rows('notifications')
            .where(
              (n) => n['userId'] == s.uid && (!unread || n['read'] != true),
            )
            .toList()
          ..sort((a, b) => '${b['createdAt']}'.compareTo('${a['createdAt']}'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Thông báo',
          'Mọi cập nhật về tổ ấm, ngay tại đây.',
          action: TextButton.icon(
            onPressed: () =>
                task(() => s.markRead(), success: 'Đã đọc tất cả thông báo'),
            icon: const Icon(Icons.done_all),
            label: const Text('Đánh dấu tất cả đã đọc'),
          ),
        ),
        Wrap(
          spacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Tất cả'),
              selected: !unread,
              onSelected: (_) => setState(() => unread = false),
            ),
            ChoiceChip(
              label: const Text('Chưa đọc'),
              selected: unread,
              onSelected: (_) => setState(() => unread = true),
            ),
          ],
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () =>
              task(s.enablePush, success: 'Đã bật thông báo trình duyệt'),
          icon: const Icon(Icons.notifications_active_outlined),
          label: const Text('Bật thông báo trình duyệt'),
        ),
        const SizedBox(height: 20),
        if (list.isEmpty)
          const EmptyView(
            'Bạn đã cập nhật tất cả',
            'Thông báo mới sẽ xuất hiện tại đây.',
          )
        else
          ...list.map(
            (n) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Panel(
                padding: 8,
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: n['read'] == true
                        ? cream
                        : const Color(0xFFFFE9A3),
                    child: const Icon(Icons.notifications_none, color: ink),
                  ),
                  title: Text(
                    n['title'],
                    style: TextStyle(
                      fontWeight: n['read'] == true
                          ? FontWeight.w400
                          : FontWeight.w700,
                    ),
                  ),
                  subtitle: Text(
                    '${n['body']}\n${n['createdAt'].toString().split('T').first}',
                  ),
                  isThreeLine: true,
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await task(
                      () => s.markRead(n['id']),
                      success: 'Đã đọc thông báo',
                    );
                    final o = s.find('orders', n['orderId'] ?? '');
                    if (o != null && mounted) orderDetail(o);
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget dashboard() {
    if (!s.admin)
      return const EmptyView(
        'Không có quyền',
        'Trang này dành cho quản trị viên.',
      );
    final all = s.rows('orders');
    final done = all.where((o) => o['status'] == 'completed');
    final total = done.fold<num>(0, (v, o) => v + (o['total'] as num));
    final pending = s
        .rows('worker_profiles')
        .where((w) => w['approval'] == 'pending')
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Chào Ý, BeeHome hôm nay',
          'Một góc nhìn rõ ràng để vận hành tốt hơn.',
          action: OutlinedButton.icon(
            onPressed: () => task(s.reload, success: 'Đã cập nhật dữ liệu'),
            icon: const Icon(Icons.refresh),
            label: const Text('Làm mới'),
          ),
        ),
        grid(
          [
                ('Tổng số đơn', '${all.length}', Icons.receipt_long_outlined),
                (
                  'Giá trị đơn hoàn thành',
                  money(total),
                  Icons.payments_outlined,
                ),
                (
                  'Khách hàng',
                  '${s.rows('users').where((u) => u['role'] == 'customer').length}',
                  Icons.people_outline,
                ),
                ('Hồ sơ chờ duyệt', '$pending', Icons.fact_check_outlined),
              ]
              .map(
                (x) => Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(x.$3, color: muted),
                      const SizedBox(height: 20),
                      Text(
                        x.$2,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      Text(
                        x.$1,
                        style: const TextStyle(color: muted, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              )
              .toList(),
          width: 210,
        ),
        const SizedBox(height: 24),
        grid([
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Trạng thái công việc',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 25),
                ...[
                  'pending',
                  'accepted',
                  'working',
                  'completed',
                  'cancelled',
                ].map((state) {
                  final count = all.where((o) => o['status'] == state).length;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Text(statusLabel(state)),
                            const Spacer(),
                            Text('$count'),
                          ],
                        ),
                        const SizedBox(height: 9),
                        LinearProgressIndicator(
                          value: all.isEmpty ? 0 : count / all.length,
                          minHeight: 9,
                          backgroundColor: cream,
                          color: state == 'completed' ? ink : honey,
                          borderRadius: BorderRadius.circular(5),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cần bạn quan tâm',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 20),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.verified_user_outlined),
                  title: Text('$pending hồ sơ đang chờ duyệt'),
                  subtitle: const Text('Kiểm tra kỹ năng và khu vực hoạt động'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => go('workers'),
                ),
                const Divider(),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.storefront_outlined),
                  title: const Text('Danh mục dịch vụ'),
                  subtitle: const Text('Cập nhật giá và phạm vi công việc'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => go('manage_services'),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Thống kê toàn bộ dữ liệu hiện tải. Giá trị đơn hoàn thành không phải doanh thu hoa hồng của nền tảng.',
                  style: TextStyle(fontSize: 12, color: muted),
                ),
              ],
            ),
          ),
        ], width: 420),
      ],
    );
  }

  Widget manageServices() {
    if (!s.admin)
      return const EmptyView(
        'Không có quyền',
        'Chỉ quản trị viên được quản lý dịch vụ.',
      );
    final list = s.rows('services');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Quản lý dịch vụ',
          'Một danh mục rõ ràng bắt đầu từ thông tin chính xác.',
          action: FilledButton.icon(
            onPressed: () => editService(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm dịch vụ'),
          ),
        ),
        ...list.map(
          (r) => Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Panel(
              padding: 18,
              child: Wrap(
                spacing: 22,
                runSpacing: 15,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Icon(serviceIcon(r), size: 35),
                  SizedBox(
                    width: 250,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          r['name'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(
                          '${money(r['price'])}/${r['unit']}',
                          style: const TextStyle(color: muted),
                        ),
                      ],
                    ),
                  ),
                  Tag(r['active'] == true ? 'Đang cung cấp' : 'Tạm ngừng'),
                  OutlinedButton.icon(
                    onPressed: () => editService(r),
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Chỉnh sửa'),
                  ),
                  TextButton(
                    onPressed: () => confirm(
                      r['active'] == true
                          ? 'Ngừng cung cấp dịch vụ?'
                          : 'Mở lại dịch vụ?',
                      'Giá và thông tin trong đơn đã đặt không bị thay đổi.',
                      () => task(
                        () => s.save('services', {
                          ...r,
                          'active': r['active'] != true,
                        }),
                      ),
                    ),
                    child: Text(r['active'] == true ? 'Tạm ngừng' : 'Mở lại'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void editService([RecordData? r]) {
    r ??= {
      'name': '',
      'category': 'Dọn dẹp',
      'price': 75000,
      'unit': 'giờ',
      'duration': 2,
      'description': '',
      'includes': <String>[],
      'excludes': <String>[],
      'imageUrl': '',
      'active': true,
      'icon': 'home',
      'tag': 'Dịch vụ mới',
    };
    final row = r;
    form(
      'Thông tin dịch vụ',
      {
        'name': '${row['name']}',
        'category': '${row['category']}',
        'price': '${row['price']}',
        'unit': '${row['unit']}',
        'duration': '${row['duration']}',
        'description': '${row['description']}',
        'includes': (row['includes'] as List).join('\n'),
        'excludes': (row['excludes'] as List).join('\n'),
        'imageUrl': '${row['imageUrl'] ?? ''}',
      },
      {
        'name': 'Tên dịch vụ',
        'category': 'Loại: Dọn dẹp hoặc Giặt ủi',
        'price': 'Đơn giá (đồng)',
        'unit': 'Đơn vị: giờ hoặc gói',
        'duration': 'Thời lượng tối thiểu (giờ)',
        'description': 'Mô tả',
        'includes': 'Bao gồm (mỗi dòng một mục)',
        'excludes': 'Không bao gồm (mỗi dòng một mục)',
        'imageUrl': 'Liên kết ảnh HTTPS',
      },
      (v) async {
        if (!['giờ', 'gói'].contains(v['unit']))
          throw StateError('Đơn vị chỉ nhận giờ hoặc gói.');
        if (!['Dọn dẹp', 'Giặt ủi'].contains(v['category']))
          throw StateError('Chọn loại Dọn dẹp hoặc Giặt ủi.');
        final h = int.tryParse(v['duration']!);
        if (h == null || h < 1 || h > 8)
          throw StateError('Thời lượng phải là số nguyên từ 1 đến 8.');
        await s.save('services', {
          ...row,
          ...v,
          'price': num.parse(v['price']!),
          'duration': h,
          'includes': v['includes']!
              .split('\n')
              .where((x) => x.trim().isNotEmpty)
              .toList(),
          'excludes': v['excludes']!
              .split('\n')
              .where((x) => x.trim().isNotEmpty)
              .toList(),
        });
      },
      optional: {'imageUrl', 'excludes'},
      numbers: {'price', 'duration'},
    );
  }

  Widget users() {
    if (!s.admin)
      return const EmptyView(
        'Không có quyền',
        'Trang này dành cho quản trị viên.',
      );
    final list = s
        .rows('users')
        .where(
          (u) => folded('${u['name']} ${u['email']}').contains(folded(search)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading('Người dùng', 'Quản lý tài khoản và trạng thái hoạt động.'),
        TextField(
          controller: searchController,
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
            hintText: 'Tìm theo tên hoặc email',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        const SizedBox(height: 20),
        ...list.map(
          (u) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              child: Wrap(
                spacing: 20,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  SizedBox(
                    width: 280,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          u['name'],
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        Text(u['email'], style: const TextStyle(color: muted)),
                      ],
                    ),
                  ),
                  Tag(
                    u['role'] == 'worker'
                        ? 'Người giúp việc'
                        : u['role'] == 'admin'
                        ? 'Quản trị viên'
                        : 'Khách hàng',
                  ),
                  Tag(statusLabel(u['status'])),
                  TextButton(
                    onPressed: u['id'] == s.uid
                        ? null
                        : () => confirm(
                            u['status'] == 'blocked'
                                ? 'Mở khóa tài khoản?'
                                : 'Khóa tài khoản?',
                            'Thay đổi trạng thái quyền sử dụng tài khoản này.',
                            () => task(
                              () => s.setUserStatus(
                                u['id'],
                                u['status'] == 'blocked' ? 'active' : 'blocked',
                              ),
                            ),
                          ),
                    child: Text(
                      u['status'] == 'blocked' ? 'Mở khóa' : 'Khóa tài khoản',
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
