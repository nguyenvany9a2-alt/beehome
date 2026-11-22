import 'package:cloud_firestore/cloud_firestore.dart';

import 'bee_store.dart';

const orderMessages = {
  'pending': 'Đơn đang chờ nhận',
  'accepted': 'Đã có người nhận việc',
  'working': 'Công việc đã bắt đầu',
  'completed': 'Công việc đã hoàn thành',
  'cancelled': 'Đơn đã bị hủy',
};

RecordData _offer(RecordData o) => {
      for (final k in [
        'customerId',
        'serviceName',
        'date',
        'time',
        'duration',
        'total'
      ])
        k: o[k],
      'status': 'pending',
      'scheduledAt': o['scheduledAt'] ?? Timestamp.fromDate(_legacyTime(o)),
      if (o['area'] != null) 'area': o['area'],
    };

DateTime _legacyTime(RecordData order) {
  final stamp = DateTime.tryParse("${order['date']}T${order['time']}:00+07:00");
  if (stamp == null) {
    throw StateError('Đơn cũ đang thiếu ngày hoặc giờ làm hợp lệ.');
  }
  return stamp.toUtc();
}

bool _overlaps(DateTime a, DateTime b, DateTime c, DateTime d) =>
    a.isBefore(d) && c.isBefore(b);

void _notify(
    Transaction tx, String id, String status, Iterable<String?> recipients) {
  final db = FirebaseFirestore.instance;
  for (final uid in recipients.whereType<String>().toSet()) {
    tx.set(db.doc('notifications/${id}_${status}_$uid'), {
      'userId': uid,
      'orderId': id,
      'status': status,
      'title': orderMessages[status],
      'body': 'Đơn $id có cập nhật mới.',
      'read': false,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    });
  }
}

extension OrderActions on BeeStore {
  Future<String> createOrder(
      {required String serviceId,
      required String addressId,
      required int duration,
      required DateTime when,
      num? confirmedTotal,
      String? confirmedAddress}) async {
    if (role != 'customer') {
      throw StateError('Chỉ khách hàng được đặt dịch vụ.');
    }
    final instant =
        DateTime.utc(when.year, when.month, when.day, when.hour, when.minute)
            .subtract(const Duration(hours: 7));
    if (!instant.isAfter(DateTime.now()) || when.hour < 7 || when.hour > 19) {
      throw StateError(
          'Hãy chọn giờ bắt đầu từ 07:00 đến 19:59 trong tương lai.');
    }
    RecordData draft(RecordData? service, RecordData? address) {
      if (service == null ||
          service['active'] != true ||
          service['price'] is! num) {
        throw StateError('Dịch vụ đã ngừng nhận lịch.');
      }
      if (address == null || address['userId'] != uid) {
        throw StateError('Địa chỉ không hợp lệ.');
      }
      final byHour = service['unit'] == 'giờ';
      final hours = byHour ? duration : (service['duration'] as num).toInt();
      if (hours < 1 || hours > 8) {
        throw StateError('Thời lượng hợp lệ từ 1 đến 8 giờ.');
      }
      final total = (service['price'] as num) * (byHour ? hours : 1);
      final location = "${address['detail']}, ${address['area']}";
      if ((confirmedTotal != null && confirmedTotal != total) ||
          (confirmedAddress != null && confirmedAddress != location)) {
        throw StateError(
            'Giá hoặc địa chỉ vừa thay đổi. Hãy xem lại trước khi đặt.');
      }
      String two(int value) => value.toString().padLeft(2, '0');
      return {
        'serviceId': serviceId,
        'serviceName': service['name'],
        'customerId': uid,
        'customerName': profile['name'],
        'workerId': null,
        'workerName': null,
        'addressId': addressId,
        'addressSnapshot': location,
        'area': address['area'],
        'contactName': address['contact'] ?? '',
        'contactPhone': address['phone'] ?? '',
        'entryNote': address['note'] ?? '',
        'date': '${when.year}-${two(when.month)}-${two(when.day)}',
        'time': '${two(when.hour)}:${two(when.minute)}',
        'duration': hours,
        'total': total,
        'scheduledAt':
            live ? Timestamp.fromDate(instant) : instant.toIso8601String(),
        'status': 'pending',
        'paymentMethod': 'cod',
        'paymentStatus': 'unpaid',
        'createdAt': DateTime.now().toUtc().toIso8601String(),
        'inAppVersion': 1
      };
    }

    if (!live) {
      final id = 'BH${DateTime.now().microsecondsSinceEpoch}';
      await save('orders', {
        'id': id,
        ...draft(find('services', serviceId), find('addresses', addressId))
      });
      return id;
    }
    final db = FirebaseFirestore.instance;
    final id = db.collection('orders').doc().id;
    await db.runTransaction((tx) async {
      final service = (await tx.get(db.doc('services/$serviceId'))).data();
      final address = (await tx.get(db.doc('addresses/$addressId'))).data();
      final order = draft(service, address);
      tx.set(db.doc('orders/$id'), order);
      tx.set(db.doc('job_offers/$id'), _offer(order));
      _notify(tx, id, 'pending', [uid]);
    });
    return id;
  }

  // Publishes a minimal offer for an existing pending order from older versions.
  Future<void> publishOffer(String id) async {
    if (!admin || !live) {
      throw StateError('Chỉ quản trị viên được mở lại việc.');
    }
    final db = FirebaseFirestore.instance;
    await db.runTransaction((tx) async {
      final order = (await tx.get(db.doc('orders/$id'))).data();
      if (order == null ||
          order['status'] != 'pending' ||
          order['workerId'] != null) {
        throw StateError('Đơn đã thay đổi trạng thái.');
      }
      final ref = db.doc('job_offers/$id');
      if (!(await tx.get(ref)).exists) tx.set(ref, _offer(order));
    });
  }

  Future<void> cancelOrder(String id) => _transition(id, 'cancelled');
  Future<void> acceptOrder(String id) => _transition(id, 'accepted');
  Future<void> startOrder(String id) => _transition(id, 'working');
  Future<void> completeOrder(String id) => _transition(id, 'completed');

  Future<void> _transition(String id, String next) async {
    final accepting = next == 'accepted';
    void check(RecordData? o) {
      if (o == null) {
        throw StateError('Công việc đã thay đổi hoặc đã có người nhận.');
      }
      final eligible = switch (next) {
        'cancelled' => role == 'customer' &&
            o['customerId'] == uid &&
            o['status'] == 'pending',
        'accepted' => role == 'worker' &&
            find('worker_profiles', uid)?['approval'] == 'approved' &&
            o['status'] == 'pending' &&
            o['workerId'] == null,
        'working' =>
          role == 'worker' && o['workerId'] == uid && o['status'] == 'accepted',
        'completed' =>
          role == 'worker' && o['workerId'] == uid && o['status'] == 'working',
        _ => false,
      };
      if (!eligible) {
        throw StateError('Trạng thái đơn hoặc quyền tài khoản đã thay đổi.');
      }
    }

    final update = {
      'status': next,
      'updatedAt': DateTime.now().toUtc().toIso8601String(),
      'inAppVersion': 1,
      if (accepting) ...{'workerId': uid, 'workerName': profile['name']},
      if (next == 'completed') 'paymentStatus': 'paid'
    };
    if (!live) {
      check(find('orders', id));
      await save('orders', {'id': id, ...update});
      return;
    }
    final db = FirebaseFirestore.instance;
    final ref = db.doc('orders/$id'), offer = db.doc('job_offers/$id');
    await db.runTransaction((tx) async {
      final original = (await tx.get(accepting ? offer : ref)).data();
      check(original);
      if (accepting || next == 'completed') {
        final ledger = db.doc('work_calendars/$uid');
        final slots = List<RecordData>.from(
            (await tx.get(ledger)).data()?['jobs'] as List? ?? []);
        if (accepting) {
          final start = original!['scheduledAt'] as Timestamp;
          final end = Timestamp.fromDate(
              start.toDate().add(Duration(hours: original['duration'] as int)));
          if (start.toDate().isBefore(DateTime.now())) {
            throw StateError('Giờ bắt đầu đã qua.');
          }
          for (final old in slots) {
            if (_overlaps(
                start.toDate(),
                end.toDate(),
                (old['start'] as Timestamp).toDate(),
                (old['end'] as Timestamp).toDate())) {
              throw StateError('Bạn đã có công việc trong khung giờ này.');
            }
          }
          // Legacy assignments predate the shared worker calendar.
          for (final old in rows('orders').where((o) =>
              o['workerId'] == uid &&
              ['accepted', 'working'].contains(o['status']) &&
              o['scheduledAt'] == null)) {
            final from = _legacyTime(old);
            if (_overlaps(start.toDate(), end.toDate(), from,
                from.add(Duration(hours: (old['duration'] as num).toInt())))) {
              throw StateError('Lịch này trùng với đơn đang làm của bạn.');
            }
          }
          final pos = slots
              .where((v) => (v['start'] as Timestamp).compareTo(start) < 0)
              .length;
          slots.insert(pos, {'id': id, 'start': start, 'end': end});
          tx.set(ledger, {'jobs': slots, 'orderId': id, 'position': pos});
        } else {
          final pos = slots.indexWhere((v) => v['id'] == id);
          if (pos >= 0) {
            slots.removeAt(pos);
            tx.set(ledger, {'jobs': slots, 'orderId': id, 'position': pos});
          }
        }
      }
      if (next == 'completed') {
        tx.set(db.doc('payments/$id'), {
          'orderId': id,
          'customerId': original!['customerId'],
          'workerId': uid,
          'method': 'cod',
          'status': 'paid',
          'amount': original['total'],
          'paidAt': FieldValue.serverTimestamp()
        });
      }
      tx.update(ref, update);
      if (accepting || next == 'cancelled') tx.delete(offer);
      _notify(tx, id, next, [
        original!['customerId'] as String,
        if (accepting) uid else original['workerId'] as String?
      ]);
    });
  }
}
