import 'dart:ui' as ui;
import 'package:beehome/features/home/guest_home.dart';
import 'package:beehome/main.dart';
import 'package:beehome/widgets/bee_backdrop.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'fixtures/bee_fixture.dart';

void size(WidgetTester t, Size size) {
  t.view.devicePixelRatio = 1;
  t.view.physicalSize = size;
  addTearDown(t.view.resetDevicePixelRatio);
  addTearDown(t.view.resetPhysicalSize);
}

Future<void> tap(WidgetTester t, Finder f) async {
  await t.ensureVisible(f.first);
  await t.pumpAndSettle();
  await t.tap(f.first);
  await t.pumpAndSettle();
}

void main() {
  testWidgets('Khách vãng lai xem danh mục và vào đăng nhập từ chi tiết',
      (t) async {
    size(t, const Size(390, 844));
    var login = false;
    final services = FixtureStore().rows('services');
    await t.pumpWidget(MaterialApp(
        home: GuestHome(
            login: () => login = true,
            catalog: Stream.value([
              ...services,
              {'id': 'off', 'name': 'Dịch vụ đã ẩn', 'active': false}
            ]))));
    await t.pumpAndSettle();
    expect(find.text('Dịch vụ đã ẩn'), findsNothing);
    await tap(t, find.text('Dọn nhà theo giờ'));
    await tap(t, find.text('Đăng nhập để đặt lịch'));
    expect(login, isTrue);
    expect(t.takeException(), isNull);
  });
  setUp(() => SharedPreferences.setMockInitialValues({}));
  testWidgets('Logo ở giữa, thanh cố định, rê chuột và ghim menu', (t) async {
    size(t, const Size(1440, 900));
    await t.pumpWidget(BeeHomeApp(store: FixtureStore()));
    await t.pumpAndSettle();
    final logo = find.byTooltip('Về trang chủ');
    expect(t.getCenter(logo).dx, 720);
    final origin = t.getCenter(logo);
    await t.drag(find.text('Dịch vụ đang mở'), const Offset(0, -400));
    await t.pumpAndSettle();
    expect(t.getCenter(logo), origin);
    await tap(t, find.byTooltip('Thu gọn thanh công cụ'));
    final label = find.widgetWithText(ListTile, 'Địa chỉ của tôi');
    expect(label, findsNothing);
    final mouse = await t.createGesture(kind: ui.PointerDeviceKind.mouse);
    await mouse.addPointer(location: const Offset(300, 100));
    await mouse.moveTo(const Offset(25, 175));
    await t.pumpAndSettle();
    expect(label, findsOneWidget);
    await mouse.moveTo(const Offset(350, 180));
    await t.pumpAndSettle();
    expect(label, findsNothing);
    await tap(t, find.byTooltip('Ghim thanh công cụ'));
    expect(label, findsOneWidget);
    await tap(t, label);
    expect(find.text('Nhà riêng'), findsOneWidget);
    await tap(t, logo);
    expect(find.text('Dịch vụ đang mở'), findsOneWidget);
    await mouse.removePointer();
    expect(t.takeException(), isNull);
  });
  testWidgets('Lưu và hủy địa chỉ đang nhập, mở lại không lỗi vòng đời',
      (t) async {
    size(t, const Size(390, 844));
    final store = FixtureStore();
    await t.pumpWidget(BeeHomeApp(store: store));
    await t.pumpAndSettle();
    await tap(t, find.byTooltip('Mở menu'));
    await tap(t, find.text('Địa chỉ của tôi'));
    await tap(t, find.text('Thêm địa chỉ'));
    final inputs = find.byType(TextFormField);
    await t.enterText(inputs.at(2), '0912345678');
    await t.enterText(inputs.at(3), '24 Nguyễn Huệ');
    await tap(t, find.text('Lưu thay đổi'));
    expect(store.rows('addresses').where((a) => a['detail'] == '24 Nguyễn Huệ'),
        hasLength(1));
    await tap(t, find.text('Thêm địa chỉ'));
    await t.enterText(find.byType(TextFormField).at(3), 'Hủy bản nháp');
    await tap(t, find.text('Hủy'));
    await tap(t, find.byTooltip('Về trang chủ'));
    expect(store.rows('addresses').where((a) => a['detail'] == 'Hủy bản nháp'),
        isEmpty);
    expect(t.takeException(), isNull);
  });
  testWidgets('Giao diện hồ sơ áp dụng ngay và lưu sau khi mở lại', (t) async {
    size(t, const Size(320, 690));
    final store = FixtureStore();
    await t.pumpWidget(BeeHomeApp(store: store));
    await t.pumpAndSettle();
    await tap(t, find.byTooltip('Mở hồ sơ'));
    await tap(t, find.text('Phòng khách'));
    expect(find.image(const AssetImage(roomPhoto)), findsOneWidget);
    await tap(t, find.text('Lá xanh'));
    await tap(t, find.text('Rất lớn'));
    final s = MediaQuery.of(t.element(find.text('Ảnh và giao diện')));
    expect(s.textScaler.scale(20), 26);
    await tap(t, find.text('Giảm chuyển động'));
    final fresh = FixtureStore();
    await fresh.init();
    expect(fresh.profile['appearance'],
        {'scene': 'room', 'tint': 'sage', 'scale': 1.3, 'still': true});
    await tap(t, find.text('Khôi phục giao diện mặc định'));
    expect(find.image(const AssetImage(mobileRoomPhoto)), findsOneWidget);
    await tap(t, find.byTooltip('Về trang chủ'));
    expect(t.takeException(), isNull);
  });
}
