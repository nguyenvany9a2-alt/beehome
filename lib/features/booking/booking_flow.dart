import 'package:flutter/material.dart';

import '../../data/bee_store.dart';
import '../../data/order_actions.dart';

/// "Chìa khóa" để mở hộp thoại từ bên ngoài BeeShell.
final bookingNavigatorKey = GlobalKey<NavigatorState>();

/// Nhận gói {serviceId, addressId, duration} từ màn của Ý,
/// cho khách chọn ngày giờ, xác nhận rồi tạo đơn.
Future<void> startBooking(BeeStore store, Map<String, dynamic> draft) async {
  final context = bookingNavigatorKey.currentContext;
  if (context == null) return;

  // 1. Chọn ngày (từ hôm nay đến 30 ngày tới)
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day = await showDatePicker(
    context: context,
    initialDate: today.add(const Duration(days: 1)),
    firstDate: today,
    lastDate: today.add(const Duration(days: 30)),
    helpText: 'Chọn ngày làm',
  );
  if (day == null || !context.mounted) return;

  // 2. Chọn giờ bắt đầu
  final time = await showTimePicker(
    context: context,
    initialTime: const TimeOfDay(hour: 8, minute: 0),
    helpText: 'Chọn giờ bắt đầu (7:00 - 19:00)',
  );
  if (time == null || !context.mounted) return;
  if (time.hour < 7 || time.hour > 19) {
    _toast(context, 'Vui lòng chọn giờ bắt đầu từ 7:00 đến 19:00.');
    return;
  }
  final when = DateTime(day.year, day.month, day.day, time.hour, time.minute);

  // 3. Hiện bảng xác nhận
  final service = store.find('services', draft['serviceId'])!;
  final address = store.find('addresses', draft['addressId'])!;
  final byHour = service['unit'] == 'giờ';
  final hours = draft['duration'] as int;
  final total = (service['price'] as num) * (byHour ? hours : 1);

  final ok = await showDialog<bool>(
    context: context,
    builder: (c) => AlertDialog(
      title: const Text('Xác nhận đặt dịch vụ'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Dịch vụ: ${service['name']}'),
          Text('Ngày: ${day.day}/${day.month}/${day.year}'),
          Text('Giờ bắt đầu: ${time.format(c)}'),
          if (byHour) Text('Thời lượng: $hours giờ'),
          Text('Địa chỉ: ${address['detail']}'),
          const SizedBox(height: 12),
          Text(
            'Tổng tiền: ${total.toInt()}đ',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const Text('Thanh toán: Tiền mặt khi hoàn thành (COD)'),
        ],
      ),
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
  if (ok != true || !context.mounted) return;

  // 4. Tạo đơn
  try {
    final id = await store.createOrder(
      serviceId: draft['serviceId'],
      addressId: draft['addressId'],
      duration: hours,
      when: when,
    );
    if (context.mounted) {
      _toast(context, 'Đặt thành công đơn $id. Xem ở mục "Đơn của tôi".');
    }
  } catch (e) {
    if (context.mounted) {
      _toast(context, e.toString().replaceFirst('Bad state: ', ''));
    }
  }
}

void _toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
  );
}