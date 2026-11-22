import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../data/bee_store.dart';
import '../../core/theme.dart';
import '../../widgets/bee_header.dart';
import 'home_page.dart';

class GuestHome extends StatefulWidget {
  const GuestHome({super.key, required this.login, this.catalog});
  final VoidCallback login;
  final Stream<List<RecordData>>? catalog;
  @override
  State<GuestHome> createState() => _GuestHomeState();
}

class _GuestHomeState extends State<GuestHome> {
  final scroll = ScrollController();
  Stream<List<RecordData>> query() =>
      widget.catalog ??
      FirebaseFirestore.instance
          .collection('services')
          .where('active', isEqualTo: true)
          .snapshots()
          .map((snap) => [
                for (final d in snap.docs) {...d.data(), 'id': d.id}
              ]);
  late var stream = query();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void details(RecordData item) {
    showDialog<void>(
        context: context,
        builder: (c) => AlertDialog(
                scrollable: true,
                title: Text('${item['name']}'),
                content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item['price'] is num
                          ? '${money(item['price'])} / ${item['unit']}'
                          : 'Liên hệ BeeHome'),
                      const SizedBox(height: 12),
                      Text('${item['description'] ?? ''}'),
                      for (final line in (item['includes'] as List? ?? []))
                        Padding(
                            padding: const EdgeInsets.only(top: 7),
                            child: Text('• $line')),
                    ]),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Đóng')),
                  FilledButton(
                      onPressed: () {
                        Navigator.pop(c);
                        widget.login();
                      },
                      child: const Text('Đăng nhập để đặt lịch'))
                ]));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
          body: Column(children: [
        BeeHeader(
            signedIn: false,
            home: () {
              if (scroll.hasClients) scroll.jumpTo(0);
            },
            account: widget.login,
            alerts: widget.login),
        Expanded(
            child: SingleChildScrollView(
                controller: scroll,
                padding: const EdgeInsets.all(16),
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1200),
                        child: StreamBuilder<List<RecordData>>(
                            stream: stream,
                            builder: (ctx, snap) => HomePage(
                                services: snap.data ?? const [],
                                onService: details,
                                onAction: widget.login,
                                actionLabel: 'Đăng nhập',
                                loading: !snap.hasData && !snap.hasError,
                                error: snap.hasError
                                    ? 'Kiểm tra kết nối để xem dịch vụ đang nhận lịch.'
                                    : null,
                                retry: () {
                                  setState(() => stream = query());
                                })))))),
      ]));
}
