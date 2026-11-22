import 'package:cloud_firestore/cloud_firestore.dart';

import 'bee_store.dart';

/// The small, private index serializes concurrent edits, including the first
/// address. Existing address books are picked up on the first successful edit.
Future<void> writeAddress(String uid, RecordData input,
    {bool remove = false}) async {
  final db = FirebaseFirestore.instance;
  final addresses = db.collection('addresses');
  final own = await addresses.where('userId', isEqualTo: uid).get();
  final index = db.doc('users/$uid/settings/addressBook');
  final id = input['id'] as String? ?? addresses.doc().id;
  await db.runTransaction((tx) async {
    final meta = (await tx.get(index)).data();
    final ids = meta == null
        ? own.docs.map((d) => d.id).toList()
        : List<String>.from(meta['ids'] as List);
    final previous = meta?['defaultId'] as String? ??
        own.docs.where((d) => d.data()['default'] == true).firstOrNull?.id;
    if ((remove || input['id'] != null) && !ids.contains(id)) {
      throw StateError('Địa chỉ đã bị xóa. Hãy chọn lại.');
    }
    if (remove) {
      ids.remove(id);
    } else if (!ids.contains(id)) {
      if (ids.length >= 20) {
        throw StateError('Bạn có thể lưu tối đa 20 địa chỉ.');
      }
      ids.add(id);
    }
    final next = !remove && input['default'] == true
        ? id
        : ids.contains(previous)
            ? previous
            : ids.firstOrNull;
    if (meta == null) {
      // Normalize duplicate legacy default flags if present.
      for (final doc in own.docs.where(
          (d) => d.id != id && d.id != next && d.data()['default'] == true)) {
        tx.update(doc.reference, {'default': false});
      }
    } else if (previous != null &&
        previous != id &&
        previous != next &&
        ids.contains(previous)) {
      tx.update(addresses.doc(previous), {'default': false});
    }
    if (remove) {
      tx.delete(addresses.doc(id));
    } else {
      tx.set(addresses.doc(id), {
        for (final key in [
          'label',
          'contact',
          'phone',
          'detail',
          'area',
          'note'
        ])
          key: (input[key] ?? '').toString().trim(),
        'userId': uid,
        'default': next == id,
      });
    }
    if (next != null && next != id && next != previous) {
      tx.update(addresses.doc(next), {'default': true});
    }
    tx.set(index, {'ids': ids, 'defaultId': next});
  });
}

Future<void> writeReview(String uid, RecordData order, int stars, String text) {
  final db = FirebaseFirestore.instance;
  final oid = order['id'] as String, wid = order['workerId'] as String;
  final batch = db.batch();
  batch.set(db.doc('reviews/$oid'), {
    'orderId': oid,
    'workerId': wid,
    'customerId': uid,
    'stars': stars,
    'comment': text.trim(),
    'createdAt': DateTime.now().toUtc().toIso8601String(),
  });
  batch.set(
      db.doc('rating_totals/$wid'),
      {
        'lastOrder': oid,
        'count': FieldValue.increment(1),
        'sum': FieldValue.increment(stars),
      },
      SetOptions(merge: true));
  return batch.commit();
}

String beeError(Object error) {
  if (error is StateError) return error.message.toString();
  if (error is FirebaseException) {
    return switch (error.code) {
      'permission-denied' =>
        'Bạn chưa có quyền thực hiện thao tác này. Nếu quyền vừa thay đổi, hãy đăng nhập lại.',
      'unavailable' ||
      'deadline-exceeded' =>
        'Kết nối đang gián đoạn. Hãy kiểm tra mạng rồi thử lại.',
      'not-found' => 'Mục này đã bị xóa hoặc chưa được tạo.',
      'already-exists' ||
      'aborted' =>
        'Dữ liệu vừa thay đổi. Hãy kiểm tra lại rồi thử tiếp.',
      _ => 'Chưa thể hoàn tất thao tác (${error.code}).',
    };
  }
  return error.toString();
}
