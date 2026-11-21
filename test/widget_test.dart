import 'package:shared_preferences/shared_preferences.dart';
import 'package:beehome/core/locales.dart';
import 'package:beehome/core/theme.dart';
import 'package:beehome/features/auth/auth_screen.dart';
import 'package:beehome/main.dart' as app;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'fixtures/bee_fixture.dart';

void viewport(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
  await tester.tap(finder.first);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Thiếu cấu hình chỉ hiển thị hướng dẫn kết nối', (tester) async {
    await app.main();
    await tester.pumpAndSettle();
    expect(find.text('Chưa có cấu hình Firebase'), findsOneWidget);
    expect(find.text('Dọn nhà theo giờ'), findsNothing);
  });

  testWidgets('Desktop tìm tiếng Việt, xóa lọc và mở địa chỉ', (tester) async {
    viewport(tester, const Size(1440, 1000));
    await tester.pumpWidget(app.BeeHomeApp(store: FixtureStore()));
    await tester.pumpAndSettle();
    expect(find.text('Dọn nhà theo giờ'), findsOneWidget);
    expect(find.text('Chăm sóc rèm'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'cham soc rem');
    await tester.pumpAndSettle();
    expect(find.text('Dọn nhà theo giờ'), findsNothing);
    await tapVisible(tester, find.text('Xóa bộ lọc'));
    expect(tester.widget<TextField>(find.byType(TextField)).controller!.text,
        isEmpty);
    await tapVisible(tester, find.text('Địa chỉ của tôi'));
    expect(find.text('Nhà riêng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Mobile điều hướng, bộ lọc, so sánh và bàn giao đúng đơn',
      (tester) async {
    viewport(tester, const Size(375, 780));
    Map<String, dynamic>? draft;
    await tester.pumpWidget(app.BeeHomeApp(
        store: FixtureStore(), onBookingRequested: (d) => draft = d));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.byTooltip('Bộ lọc'));
    await tapVisible(tester, find.text('Theo giờ'));
    await tapVisible(tester, find.text('Áp dụng'));
    expect(find.text('Chăm sóc rèm'), findsNothing);
    await tapVisible(tester, find.byTooltip('So sánh Dọn nhà theo giờ'));
    await tapVisible(tester, find.text('So sánh (1/3)'));
    expect(find.text('So sánh dịch vụ'), findsOneWidget);
    await tapVisible(tester, find.text('Đóng'));
    await tapVisible(tester, find.text('Xem chi tiết'));
    await tapVisible(tester, find.text('Đặt lịch'));
    await tapVisible(tester, find.text('Chọn ngày làm'));
    expect(draft, {'serviceId': 's1', 'addressId': 'a1', 'duration': 2});
    await tapVisible(tester, find.text('Đơn đặt'));
    await tapVisible(tester, find.text('Chi tiết'));
    expect(find.text('Chi tiết đơn BH1001'), findsOneWidget);
    await tapVisible(tester, find.text('Đóng'));
    await tapVisible(tester, find.text('Thêm'));
    await tapVisible(tester, find.text('Địa chỉ của tôi'));
    expect(find.text('Nhà riêng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Chọn ngày giờ, xác nhận và tạo đúng một đơn trong bộ kiểm thử',
      (tester) async {
    viewport(tester, const Size(390, 844));
    SharedPreferences.setMockInitialValues({});
    final store = FixtureStore();
    final before = store.rows('orders').length;
    await tester.pumpWidget(app.BeeHomeApp(store: store));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Xem chi tiết'));
    await tapVisible(tester, find.text('Đặt lịch'));
    await tapVisible(tester, find.text('Chọn ngày làm'));
    final day = find.byType(DatePickerDialog);
    final confirmDay =
        MaterialLocalizations.of(tester.element(day)).okButtonLabel;
    await tapVisible(
        tester, find.descendant(of: day, matching: find.text(confirmDay)));
    final time = find.byType(TimePickerDialog);
    final confirmTime =
        MaterialLocalizations.of(tester.element(time)).okButtonLabel;
    await tapVisible(
        tester, find.descendant(of: time, matching: find.text(confirmTime)));
    expect(find.text('Xác nhận lịch đặt'), findsOneWidget);
    expect(store.rows('orders').length, before);
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Đặt dịch vụ'));
    final orders = store.rows('orders');
    expect(orders.length, before + 1);
    expect(orders.last['customerId'], 'qa-customer');
    expect(orders.last['total'], 150000);
    expect(orders.last['status'], 'pending');
    expect(tester.takeException(), isNull);
  });

  testWidgets('Gợi ý công việc lấy từ danh mục thật đang hiển thị',
      (tester) async {
    viewport(tester, const Size(390, 844));
    final store = FixtureStore(records: {
      'services': [
        {
          'id': 'id-tu-firestore',
          'name': 'Vệ sinh theo yêu cầu',
          'active': true,
          'category': 'Chăm nhà',
          'unit': 'gói',
          'price': 1200000,
          'duration': 2,
          'includes': ['Vệ sinh đèn']
        }
      ]
    });
    await tester.pumpWidget(app.BeeHomeApp(store: store));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.text('Chọn theo công việc'));
    await tapVisible(tester, find.text('Vệ sinh đèn'));
    expect(find.text('Vệ sinh theo yêu cầu'), findsOneWidget);
    expect(find.text('Vệ sinh đèn'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Không có dịch vụ thì hiện danh mục trống', (tester) async {
    viewport(tester, const Size(320, 680));
    await tester.pumpWidget(app.BeeHomeApp(store: FixtureStore(records: {})));
    await tester.pumpAndSettle();
    expect(find.text('Chưa có dịch vụ đang mở'), findsOneWidget);
    expect(find.text('Xem chi tiết'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Đăng nhập và đăng ký trên màn hình hẹp', (tester) async {
    viewport(tester, const Size(320, 650));
    await tester.pumpWidget(MaterialApp(
        locale: beeLocale,
        localizationsDelegates: beeDelegates,
        supportedLocales: beeLocales,
        theme: beeTheme(),
        home: const AuthScreen()));
    await tester.pumpAndSettle();
    await tapVisible(tester, find.widgetWithText(FilledButton, 'Đăng nhập'));
    expect(find.text('Nhập địa chỉ email hợp lệ'), findsOneWidget);
    await tapVisible(tester, find.text('Chưa có tài khoản? Đăng ký'));
    expect(find.text('Loại tài khoản'), findsOneWidget);
    await tapVisible(
        tester, find.widgetWithText(FilledButton, 'Tạo tài khoản'));
    expect(find.text('Vui lòng nhập họ tên'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  for (final role in ['worker', 'admin']) {
    testWidgets('Điều hướng đúng tài khoản $role', (tester) async {
      viewport(tester, const Size(390, 820));
      await tester.pumpWidget(app.BeeHomeApp(
          store: FixtureStore(
              user: role == 'worker' ? 'w1' : 'admin', accountRole: role)));
      await tester.pumpAndSettle();
      expect(
          find.text(
              role == 'worker' ? 'Hồ sơ nghề nghiệp' : 'Tổng quan vận hành'),
          findsOneWidget);
      await tapVisible(
          tester,
          find.widgetWithText(NavigationDestination,
              role == 'worker' ? 'Công việc' : 'Đơn hàng'));
      expect(
          find.text(
              role == 'worker' ? 'Công việc của tôi' : 'Quản lý đơn hàng'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
