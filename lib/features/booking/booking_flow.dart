import 'package:flutter/material.dart';

import '../../data/bee_store.dart';
import '../../core/theme.dart';
import '../../widgets/common.dart';
import '../../data/order_actions.dart';
import '../../data/safe_writes.dart';

/// "Chìa khóa" để mở hộp thoại từ bên ngoài BeeShell.
final bookingNavigatorKey = GlobalKey<NavigatorState>();

/// Nhận gói {serviceId, addressId, duration} từ màn của Ý,
/// cho khách chọn ngày giờ, xác nhận rồi tạo đơn.
Future<void> startBooking(BeeStore store, Map<String, dynamic> draft) async {
  final context = bookingNavigatorKey.currentState?.overlay?.context;
  if (context == null) return;

  // 1. Chọn ngày (từ hôm nay đến 30 ngày tới)
  final now = DateTime.now().toUtc().add(const Duration(hours: 7));
  final today = DateTime(now.year, now.month, now.day);
  final day = await showDatePicker(
    context: context,
    initialDate: today.add(const Duration(days: 1)),
    firstDate: today,
    lastDate: today.add(const Duration(days: 30)),
    helpText: 'Chọn ngày làm',
  );
  if (day == null || !context.mounted || !store.sessionActive) return;

  // 2. Chọn giờ bắt đầu
  final time = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 8, minute: 0),
    helpText: 'Giờ Việt Nam (07:00 – 19:59)',
  );
  if (time == null || !context.mounted || !store.sessionActive) return;
  if (time.hour < 7 || time.hour > 19) {
    _toast(context, 'Vui lòng chọn giờ bắt đầu từ 07:00 đến 19:59.');
    return;
  }
  final when = DateTime(day.year, day.month, day.day, time.hour, time.minute);

  // 3. Hiện bảng xác nhận
  final service = store.find('services', draft['serviceId']);
  final address = store.find('addresses', draft['addressId']);
  if (service == null ||
      address == null ||
      service['active'] != true ||
      service['price'] is! num) {
    _toast(context, 'Dịch vụ hoặc địa chỉ đã thay đổi. Vui lòng chọn lại.');
    return;
  }
  final byHour = service['unit'] == 'giờ';
  final hours = draft['duration'] as int;
  final total = (service['price'] as num) * (byHour ? hours : 1);

  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      scrollable: true,
      title: const Text('Xác nhận lịch đặt'),
      content: SizedBox(
          width: 380,
          child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('${service['name']}',
                    style: Theme.of(c).textTheme.titleLarge),
                const SizedBox(height: 10),
                InfoLine(Icons.calendar_month_outlined, 'Ngày và giờ làm',
                    '${day.day}/${day.month}/${day.year} · ${time.format(c)}'),
                if (byHour)
                  InfoLine(Icons.schedule, 'Thời lượng', '$hours giờ'),
                InfoLine(
                    Icons.location_on_outlined,
                    'Địa chỉ',
                    [address['detail'], address['area']]
                        .whereType<String>()
                        .where((s) => s.trim().isNotEmpty)
                        .join(', ')),
                const Divider(),
                InfoLine(
                    Icons.payments_outlined, 'Tổng thanh toán', money(total)),
                const Text('Thanh toán tiền mặt khi hoàn thành.',
                    style: TextStyle(color: muted, fontSize: 13)),
              ])),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(c, false),
          child: const Text('Hủy'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(c, true),
          child: const Text('Đặt dịch vụ'),
        ),
      ],
    ),
  );
  if (ok != true || !context.mounted || !store.sessionActive) return;

  // 4. Tạo đơn
  try {
    final id = await store.createOrder(
      serviceId: draft['serviceId'],
      addressId: draft['addressId'],
      duration: hours,
      when: when,
      confirmedTotal: total,
      confirmedAddress: "${address['detail']}, ${address['area']}",
    );
    if (context.mounted) {
      _toast(context, 'Đặt thành công đơn $id. Xem ở mục "Đơn của tôi".');
    }
  } catch (e) {
    if (context.mounted) {
      _toast(context, beeError(e));
    }
  }
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}
