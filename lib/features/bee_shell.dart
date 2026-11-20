import 'package:flutter/material.dart';
import 'booking/order_buttons.dart';
import 'booking/booking_flow.dart';
import 'services/service_catalog.dart';
import '../core/theme.dart';
import '../data/bee_store.dart';
import '../widgets/common.dart';
import 'auth/logout_button.dart';

class BeeShell extends StatefulWidget {
  const BeeShell({super.key, required this.store, this.onBookingRequested});
  final BeeStore store;
  final ValueChanged<Map<String, dynamic>>? onBookingRequested;
  @override
  State<BeeShell> createState() => _BeeShellState();
}

class _BeeShellState extends State<BeeShell> {
  final scaffoldKey = GlobalKey<ScaffoldState>();
  final pageScroll = ScrollController();
  final searchController = TextEditingController();
  BeeStore get s => widget.store;
  String page = 'services', search = '', orderFilter = 'Tất cả';
  bool unread = false;
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
    pageScroll.dispose();
    s.removeListener(changed);
    searchController.dispose();
    super.dispose();
  }

  void go(String p) {
    scaffoldKey.currentState?.closeDrawer();
    if (pageScroll.hasClients) pageScroll.jumpTo(0);
    FocusManager.instance.primaryFocus?.unfocus();
    searchController.clear();
    setState(() {
      page = p;
      search = '';
      error = null;
    });
  }

  void toast(String t) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t), behavior: SnackBarBehavior.floating),
      );
    }
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
      if (mounted) {
        setState(() => error = e.toString().replaceFirst('Bad state: ', ''));
      }
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
  String get roleLabel => s.admin
      ? 'Quản trị viên'
      : s.role == 'worker'
          ? 'Người giúp việc'
          : 'Khách hàng';

  List<(String, String, IconData)> get mobileNav => s.admin
      ? [
          ('dashboard', 'Tổng quan', Icons.dashboard_outlined),
          ('orders', 'Đơn hàng', Icons.receipt_long_outlined),
          ('manage_services', 'Dịch vụ', Icons.grid_view_outlined),
          ('more', 'Thêm', Icons.menu)
        ]
      : s.role == 'worker'
          ? [
              ('profile', 'Hồ sơ', Icons.person_outline),
              ('orders', 'Công việc', Icons.work_outline),
              ('notifications', 'Thông báo', Icons.notifications_outlined)
            ]
          : [
              ('services', 'Dịch vụ', Icons.grid_view_outlined),
              ('orders', 'Đơn đặt', Icons.receipt_long_outlined),
              ('profile', 'Hồ sơ', Icons.person_outline),
              ('more', 'Thêm', Icons.menu)
            ];

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1000;
    final items = mobileNav;
    final index = items.indexWhere((n) => n.$1 == page);
    final notifications = s
        .rows('notifications')
        .where((n) => n['userId'] == s.uid && n['read'] != true)
        .length;
    final title = nav.where((n) => n.$1 == page).map((n) => n.$2).firstOrNull ??
        'Thông báo';
    final problem = error ?? s.syncError;
    return Scaffold(
        key: scaffoldKey,
        drawer: wide ? null : Drawer(child: sidebar()),
        bottomNavigationBar: wide
            ? null
            : NavigationBar(
                selectedIndex: index < 0 ? items.length - 1 : index,
                onDestinationSelected: (i) => items[i].$1 == 'more'
                    ? scaffoldKey.currentState?.openDrawer()
                    : go(items[i].$1),
                destinations: [
                    for (final n in items)
                      NavigationDestination(icon: Icon(n.$3), label: n.$2)
                  ]),
        body: SafeArea(
            bottom: false,
            child: Row(children: [
              if (wide) SizedBox(width: 236, child: sidebar()),
              Expanded(
                  child: Column(children: [
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: wide ? 28 : 12, vertical: 7),
                    decoration: const BoxDecoration(
                        color: Colors.white,
                        border: Border(bottom: BorderSide(color: line))),
                    child: Row(children: [
                      if (wide)
                        Expanded(
                            child: Text(title,
                                style: const TextStyle(
                                    color: muted, fontWeight: FontWeight.w600)))
                      else
                        Expanded(
                            child: Row(children: [
                          if (s.role == 'worker')
                            IconButton(
                                tooltip: 'Mở menu',
                                icon: const Icon(Icons.menu),
                                onPressed: () =>
                                    scaffoldKey.currentState?.openDrawer()),
                          const Flexible(
                              child: FittedBox(
                                  fit: BoxFit.scaleDown, child: BeeBrand())),
                        ])),
                      IconButton(
                          tooltip: 'Thông báo ($notifications chưa đọc)',
                          onPressed: () => go('notifications'),
                          icon: Badge(
                              isLabelVisible: notifications > 0,
                              backgroundColor: forest,
                              label: Text(notifications > 99
                                  ? '99+'
                                  : '$notifications'),
                              child: const Icon(
                                  Icons.notifications_none_rounded))),
                      if (wide && !s.admin)
                        Padding(
                            padding: const EdgeInsets.only(left: 6),
                            child: IconButton(
                                tooltip: 'Mở hồ sơ',
                                icon: const Icon(Icons.account_circle_outlined),
                                onPressed: () => go('profile'))),
                    ])),
                if (busy) const LinearProgressIndicator(minHeight: 2),
                if (problem != null)
                  Material(
                      color: const Color(0xFFFBE8E3),
                      child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          child: Row(children: [
                            const Icon(Icons.info_outline, color: danger),
                            const SizedBox(width: 8),
                            Expanded(
                                child: Text(problem,
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(color: danger))),
                            TextButton(
                                onPressed: busy
                                    ? null
                                    : () => task(s.reload,
                                        success: 'Đã tải lại dữ liệu'),
                                child: const Text('Thử lại')),
                          ]))),
                Expanded(
                    child: SingleChildScrollView(
                        controller: pageScroll,
                        padding: EdgeInsets.fromLTRB(
                            wide ? 30 : 14, wide ? 24 : 14, wide ? 30 : 14, 28),
                        child: Align(
                            alignment: Alignment.topCenter,
                            child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 1160),
                                child: TweenAnimationBuilder<double>(
                                    key: ValueKey(page),
                                    tween: Tween(
                                        begin: MediaQuery.disableAnimationsOf(
                                                context)
                                            ? 1.0
                                            : 0.0,
                                        end: 1.0),
                                    duration:
                                        MediaQuery.disableAnimationsOf(context)
                                            ? Duration.zero
                                            : const Duration(milliseconds: 160),
                                    curve: Curves.easeOut,
                                    builder: (_, v, child) =>
                                        Opacity(opacity: v, child: child),
                                    child: content()))))),
              ])),
            ])));
  }

  Widget sidebar() => ColoredBox(
      color: ink,
      child: SafeArea(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        const Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 12, 25),
            child: BeeBrand(light: true)),
        Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 14, 10),
            child: Text(roleLabel,
                style: const TextStyle(
                    color: Color(0xFFD0DED3),
                    fontSize: 13,
                    fontWeight: FontWeight.w600))),
        Expanded(
            child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
              for (final n in nav)
                Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Material(
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(13)),
                        clipBehavior: Clip.antiAlias,
                        color: page == n.$1
                            ? const Color(0xFFE7EEDA)
                            : Colors.transparent,
                        child: ListTile(
                            selected: page == n.$1,
                            selectedColor: ink,
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 12),
                            textColor: Colors.white,
                            iconColor: Colors.white,
                            leading: Icon(n.$3, size: 21),
                            title: Text(n.$2,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600)),
                            onTap: () => go(n.$1)))),
            ])),
        Divider(color: Colors.white.withValues(alpha: .2)),
        Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 12, 12),
            child: Row(children: [
              Expanded(
                  child: Text('${s.profile['name'] ?? 'Tài khoản'}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          color: Colors.white, fontWeight: FontWeight.w600))),
              if (s.live)
                const IconTheme(
                    data: IconThemeData(color: Colors.white),
                    child: LogoutButton()),
            ])),
      ])));

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
        _ => ServiceCatalog(
            records: s.rows('services'),
            onDetails: details,
            onManage: s.admin ? () => go('manage_services') : null),
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
            children:
                children.map((e) => SizedBox(width: w, child: e)).toList(),
          );
        },
      );
  IconData serviceIcon(RecordData r) => r['icon'] == 'laundry'
      ? Icons.local_laundry_service_outlined
      : r['icon'] == 'sparkles'
          ? Icons.auto_awesome_outlined
          : Icons.cottage_outlined;
  Future<void> modal(String title, Widget body, {List<Widget>? actions}) =>
      showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
          title: Text(title),
          content: SizedBox(
            width: 620,
            child: SingleChildScrollView(child: body),
          ),
          actions: actions ??
              [
                TextButton(
                  onPressed: () => Navigator.pop(c),
                  child: const Text('Đóng'),
                ),
              ],
        ),
      );
  void details(RecordData r) {
    final includes = (r['includes'] is List ? r['includes'] as List : const [])
        .where((v) => '$v'.trim().isNotEmpty);
    final excludes = (r['excludes'] is List ? r['excludes'] as List : const [])
        .where((v) => '$v'.trim().isNotEmpty);
    final canBook = s.role == 'customer' &&
        r['active'] == true &&
        r['price'] is num &&
        r['duration'] is num;
    modal(
        '${r['name'] ?? 'Chi tiết dịch vụ'}',
        Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          if ((r['description'] ?? '').toString().isNotEmpty)
            Text('${r['description']}'),
          const SizedBox(height: 14),
          if (r['price'] is num)
            InfoLine(Icons.payments_outlined, 'Đơn giá',
                '${money(r['price'])} / ${r['unit'] ?? ''}'),
          if (r['duration'] != null)
            InfoLine(
                Icons.schedule, 'Thời lượng tối thiểu', '${r['duration']} giờ'),
          for (final group in [
            ('Công việc bao gồm', includes, Icons.check_circle_outline),
            ('Không bao gồm', excludes, Icons.remove_circle_outline)
          ]) ...[
            if (group.$2.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(group.$1,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              for (final item in group.$2)
                Padding(
                    padding: const EdgeInsets.only(top: 7),
                    child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(group.$3, size: 18, color: forest),
                          const SizedBox(width: 9),
                          Expanded(child: Text('$item'))
                        ]))
            ],
          ],
        ]),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Đóng')),
          if (canBook)
            FilledButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  booking(r);
                },
                icon: const Icon(Icons.calendar_month_outlined, size: 18),
                label: const Text('Đặt lịch')),
        ]);
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
          scrollable: true,
          title: const Text('Địa chỉ và thời lượng'),
          content: SizedBox(
            width: 480,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(r['name'], style: Theme.of(c).textTheme.titleLarge),
                const SizedBox(height: 18),
                DropdownButtonFormField<String>(
                  initialValue: aid,
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
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4,
                    children: [
                      const Text('Thời lượng'),
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
                  'Bước tiếp theo, chọn ngày và giờ làm việc.',
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
                final proceed = widget.onBookingRequested;
                if (proceed == null) {
                  startBooking(s, draft);
                } else {
                  proceed(draft);
                }
              },
              child: const Text('Chọn ngày làm'),
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
                            maxLines: e.key == 'description' ||
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
                              if (v.isEmpty && !optional.contains(e.key)) {
                                return 'Vui lòng nhập ${e.value.toLowerCase()}';
                              }
                              if (v.length > 1500) {
                                return 'Nội dung tối đa 1.500 ký tự';
                              }
                              if (numbers.contains(e.key) &&
                                  (num.tryParse(v) == null ||
                                      num.parse(v) <= 0)) {
                                return 'Nhập số lớn hơn 0';
                              }
                              if (e.key == 'phone' &&
                                  !RegExp(r'^0\d{9}$').hasMatch(v)) {
                                return 'Số điện thoại gồm 10 số, bắt đầu bằng 0';
                              }
                              if ((e.key == 'imageUrl' ||
                                      e.key == 'avatarUrl') &&
                                  v.isNotEmpty &&
                                  !v.startsWith('https://')) {
                                return 'Dùng liên kết ảnh HTTPS';
                              }
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
    final list =
        s.rows('addresses').where((a) => a['userId'] == s.uid).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Địa chỉ của tôi',
          'Chọn địa chỉ mặc định để đặt lịch nhanh hơn.',
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
          'Cập nhật thông tin liên hệ và ảnh đại diện.',
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
                  'Tài khoản',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                ),
                const SizedBox(height: 15),
                Text(
                  'Vai trò · $roleLabel',
                ),
                const SizedBox(height: 18),
                if (s.role == 'customer')
                  OutlinedButton.icon(
                    onPressed: () => go('addresses'),
                    icon: const Icon(Icons.location_on_outlined),
                    label: const Text('Quản lý địa chỉ'),
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
                    Tag(w?['approval'] == null || w?['approval'] == 'pending'
                        ? 'Chờ duyệt'
                        : statusLabel(w?['approval'])),
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
              folded('${w['name'] ?? ''}').contains(folded(search)),
        )
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          s.admin ? 'Duyệt người giúp việc' : 'Người giúp việc BeeHome',
          s.admin
              ? 'Kiểm tra hồ sơ trước khi cho phép nhận việc.'
              : 'Xem kỹ năng, khu vực hoạt động và đánh giá từ các đơn đã hoàn thành.',
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
                        Tag(
                            w['approval'] == 'pending'
                                ? 'Chờ duyệt'
                                : statusLabel(w['approval']),
                            color: statusColor(w['approval'])),
                        const SizedBox(height: 12),
                        Text(
                          [
                            if ((w['experience'] ?? '').toString().isNotEmpty)
                              '${w['experience']} kinh nghiệm',
                            if ((w['area'] ?? '').toString().isNotEmpty)
                              '${w['area']}'
                          ].join(' · '),
                          style: const TextStyle(color: muted, fontSize: 13),
                        ),
                        const SizedBox(height: 12),
                        if ((w['skills'] ?? '').toString().isNotEmpty)
                          Text('${w['skills']}'),
                        Text(
                          '${w['bio'] ?? ''}',
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
    final own = s
        .rows('orders')
        .where((o) =>
            s.admin ||
            o[s.role == 'worker' ? 'workerId' : 'customerId'] == s.uid ||
            (s.role == 'worker' && o['status'] == 'pending'))
        .toList();
    final list = own
        .where((o) =>
            (orderFilter == 'Tất cả' || o['status'] == orderFilter) &&
            folded("${o['id']} ${o['serviceName']}")
                .contains(folded(search.trim())))
        .toList();
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      heading(
          s.admin
              ? 'Quản lý đơn hàng'
              : s.role == 'worker'
                  ? 'Công việc của tôi'
                  : 'Đơn dịch vụ của tôi',
          'Xem lịch làm việc và tiến độ của từng đơn.'),
      TextField(
          controller: searchController,
          onChanged: (v) => setState(() => search = v),
          decoration: const InputDecoration(
              hintText: 'Tìm mã đơn, dịch vụ', prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 10),
      SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(children: [
            for (final v in [
              'Tất cả',
              'pending',
              'accepted',
              'working',
              'completed',
              'cancelled'
            ])
              Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: ChoiceChip(
                      showCheckmark: false,
                      selected: v == orderFilter,
                      onSelected: (_) => setState(() => orderFilter = v),
                      label: Text(v == 'Tất cả' ? v : statusLabel(v)))),
          ])),
      const SizedBox(height: 16),
      if (list.isEmpty)
        EmptyView(
            own.isEmpty ? 'Chưa có đơn dịch vụ' : 'Chưa tìm thấy đơn',
            own.isEmpty
                ? 'Lịch làm việc sẽ xuất hiện tại đây khi có đơn.'
                : 'Thử đổi trạng thái hoặc tìm theo mã đơn.',
            icon: Icons.event_note_outlined,
            action: own.isEmpty && s.role == 'customer'
                ? OutlinedButton(
                    onPressed: () => go('services'),
                    child: const Text('Xem dịch vụ'))
                : own.isNotEmpty
                    ? TextButton(
                        onPressed: () => setState(() {
                              searchController.clear();
                              search = '';
                              orderFilter = 'Tất cả';
                            }),
                        child: const Text('Hiện tất cả đơn'))
                    : null),
      for (final o in list)
        Padding(
            key: ValueKey(o['id']),
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
                padding: 18,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Wrap(
                          alignment: WrapAlignment.spaceBetween,
                          spacing: 12,
                          runSpacing: 5,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Text('Đơn ${o['id']}',
                                style: const TextStyle(
                                    color: muted,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12)),
                            Tag(statusLabel(o['status']),
                                color: statusColor(o['status'])),
                          ]),
                      const SizedBox(height: 10),
                      Text('${o['serviceName'] ?? 'Dịch vụ'}',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 10),
                      Wrap(spacing: 18, runSpacing: 6, children: [
                        if (displaySchedule(o).isNotEmpty)
                          Text(displaySchedule(o),
                              style: const TextStyle(color: muted)),
                        if (o['total'] is num)
                          Text(money(o['total']),
                              style:
                                  const TextStyle(fontWeight: FontWeight.w700)),
                      ]),
                      const SizedBox(height: 14),
                      const Divider(),
                      const SizedBox(height: 8),
                      Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            TextButton.icon(
                                onPressed: () => orderDetail(o),
                                icon: const Icon(Icons.article_outlined,
                                    size: 17),
                                label: const Text('Chi tiết')),
                            OrderButtons(store: s, order: o),
                            if (o['customerId'] == s.uid &&
                                o['status'] == 'completed' &&
                                s.find('reviews', o['id']) == null)
                              FilledButton(
                                  onPressed: () => reviewDialog(o),
                                  child: const Text('Đánh giá')),
                          ]),
                    ]))),
    ]);
  }

  void orderDetail(RecordData o) => modal(
      'Chi tiết đơn ${o['id']}',
      Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Text('${o['serviceName'] ?? 'Dịch vụ'}',
            style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Align(
            alignment: Alignment.centerLeft,
            child:
                Tag(statusLabel(o['status']), color: statusColor(o['status']))),
        const SizedBox(height: 12),
        InfoLine(
            Icons.calendar_today_outlined, 'Lịch làm việc', displaySchedule(o)),
        if (o['duration'] != null)
          InfoLine(Icons.timer_outlined, 'Thời lượng', '${o['duration']} giờ'),
        InfoLine(Icons.person_outline, 'Người giúp việc',
            '${o['workerName'] ?? 'Chưa có người nhận'}'),
        if (o['addressSnapshot'] != null)
          InfoLine(Icons.location_on_outlined, 'Địa chỉ lúc đặt',
              '${o['addressSnapshot']}'),
        const Divider(),
        if (o['total'] is num)
          InfoLine(Icons.payments_outlined, 'Giá đã chốt', money(o['total'])),
        InfoLine(Icons.receipt_outlined, 'Thanh toán',
            statusLabel(o['paymentStatus'])),
      ]));

  String displaySchedule(RecordData order) {
    final raw = '${order['date'] ?? ''}';
    final date = DateTime.tryParse(raw);
    final label = date == null
        ? raw
        : '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
    final time = '${order['time'] ?? ''}'.trim();
    return [label, time].where((s) => s.isNotEmpty).join(' · ');
  }

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
    ).then(
      (_) => Future.delayed(const Duration(milliseconds: 400), text.dispose),
    );
  }

  Widget notifications() {
    final list = s
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
          'Cập nhật về đơn dịch vụ và tài khoản của bạn.',
          action: TextButton.icon(
            onPressed: s
                    .rows('notifications')
                    .any((n) => n['userId'] == s.uid && n['read'] != true)
                ? () =>
                    task(() => s.markRead(), success: 'Đã đọc tất cả thông báo')
                : null,
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
                    backgroundColor:
                        n['read'] == true ? cream : const Color(0xFFFFE9A3),
                    child: const Icon(Icons.notifications_none, color: ink),
                  ),
                  title: Text(
                    n['title'],
                    style: TextStyle(
                      fontWeight:
                          n['read'] == true ? FontWeight.w400 : FontWeight.w700,
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
    if (!s.admin) {
      return const EmptyView(
        'Không có quyền',
        'Trang này dành cho quản trị viên.',
      );
    }
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
          'Tổng quan vận hành',
          'Đơn dịch vụ, khách hàng và hồ sơ cần duyệt.',
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
    if (!s.admin) {
      return const EmptyView(
        'Không có quyền',
        'Chỉ quản trị viên được quản lý dịch vụ.',
      );
    }
    final list = s.rows('services');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        heading(
          'Quản lý dịch vụ',
          'Cập nhật giá, phạm vi công việc và trạng thái nhận lịch.',
          action: FilledButton.icon(
            onPressed: () => editService(),
            icon: const Icon(Icons.add),
            label: const Text('Thêm dịch vụ'),
          ),
        ),
        if (list.isEmpty)
          const EmptyView('Danh mục đang trống',
              'Chọn Thêm dịch vụ để nhập thông tin và đơn giá.',
              icon: Icons.grid_view_outlined),
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
        if (!['giờ', 'gói'].contains(v['unit'])) {
          throw StateError('Đơn vị chỉ nhận giờ hoặc gói.');
        }
        if (!['Dọn dẹp', 'Giặt ủi'].contains(v['category'])) {
          throw StateError('Chọn loại Dọn dẹp hoặc Giặt ủi.');
        }
        final h = int.tryParse(v['duration']!);
        if (h == null || h < 1 || h > 8) {
          throw StateError('Thời lượng phải là số nguyên từ 1 đến 8.');
        }
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
    if (!s.admin) {
      return const EmptyView(
        'Không có quyền',
        'Trang này dành cho quản trị viên.',
      );
    }
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
        if (list.isEmpty)
          const EmptyView('Chưa tìm thấy người dùng',
              'Tài khoản phù hợp với từ khóa sẽ xuất hiện tại đây.',
              icon: Icons.people_outline),
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
                  Tag(statusLabel(u['status']),
                      color: statusColor(u['status'])),
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
                                  u['status'] == 'blocked'
                                      ? 'active'
                                      : 'blocked',
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
