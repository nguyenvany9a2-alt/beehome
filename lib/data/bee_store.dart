import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'safe_writes.dart';

import 'package:firebase_messaging/firebase_messaging.dart';

typedef RecordData = Map<String, dynamic>;

class MissingProfile extends StateError {
  MissingProfile() : super('Chưa có hồ sơ BeeHome cho tài khoản này.');
}

class BeeStore extends ChangeNotifier {
  BeeStore()
      : live = true,
        uid = '',
        role = 'customer',
        data = {};
  @visibleForTesting
  BeeStore.inMemory({required this.uid, required this.role, required this.data})
      : live = false;
  final bool live;
  final subscriptions = <String, StreamSubscription>{};
  final _errors = <String, String>{};
  String? get syncError => _errors.values.firstOrNull;
  String uid, role;
  bool _closed = false;
  bool get sessionActive =>
      !_closed && (!live || FirebaseAuth.instance.currentUser?.uid == uid);
  Map<String, dynamic> data;
  List<RecordData> rows(String name) {
    final records = ((data[name] ?? []) as List)
        .map((e) => Map<String, dynamic>.from(e as Map))
        .toList();
    if (name == 'worker_profiles') {
      final totals = {for (final r in rows('rating_totals')) r['id']: r};
      for (final worker in records) {
        final extra = totals[worker['id']];
        if (extra == null) continue;
        final old = (worker['reviewCount'] as num?) ?? 0;
        final count = old + (extra['count'] as num);
        final oldSum = (worker['ratingSum'] as num?) ??
            ((worker['rating'] as num?) ?? 0) * old;
        worker['reviewCount'] = count;
        worker['rating'] = count == 0 ? 0 : (oldSum + extra['sum']) / count;
      }
    }
    return records;
  }

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
    if (!live) return;
    final user = await FirebaseAuth.instance.authStateChanges().first;
    if (user == null) {
      throw StateError(
        'Phiên đăng nhập đã kết thúc. Vui lòng đăng nhập lại.',
      );
    }
    uid = user.uid;
    final token = await user.getIdTokenResult(true);
    final doc = await FirebaseFirestore.instance.doc('users/$uid').get();
    if (!doc.exists) throw MissingProfile();
    final profile = doc.data()!;
    if (profile['status'] != 'active') {
      throw StateError('Tài khoản đang bị khóa. Hãy liên hệ quản trị viên.');
    }
    if (profile['role'] == 'admin' && token.claims?['role'] != 'admin') {
      throw StateError(
          'Hồ sơ quản trị chưa khớp quyền Firebase Authentication. Hãy kiểm tra custom claim của UID này.');
    }
    role = token.claims?['role'] == 'admin'
        ? 'admin'
        : profile['role'] == 'worker'
            ? 'worker'
            : 'customer';
    data['users'] = [
      {...profile, 'id': uid}
    ];
    await reload();
  }

  Map<String, Query<RecordData>> get _queries {
    final db = FirebaseFirestore.instance;
    Query<RecordData> mine(String name, String field) =>
        db.collection(name).where(field, isEqualTo: uid);
    final party = role == 'worker' ? 'workerId' : 'customerId';
    return {
      'services': admin
          ? db.collection('services')
          : db.collection('services').where('active', isEqualTo: true),
      'users': admin
          ? db.collection('users')
          : db.collection('users').where(FieldPath.documentId, isEqualTo: uid),
      'worker_profiles': admin
          ? db.collection('worker_profiles')
          : role == 'worker'
              ? db
                  .collection('worker_profiles')
                  .where(FieldPath.documentId, isEqualTo: uid)
              : db
                  .collection('worker_profiles')
                  .where('approval', isEqualTo: 'approved'),
      if (role == 'customer') 'addresses': mine('addresses', 'userId'),
      'orders': admin ? db.collection('orders') : mine('orders', party),
      'payments': admin ? db.collection('payments') : mine('payments', party),
      'reviews': admin ? db.collection('reviews') : mine('reviews', party),
      'notifications': mine('notifications', 'userId'),
      'rating_totals': db.collection('rating_totals'),
    };
  }

  void _receive(String name, QuerySnapshot<RecordData> snapshot) {
    if (!sessionActive) return;
    data[name] = [
      for (final d in snapshot.docs) {...d.data(), 'id': d.id}
    ];
    _errors.remove(name);
    if (name == 'worker_profiles' && role == 'worker') {
      final approved = find(name, uid)?['approval'] == 'approved';
      if (approved && !subscriptions.containsKey('job_offers')) {
        _listen(
            'job_offers', FirebaseFirestore.instance.collection('job_offers'));
      } else if (!approved) {
        subscriptions.remove('job_offers')?.cancel();
        data.remove('job_offers');
        _errors.remove('job_offers');
      }
    }
    notifyListeners();
  }

  void _listen(String name, Query<RecordData> query) {
    subscriptions[name] = query
        .snapshots()
        .listen((snap) => _receive(name, snap), onError: (Object e) {
      if (!sessionActive) return;
      _errors[name] = beeError(e);
      subscriptions.remove(name)?.cancel();
      notifyListeners();
    });
  }

  Future<void> reload() async {
    if (!live || !sessionActive) return;
    await Future.wait(_queries.entries.map((item) async {
      if (!subscriptions.containsKey(item.key)) _listen(item.key, item.value);
      _receive(item.key, await item.value.get());
    }));
  }

  @override
  void dispose() {
    _closed = true;
    for (final sub in subscriptions.values) {
      sub.cancel();
    }
    subscriptions.clear();
    super.dispose();
  }

  Future<void> persist() async {
    notifyListeners();
  }

  Future<void> save(String collection, RecordData row) async {
    final id = row['id']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toString();
    row = {...row, 'id': id};
    if (collection == 'services' && !admin) {
      throw StateError('Chỉ quản trị viên được quản lý dịch vụ.');
    }
    if (live) {
      final copy = {...row}..remove('id');
      await FirebaseFirestore.instance
          .collection(collection)
          .doc(id)
          .set(copy, SetOptions(merge: true));
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
      await writeAddress(uid, row);
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
      await writeAddress(uid, {'id': id}, remove: true);
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
        order['status'] != 'completed') {
      throw StateError('Chỉ đánh giá đơn của bạn đã hoàn thành.');
    }
    if (stars < 1 || stars > 5) {
      throw StateError('Vui lòng chọn từ 1 đến 5 sao.');
    }
    if (find('reviews', orderId) != null) {
      throw StateError('Đơn này đã được đánh giá.');
    }
    if (live) {
      await writeReview(uid, order, stars, comment);
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
          rs.fold<num>(0, (totalStars, r) => totalStars + (r['stars'] as num)) /
              rs.length;
      await save('worker_profiles', worker);
    }
  }

  Future<void> approve(String id, bool accepted, String reason) async {
    if (!admin) throw StateError('Chỉ quản trị viên được duyệt hồ sơ.');
    if (!accepted && reason.trim().isEmpty) {
      throw StateError('Cần nhập lý do từ chối.');
    }
    if (live) {
      await FirebaseFirestore.instance.doc('worker_profiles/$id').update({
        'approval': accepted ? 'approved' : 'rejected',
        'reason': reason.trim(),
        'approvedBy': uid,
        'approvedAt': DateTime.now().toUtc().toIso8601String(),
      });
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
    if (!admin || id == uid) {
      throw StateError('Không được thay đổi trạng thái tài khoản này.');
    }
    if (live) {
      await FirebaseFirestore.instance
          .doc('users/$id')
          .update({'status': status});
      return;
    }
    await save('users', {...find('users', id)!, 'status': status});
  }

  Future<void> enablePush() async {
    if (!live) {
      throw StateError(
        'Cần kết nối Firebase để bật thông báo trình duyệt.',
      );
    }
    const vapid = String.fromEnvironment('FIREBASE_VAPID_KEY');
    if (vapid.isEmpty) throw StateError('Chưa cấu hình khóa VAPID cho web.');
    final messaging = FirebaseMessaging.instance;
    final settings = await messaging.requestPermission();
    if (settings.authorizationStatus != AuthorizationStatus.authorized) {
      throw StateError('Bạn chưa cho phép trình duyệt nhận thông báo.');
    }
    final token = await messaging.getToken(vapidKey: kIsWeb ? vapid : null);
    if (token == null) throw StateError('Chưa lấy được mã nhận thông báo.');
    final col = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fcmTokens');
    final old = await col.where('token', isEqualTo: token).get();
    if (old.docs.isEmpty) {
      await col.add({
        'token': token,
        'createdAt': DateTime.now().toIso8601String(),
      });
    }
  }

  Future<void> markRead([String? id]) async {
    final own = rows('notifications')
        .where((n) =>
            n['userId'] == uid &&
            n['read'] != true &&
            (id == null || n['id'] == id))
        .toList();
    if (live) {
      final db = FirebaseFirestore.instance;
      for (int i = 0; i < own.length; i += 400) {
        final batch = db.batch();
        for (final n in own.skip(i).take(400)) {
          batch.update(
              db.collection('notifications').doc(n['id']), {'read': true});
        }
        await batch.commit();
      }
      return;
    }
    for (final n in own.toList()) {
      await save('notifications', {...n, 'read': true});
    }
  }
}
