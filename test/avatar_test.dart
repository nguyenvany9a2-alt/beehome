import 'dart:convert';
import 'dart:ui' as ui;
import 'package:beehome/features/account/preferences.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('beehome/photo');
  final mock =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  tearDown(() => mock.setMockMethodCallHandler(channel, null));
  test('Ảnh chọn từ thiết bị được thu nhỏ và lưu đúng định dạng', () async {
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    canvas.drawColor(const ui.Color(0xffe5ba74), ui.BlendMode.src);
    final picture = recorder.endRecording();
    final input = await picture.toImage(420, 240);
    final data = await input.toByteData(format: ui.ImageByteFormat.png);
    mock.setMockMethodCallHandler(
        channel, (call) async => data!.buffer.asUint8List());
    final saved = await chooseAvatar();
    expect(saved, startsWith('data:image/png;base64,'));
    expect(saved!.length, lessThan(80000));
    final bytes = base64Decode(saved.substring(22));
    final header = ByteData.sublistView(bytes);
    expect([header.getUint32(16), header.getUint32(20)], [112, 112]);
    input.dispose();
    picture.dispose();
    mock.setMockMethodCallHandler(channel, (call) async => null);
    expect(await chooseAvatar(), isNull);
  });
}
