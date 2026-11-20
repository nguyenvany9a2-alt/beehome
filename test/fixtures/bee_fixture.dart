import 'dart:convert';
import 'package:beehome/data/bee_store.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Small, deterministic records used only by automated tests.
class FixtureStore extends BeeStore {
  FixtureStore(
      {String user = 'qa-customer',
      String accountRole = 'customer',
      Map<String, dynamic>? records})
      : super.inMemory(
            uid: user,
            role: accountRole,
            data: records ??
                {
                  'services': [
                    {
                      'id': 's1',
                      'name': 'Dọn nhà theo giờ',
                      'category': 'Dọn dẹp',
                      'description': 'Vệ sinh sàn nhà',
                      'price': 75000,
                      'duration': 2,
                      'unit': 'giờ',
                      'active': true,
                      'includes': ['Lau sàn'],
                      'excludes': []
                    },
                    {
                      'id': 's2',
                      'name': 'Chăm sóc rèm',
                      'category': 'Chăm vải',
                      'price': 1600000,
                      'duration': 3,
                      'unit': 'gói',
                      'active': true
                    }
                  ],
                  'users': [
                    {
                      'id': 'qa-customer',
                      'name': 'Khách kiểm thử',
                      'email': 'qa@example.invalid',
                      'phone': '',
                      'avatarUrl': '',
                      'status': 'active',
                      'role': 'customer'
                    }
                  ],
                  'worker_profiles': [
                    {
                      'id': 'w1',
                      'name': 'Kỹ thuật viên',
                      'skills': '',
                      'approval': 'approved',
                      'rating': 5,
                      'reviewCount': 1
                    }
                  ],
                  'addresses': [
                    {
                      'id': 'a1',
                      'userId': 'qa-customer',
                      'label': 'Nhà riêng',
                      'detail': 'Địa chỉ kiểm thử',
                      'area': '',
                      'contact': '',
                      'phone': '',
                      'default': true
                    }
                  ],
                  'orders': [
                    {
                      'id': 'BH1001',
                      'customerId': 'qa-customer',
                      'workerId': 'w1',
                      'serviceName': 'Dọn nhà theo giờ',
                      'status': 'completed',
                      'total': 150000,
                      'date': '2026-11-01',
                      'time': '08:00',
                      'duration': 2,
                      'paymentStatus': 'paid'
                    },
                    {
                      'id': 'BH1002',
                      'customerId': 'qa-customer',
                      'serviceName': 'Chăm sóc rèm',
                      'status': 'pending',
                      'total': 1600000,
                      'date': '2026-11-02',
                      'paymentStatus': 'unpaid'
                    }
                  ],
                  'reviews': [
                    {
                      'id': 'old-order',
                      'orderId': 'old-order',
                      'customerId': 'other',
                      'workerId': 'w1',
                      'stars': 5
                    }
                  ],
                  'notifications': [
                    {
                      'id': 'n1',
                      'userId': 'qa-customer',
                      'title': 'Cập nhật',
                      'body': 'Đã nhận đơn',
                      'createdAt': '2026-11-01',
                      'read': false
                    }
                  ],
                });

  static const cacheKey = 'beehome.test.store';
  @override
  Future<void> init() async {
    final previous =
        (await SharedPreferences.getInstance()).getString(cacheKey);
    if (previous != null) {
      data = Map<String, dynamic>.from(jsonDecode(previous) as Map);
    }
  }

  @override
  Future<void> persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(cacheKey, jsonEncode(data));
    await super.persist();
  }
}
