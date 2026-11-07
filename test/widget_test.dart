import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:beehome/main.dart';
import 'package:beehome/data/bee_store.dart';

void main() {
  testWidgets('BeeHome hiển thị dịch vụ và điều hướng địa chỉ', (tester) async {
    SharedPreferences.setMockInitialValues({});
    tester.view.physicalSize = const Size(1440, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final s = BeeStore();
    await s.init();
    await tester.pumpWidget(BeeHomeApp(store: s));
    await tester.pumpAndSettle();
    expect(find.text('BeeHome'), findsOneWidget);
    expect(find.text('Dọn nhà theo giờ'), findsOneWidget);
    await tester.tap(find.text('Địa chỉ của tôi'));
    await tester.pumpAndSettle();
    expect(find.text('Thêm địa chỉ'), findsOneWidget);
    expect(find.text('Nhà riêng'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
