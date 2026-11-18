import 'package:cloud_firestore/cloud_firestore.dart';

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

  /// Khách hủy đơn: chỉ khi chưa có người nhận.
  Future<void> cancelOrder(String id) => _changeOrder(id, (o) {
    if (o['customerId'] != uid) {
      throw StateError('Bạn chỉ hủy được đơn của mình.');
    }
    if (o['status'] != 'pending') {
      throw StateError('Chỉ hủy được đơn chưa có người nhận.');
    }
  }, {'status': 'cancelled'});

  /// Người giúp việc nhận đơn: không cho 2 người nhận trùng.
  Future<void> acceptOrder(String id) => _changeOrder(id, (o) {
    if (role != 'worker') {
      throw StateError('Chỉ người giúp việc được nhận đơn.');
    }
    if (find('worker_profiles', uid)?['approval'] != 'approved') {
      throw StateError('Hồ sơ của bạn chưa được duyệt nên chưa thể nhận đơn.');
    }
    if (o['status'] != 'pending' || o['workerId'] != null) {
      throw StateError('Đơn này đã có người nhận.');
    }
  }, {'workerId': uid, 'workerName': profile['name'], 'status': 'accepted'});

  /// Người giúp việc bắt đầu làm.
  Future<void> startOrder(String id) => _changeOrder(id, (o) {
    if (o['workerId'] != uid || o['status'] != 'accepted') {
      throw StateError('Chỉ bắt đầu được đơn bạn đã nhận.');
    }
  }, {'status': 'working'});

  /// Người giúp việc hoàn thành, đồng thời ghi nhận đã thu tiền mặt (COD).
  Future<void> completeOrder(String id) => _changeOrder(id, (o) {
    if (o['workerId'] != uid || o['status'] != 'working') {
      throw StateError('Chỉ hoàn thành được đơn đang làm.');
    }
  }, {'status': 'completed', 'paymentStatus': 'paid'});

  /// Hàm phụ: đọc đơn, kiểm tra điều kiện, rồi cập nhật.
  /// Firebase thật thì dùng transaction để chống bấm trùng.
  Future<void> _changeOrder(
    String id,
    void Function(RecordData order) check,
    RecordData changes,
  ) async {
    final update = {...changes, 'updatedAt': DateTime.now().toIso8601String()};
    if (live) {
      final db = FirebaseFirestore.instance;
      final ref = db.collection('orders').doc(id);
      await db.runTransaction((tx) async {
        final snap = await tx.get(ref);
        if (!snap.exists) throw StateError('Không tìm thấy đơn.');
        check({...snap.data()!, 'id': snap.id});
        tx.update(ref, update);
      });
      await reload();
    } else {
      final order = find('orders', id);
      if (order == null) throw StateError('Không tìm thấy đơn.');
      check(order);
      await save('orders', {'id': id, ...update});
    }
  }
}

String _two(int n) => n.toString().padLeft(2, '0');
String _date(DateTime d) => '${d.year}-${_two(d.month)}-${_two(d.day)}';