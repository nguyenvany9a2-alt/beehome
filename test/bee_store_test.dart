import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beehome/data/bee_store.dart';
import 'package:beehome/core/theme.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late BeeStore s;
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    s = BeeStore();
    await s.init();
  });
  test('Tìm kiếm tiếng Việt không dấu', () {
    expect(folded('Dọn Nhà – GIẶT ỦI'), 'don nha – giat ui');
  });
  test('Đánh giá chỉ một lần và tính lại điểm', () async {
    await s.review('BH1001', 4, 'Tốt');
    expect(s.find('worker_profiles', 'w1')!['rating'], 4.5);
    await expectLater(s.review('BH1001', 5, 'Lặp'), throwsStateError);
  });
  test('Không đánh giá đơn chưa hoàn thành', () async {
    await expectLater(s.review('BH1002', 5, ''), throwsStateError);
  });
  test('Không đánh giá đơn người khác', () async {
    s.demoRole('worker');
    await expectLater(s.review('BH1001', 5, ''), throwsStateError);
  });
  test('Không đánh giá ngoài khoảng điểm', () async {
    await expectLater(s.review('BH1001', 6, ''), throwsStateError);
  });
  test('Đổi mặc định không tạo hai địa chỉ mặc định', () async {
    await s.saveAddress({'id': 'a2', 'label': 'Nhà khác', 'default': true});
    expect(s.rows('addresses').where((a) => a['default'] == true).length, 1);
    expect(s.find('addresses', 'a1')!['default'], false);
    await s.deleteAddress('a2');
    expect(s.find('addresses', 'a1')!['default'], true);
  });
  test('Khách không được duyệt người giúp việc', () async {
    await expectLater(s.approve('w2', true, ''), throwsStateError);
  });
  test('Thông báo đã đọc được lưu sau tải lại', () async {
    await s.markRead('n1');
    final other = BeeStore();
    await other.init();
    expect(other.find('notifications', 'n1')!['read'], true);
  });
}
