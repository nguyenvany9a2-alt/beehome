import 'package:beehome/widgets/bee_backdrop.dart';
import 'package:beehome/widgets/scroll_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const tileKey = ValueKey('below-fold');

Widget scrollingPage(ScrollController controller, {bool reduced = false}) {
  return MaterialApp(
    builder: buildBeeBackdrop,
    home: Builder(builder: (context) {
      return MediaQuery(
        data: MediaQuery.of(context).copyWith(disableAnimations: reduced),
        child: SingleChildScrollView(
          controller: controller,
          child: const Column(children: [
            SizedBox(height: 940),
            ScrollReveal(key: tileKey, child: SizedBox(height: 100)),
            SizedBox(height: 960),
          ]),
        ),
      );
    }),
  );
}

double tileOpacity(WidgetTester tester) => tester
    .widget<FadeTransition>(
      find.descendant(
          of: find.byKey(tileKey), matching: find.byType(FadeTransition)),
    )
    .opacity
    .value;

void main() {
  testWidgets('Ảnh nền đổi theo chiều rộng và đứng yên khi cuộn',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(1280, 800);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(scrollingPage(scroll));
    final widePhoto = find.image(const AssetImage(roomPhoto));
    expect(tester.getSize(widePhoto), const Size(1280, 800));
    final origin = tester.getTopLeft(widePhoto);
    scroll.jumpTo(600);
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(widePhoto), origin);
    tester.view.physicalSize = const Size(390, 844);
    await tester.pumpAndSettle();
    expect(widePhoto, findsNothing);
    expect(tester.getSize(find.image(const AssetImage(mobileRoomPhoto))),
        const Size(390, 844));
  });

  testWidgets('Mục bên dưới hiện một lần khi cuộn tới', (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(scrollingPage(scroll));
    await tester.pumpAndSettle();
    expect(tileOpacity(tester), 0);
    scroll.jumpTo(650);
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 90));
    expect(tileOpacity(tester), allOf(greaterThan(0), lessThan(1)));
    await tester.pumpAndSettle();
    expect(tileOpacity(tester), 1);
    scroll.jumpTo(0);
    await tester.pumpAndSettle();
    scroll.jumpTo(650);
    await tester.pump();
    expect(tileOpacity(tester), 1);
  });

  testWidgets('Giảm chuyển động hiển thị ngay cả nội dung ở ngoài màn hình',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    await tester.pumpWidget(scrollingPage(scroll));
    await tester.pumpAndSettle();
    expect(tileOpacity(tester), 0);
    await tester.pumpWidget(scrollingPage(scroll, reduced: true));
    expect(tileOpacity(tester), 1);
  });

  testWidgets('Mở rộng chiều cao cũng làm xuất hiện phần vừa nhìn thấy',
      (tester) async {
    final scroll = ScrollController();
    addTearDown(scroll.dispose);
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(900, 600);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(scrollingPage(scroll));
    await tester.pumpAndSettle();
    expect(tileOpacity(tester), 0);
    tester.view.physicalSize = const Size(900, 1100);
    await tester.pumpAndSettle();
    expect(tileOpacity(tester), 1);
  });
}
