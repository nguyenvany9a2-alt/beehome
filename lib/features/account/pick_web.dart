import 'dart:async';
import 'dart:js_interop';
import 'dart:typed_data';
import 'package:web/web.dart' as web;

Future<Uint8List?> pickPhoto() {
  final result = Completer<Uint8List?>();
  final input = web.HTMLInputElement()
    ..type = 'file'
    ..accept = 'image/jpeg,image/png,image/webp';
  input.style.display = 'none';
  web.document.body?.appendChild(input);
  input.oncancel = ((web.Event _) {
    if (!result.isCompleted) result.complete(null);
  }).toJS;
  input.onchange = ((web.Event _) {
    Future<void>(() async {
      final f = input.files?.item(0);
      if (f == null) {
        result.complete(null);
        return;
      }
      if (f.size > 8 * 1024 * 1024) throw StateError('Chọn ảnh nhỏ hơn 8 MB.');
      result.complete((await f.arrayBuffer().toDart).toDart.asUint8List());
    }).catchError((Object e) {
      if (!result.isCompleted) result.completeError(e);
    });
  }).toJS;
  input.click();
  return result.future.whenComplete(() => input.remove());
}
