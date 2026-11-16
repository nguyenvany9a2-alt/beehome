import 'bee_store.dart';

/// Các hàm xử lý đơn hàng (phần của Hào).
/// Gắn thêm vào BeeStore bằng extension, không sửa file của Ý.
extension OrderActions on BeeStore {
  /// Tạo đơn mới, trả về mã đơn.
  Future<String> createOrder({
    required String serviceId,
    required String addressId,
    required int duration,
    required DateTime when,
  }) async {
    // 1. Kiểm tra quyền
    if (role != 'customer') {
      throw StateError('Chỉ khách hàng được đặt dịch vụ.');
    }

    // 2. Kiểm tra dịch vụ và địa chỉ còn hợp lệ
    final service = find('services', serviceId);
    if (service == null || service['active'] != true) {
      throw StateError('Dịch vụ này hiện không còn được cung cấp.');
    }
    final address = find('addresses', addressId);
    if (address == null || address['userId'] != uid) {
      throw StateError('Địa chỉ không hợp lệ.');
    }

    // 3. Kiểm tra thời gian
    if (when.isBefore(DateTime.now())) {
      throw StateError('Thời gian làm việc phải ở tương lai.');
    }

    // 4. Tính giá: dịch vụ theo giờ thì nhân số giờ, theo gói thì giữ nguyên
    final price = service['price'] as num;
    final byHour = service['unit'] == 'giờ';
    final hours = byHour ? duration : (service['duration'] as num).toInt();
    final total = byHour ? price * hours : price;

    // 5. Tạo mã đơn và lưu
    final id = 'BH${DateTime.now().millisecondsSinceEpoch % 1000000}';
    await save('orders', {
      'id': id,
      'serviceId': serviceId,
      'serviceName': service['name'],
      'customerId': uid,
      'customerName': profile['name'],
      'workerId': null,
      'workerName': null,
      'addressId': addressId,
      'addressSnapshot': '${address['detail']}, ${address['area']}',
      'date': _date(when),
      'time': '${_two(when.hour)}:${_two(when.minute)}',
      'duration': hours,
      'total': total,
      'status': 'pending',
      'paymentMethod': 'cod',
      'paymentStatus': 'unpaid',
      'createdAt': DateTime.now().toIso8601String(),
    });
    return id;
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';