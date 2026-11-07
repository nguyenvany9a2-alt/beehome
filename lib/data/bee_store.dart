import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import 'seed.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

typedef RecordData = Map<String, dynamic>;

class BeeStore extends ChangeNotifier {
  BeeStore({this.live = false});
  final bool live;
  final subscriptions = <String, StreamSubscription>{};
  String? syncError;
  String uid = 'demo-y', role = 'customer';
  Map<String, dynamic> data = {};
  List<RecordData> rows(String name) => ((data[name] ?? []) as List)
      .map((e) => Map<String, dynamic>.from(e as Map))
      .toList();
  RecordData? find(String collection, String id) {
    for (final r in rows(collection)) {
      if (r['id'] == id) return r;
    }
    return null;
  }

  bool get admin => role == 'admin';
  RecordData get profile =>
      find('users', uid) ??
      {
        'id': uid,
        'name': 'Thành viên BeeHome',
        'phone': '',
        'email': '',
        'avatarUrl': '',
      };
  Future<void> init() async {
    if (!live) {
      final p = await SharedPreferences.getInstance();
      final cached = p.getString('beehome.demo.v1');
      try {
        data = cached == null
            ? seedData()
            : Map<String, dynamic>.from(jsonDecode(cached));
      } catch (_) {
        data = seedData();
      }
    } else {
      final user = await FirebaseAuth.instance.authStateChanges().first;
      if (user == null)
        throw StateError(
          'Chưa đăng nhập. Tích hợp màn hình xác thực của Hào trước khi dùng dữ liệu thật.',
        );
      uid = user.uid;
      final token = await user.getIdTokenResult(true);
      role = token.claims?['role']?.toString() ?? 'customer';
      await reload();
    }
    notifyListeners();
  }

  Future<void> reload() async {
    if (!live) return;
    final db = FirebaseFirestore.instance;
    for (final c in [
      'services',
      'users',
      'worker_profiles',
      'addresses',
      'orders',
      'reviews',
      'notifications',
    ]) {
      Query<Map<String, dynamic>> q = db.collection(c);
      if (!admin) {
        if (c == 'services') q = q.where('active', isEqualTo: true);
        if (c == 'users') q = q.where(FieldPath.documentId, isEqualTo: uid);
        if (c == 'worker_profiles')
          q = role == 'worker'
              ? q.where(FieldPath.documentId, isEqualTo: uid)
              : q.where('approval', isEqualTo: 'approved');
        if (c == 'addresses' || c == 'notifications')
          q = q.where('userId', isEqualTo: uid);
        if (c == 'orders')
          q = q.where(
            role == 'worker' ? 'workerId' : 'customerId',
            isEqualTo: uid,
          );
        if (c == 'reviews')
          q = q.where(
            role == 'worker' ? 'workerId' : 'customerId',
            isEqualTo: uid,
          );
      }
      if (!subscriptions.containsKey(c)) {
        subscriptions[c] = q.snapshots().listen(
          (snapshot) {
            data[c] = snapshot.docs
                .map((e) => {...e.data(), 'id': e.id})
                .toList();
            syncError = null;
            notifyListeners();
          },
          onError: (Object e) {
            syncError = 'Không đồng bộ được $c: $e';
            notifyListeners();
          },
        );
      }
      final s = await q.get();
      data[c] = s.docs.map((e) => {...e.data(), 'id': e.id}).toList();
    }
    notifyListeners();
  }

  @override
  void dispose() {
    for (final sub in subscriptions.values) {
      sub.cancel();
    }
    super.dispose();
  }

  Future<void> persist() async {
    if (!live) {
      final p = await SharedPreferences.getInstance();
      await p.setString('beehome.demo.v1', jsonEncode(data));
    }
    notifyListeners();
  }

  Future<void> save(String collection, RecordData row) async {
    final id =
        row['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    row = {...row, 'id': id};
    if (collection == 'services' && !admin)
      throw StateError('Chỉ quản trị viên được quản lý dịch vụ.');
    if (live) {
      final copy = {...row}..remove('id');
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .set(copy, SetOptions(merge: true));
      await reload();
    } else {
      final list = rows(collection);
      final i = list.indexWhere((e) => e['id'] == id);
      if (i < 0) {
        list.add(row);
      } else {
        list[i] = {...list[i], ...row};
      }
      data[collection] = list;
      await persist();
    }
  }

  Future<void> saveAddress(RecordData row) async {
    row = {...row, 'userId': uid};
    if (live) {
      await FirebaseFunctions.instance.httpsCallable('saveAddress').call(row);
      await reload();
      return;
    }
    final all = rows('addresses');
    if (all.where((a) => a['userId'] == uid).isEmpty) row['default'] = true;
    if (row['default'] == true) {
      data['addresses'] = all
          .map((a) => a['userId'] == uid ? {...a, 'default': false} : a)
          .toList();
    }
    await save('addresses', row);
  }

  Future<void> deleteAddress(String id) async {
    if (live) {
      await FirebaseFunctions.instance.httpsCallable('deleteAddress').call({
        'id': id,
      });
      await reload();
      return;
    }
    final old = find('addresses', id);
    if (old?['userId'] != uid) throw StateError('Không có quyền.');
    final all = rows('addresses')..removeWhere((a) => a['id'] == id);
    final own = all.where((a) => a['userId'] == uid).toList();
    if (old?['default'] == true && own.isNotEmpty) own.first['default'] = true;
    data['addresses'] = all;
    await persist();
  }

  Future<void> review(String orderId, int stars, String comment) async {
    final order = find('orders', orderId);
    if (order == null ||
        order['customerId'] != uid ||
        order['status'] != 'completed')
      throw StateError('Chỉ đánh giá đơn của bạn đã hoàn thành.');
    if (stars < 1 || stars > 5)
      throw StateError('Vui lòng chọn từ 1 đến 5 sao.');
    if (find('reviews', orderId) != null)
      throw StateError('Đơn này đã được đánh giá.');
    if (live) {
      await FirebaseFunctions.instance.httpsCallable('submitReview').call({
        'orderId': orderId,
        'stars': stars,
        'comment': comment,
      });
      await reload();
      return;
    }
    await save('reviews', {
      'id': orderId,
      'orderId': orderId,
      'customerId': uid,
      'workerId': order['workerId'],
      'stars': stars,
      'comment': comment.trim(),
      'createdAt': DateTime.now().toIso8601String(),
    });
    final worker = find('worker_profiles', order['workerId']);
    if (worker != null) {
      final rs = rows('reviews')
          .where((r) => r['workerId'] == order['workerId'])
          .toList();
      worker['reviewCount'] = rs.length;
      worker['rating'] =
          rs.fold<num>(0, (sum, r) => sum + (r['stars'] as num)) / rs.length;
      await save('worker_profiles', worker);
    }
  }

  Future<void> approve(String id, bool accepted, String reason) async {
    if (!admin) throw StateError('Chỉ quản trị viên được duyệt hồ sơ.');
    if (!accepted && reason.trim().isEmpty)
      throw StateError('Cần nhập lý do từ chối.');
    if (live) {
      await FirebaseFunctions.instance.httpsCallable('approveWorker').call({
        'id': id,
        'approved': accepted,
        'reason': reason,
      });
      await reload();
      return;
    }
    final row = find('worker_profiles', id)!;
    await save('worker_profiles', {
      ...row,
      'approval': accepted ? 'approved' : 'rejected',
      'reason': reason,
    });
  }

  Future<void> setUserStatus(String id, String status) async {
    if (!admin || id == uid)
      throw StateError('Không được thay đổi trạng thái tài khoản này.');
    if (live) {
      await FirebaseFunctions.instance.httpsCallable('setUserStatus').call({
        'id': id,
        'status': status,
      });
      await reload();
      return;
    }
    await save('users', {...find('users', id)!, 'status': status});
  }

  Future<void> enablePush() async {
    if (!live)
      throw StateError(
        'Thông báo đẩy cần Firebase thật; demo vẫn có thông báo trong ứng dụng.',
      );
    const vapid = String.fromEnvironment('FIREBASE_VAPID_KEY');
    if (vapid.isEmpty) throw StateError('Chưa cấu hình khóa VAPID cho web.');
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized)
      throw StateError('Bạn chưa cho phép trình duyệt nhận thông báo.');
    final token = await messaging.getToken(vapidKey: vapid);
    if (token == null) throw StateError('Chưa lấy được mã nhận thông báo.');
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcmTokens');
    final old = await col.where('token', isEqualTo: token).get();
    if (old.docs.isEmpty)
      await col.add({
        'token': token,
        'createdAt': DateTime.now().toIso8601String(),
      });
  }

  Future<void> markRead([String? id]) async {
    final own = rows('notifications')
        .where((n) => n['userId'] == uid && (id == null || n['id'] == id));
    if (live) {
      final batch = FirebaseFirestore.instance.batch();
      for (final n in own) {
        batch.update(
          FirebaseFirestore.instance.collection('notifications').doc(n['id']),
          {'read': true},
        );
      }
      await batch.commit();
      await reload();
      return;
    }
    for (final n in own.toList()) {
      await save('notifications', {...n, 'read': true});
    }
  }

  void demoRole(String value) {
    if (live) return;
    role = value;
    uid = value == 'worker' ? 'w2' : 'demo-y';
    notifyListeners();
  }

  Future<void> reset() async {
    if (live) return;
    data = seedData();
    await persist();
  }
}
