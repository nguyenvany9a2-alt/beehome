import 'dart:convert';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/theme.dart';
import '../../data/bee_store.dart';
import '../../data/safe_writes.dart';
import '../../widgets/common.dart';
import 'pick_native.dart' if (dart.library.js_interop) 'pick_web.dart';

const defaultLook = {
  'scene': 'auto',
  'tint': 'warm',
  'scale': 1.0,
  'still': false
};

Future<String?> chooseAvatar() async {
  final bytes = await pickPhoto();
  if (bytes == null) return null;
  final buffer = await ui.ImmutableBuffer.fromUint8List(bytes);
  ui.ImageDescriptor? image;
  ui.Codec? codec;
  ui.Image? original, thumbnail;
  ui.Picture? picture;
  try {
    image = await ui.ImageDescriptor.encoded(buffer);
    if (image.width * image.height > 40000000) {
      throw StateError('Hãy chọn ảnh dưới 40 megapixel.');
    }
    final ratio = math.min(1.0, 384 / math.max(image.width, image.height));
    codec = await image.instantiateCodec(
        targetWidth: math.max(1, (image.width * ratio).round()),
        targetHeight: math.max(1, (image.height * ratio).round()));
    original = (await codec.getNextFrame()).image;
    final side = math.min(original.width, original.height).toDouble();
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    canvas.drawImageRect(
        original,
        Rect.fromLTWH((original.width - side) / 2, (original.height - side) / 2,
            side, side),
        const Rect.fromLTWH(0, 0, 112, 112),
        Paint()..filterQuality = FilterQuality.medium);
    picture = recorder.endRecording();
    thumbnail = await picture.toImage(112, 112);
    final png = await thumbnail.toByteData(format: ui.ImageByteFormat.png);
    if (png == null) throw StateError('Không đọc được ảnh.');
    return 'data:image/png;base64,${base64Encode(png.buffer.asUint8List(png.offsetInBytes, png.lengthInBytes))}';
  } finally {
    thumbnail?.dispose();
    picture?.dispose();
    original?.dispose();
    codec?.dispose();
    image?.dispose();
    buffer.dispose();
  }
}

class AccountAvatar extends StatelessWidget {
  const AccountAvatar({super.key, required this.profile});
  final RecordData profile;
  @override
  Widget build(BuildContext context) {
    final url = profile['avatarUrl']?.toString() ?? '';
    ImageProvider? image;
    if (url.startsWith('data:image/png;base64,') && url.length <= 80000) {
      try {
        image = MemoryImage(base64Decode(url.substring(22)));
      } on FormatException {
        image = null;
      }
    } else if (url.startsWith('https://')) {
      image = NetworkImage(url);
    }
    final initials = (profile['name']?.toString() ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((s) => s.isNotEmpty)
        .toList();
    final letters = [
      if (initials.length > 1) initials.first.characters.first,
      if (initials.isNotEmpty) initials.last.characters.first
    ].join().toUpperCase();
    return CircleAvatar(
        radius: 34,
        backgroundColor: honey,
        foregroundImage: image,
        onForegroundImageError: image == null ? null : (_, __) {},
        child: Text(letters,
            style: const TextStyle(
                fontSize: 24, color: ink, fontWeight: FontWeight.w700)));
  }
}

class AccountPreferences extends StatefulWidget {
  const AccountPreferences({super.key, required this.store});
  final BeeStore store;
  @override
  State<AccountPreferences> createState() => _AccountPreferencesState();
}

class _AccountPreferencesState extends State<AccountPreferences> {
  bool saving = false;
  String? error;
  Map<String, dynamic> get look => {
        ...defaultLook,
        ...?widget.store.profile['appearance'] as Map<String, dynamic>?
      };
  Future<void> write(Future<void> Function() operation) async {
    if (saving) return;
    setState(() {
      saving = true;
      error = null;
    });
    try {
      await operation();
    } catch (e) {
      if (mounted) setState(() => error = beeError(e));
    } finally {
      if (mounted) setState(() => saving = false);
    }
  }

  Future<void> saveLook(Map<String, dynamic> next) => write(() =>
      widget.store.save('users', {'id': widget.store.uid, 'appearance': next}));
  Widget choices(String label, String key, Map<Object, String> options) =>
      Padding(
          padding: const EdgeInsets.only(top: 14),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 5),
            Wrap(spacing: 7, runSpacing: 5, children: [
              for (final opt in options.entries)
                ChoiceChip(
                    label: Text(opt.value),
                    selected: look[key] == opt.key,
                    onSelected: saving
                        ? null
                        : (_) => saveLook({...look, key: opt.key}))
            ]),
          ]));
  @override
  Widget build(BuildContext context) => Panel(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Ảnh và giao diện', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 10),
        Wrap(spacing: 8, runSpacing: 6, children: [
          OutlinedButton.icon(
              onPressed: saving
                  ? null
                  : () => write(() async {
                        final s = widget.store;
                        final photo = await chooseAvatar();
                        if (photo != null && mounted && s.sessionActive) {
                          await s
                              .save('users', {'id': s.uid, 'avatarUrl': photo});
                        }
                      }),
              icon: const Icon(Icons.add_photo_alternate_outlined),
              label: const Text('Chọn ảnh đại diện')),
          if ((widget.store.profile['avatarUrl'] ?? '') != '')
            TextButton(
                onPressed: saving
                    ? null
                    : () => write(() => widget.store.save(
                        'users', {'id': widget.store.uid, 'avatarUrl': ''})),
                child: const Text('Bỏ ảnh'))
        ]),
        choices('Hình nền', 'scene', {
          'auto': 'Theo thiết bị',
          'room': 'Phòng khách',
          'corner': 'Góc đọc sách',
          'plain': 'Nền trơn'
        }),
        choices('Tông nền', 'tint',
            {'warm': 'Mật ong', 'sage': 'Lá xanh', 'stone': 'Xanh xám'}),
        choices('Cỡ chữ', 'scale',
            {1.0: 'Tiêu chuẩn', 1.15: 'Lớn', 1.3: 'Rất lớn'}),
        SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Giảm chuyển động'),
            value: look['still'] == true,
            onChanged: saving ? null : (v) => saveLook({...look, 'still': v})),
        TextButton(
            onPressed: saving ? null : () => saveLook({...defaultLook}),
            child: const Text('Khôi phục giao diện mặc định')),
        if (saving) const LinearProgressIndicator(minHeight: 2),
        if (error != null) Text(error!, style: const TextStyle(color: danger)),
      ]));
}
