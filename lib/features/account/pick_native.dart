import 'package:flutter/services.dart';

Future<Uint8List?> pickPhoto() =>
    const MethodChannel('beehome/photo').invokeMethod<Uint8List>('choose');
