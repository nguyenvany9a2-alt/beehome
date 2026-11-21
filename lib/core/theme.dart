import 'package:flutter/material.dart';

const ink = Color(0xFF163C34);
const forest = Color(0xFF174A3B);
const honey = Color(0xFFF2C969);
const cream = Color(0xFFF7F6F1);
const muted = Color(0xFF52635B);
const leaf = Color(0xFFE6EEE7);
const line = Color(0xFFDCE2D9);
const danger = Color(0xFF993E34);

ThemeData beeTheme() {
  final colors = ColorScheme.fromSeed(
    seedColor: forest,
    primary: forest,
    onPrimary: Colors.white,
    secondary: honey,
    onSecondary: ink,
    surface: Colors.white,
    onSurface: ink,
    error: danger,
    outline: const Color(0xFF78897F),
  );
  final base = ThemeData(
      useMaterial3: true, colorScheme: colors, fontFamily: 'Work Sans');
  final text = base.textTheme.apply(bodyColor: ink, displayColor: ink);
  const display = TextStyle(
      fontFamily: 'Playfair Display',
      color: ink,
      fontWeight: FontWeight.w600,
      height: 1.16,
      letterSpacing: -.65);
  final rounded =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(14));
  final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: const BorderSide(color: line));
  return base.copyWith(
    scaffoldBackgroundColor: Colors.transparent,
    textTheme: text.copyWith(
      headlineLarge: display.copyWith(fontSize: 43),
      headlineMedium: display.copyWith(fontSize: 30),
      titleLarge: text.titleLarge
          ?.copyWith(fontSize: 20, height: 1.26, fontWeight: FontWeight.w700),
      bodyMedium: text.bodyMedium?.copyWith(fontSize: 15, height: 1.45),
    ),
    dividerTheme: const DividerThemeData(color: line, space: 1, thickness: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: border,
      enabledBorder: border,
      focusedBorder: border.copyWith(
          borderSide: const BorderSide(color: forest, width: 2)),
      errorMaxLines: 2,
      hintStyle: const TextStyle(color: muted, fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
      shape: rounded,
      minimumSize: const Size(48, 48),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
      textStyle: const TextStyle(
          fontFamily: 'Work Sans', fontSize: 14, fontWeight: FontWeight.w700),
    )),
    outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
      shape: rounded,
      side: const BorderSide(color: Color(0xFFB7C7B9)),
      minimumSize: const Size(48, 46),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    )),
    chipTheme: base.chipTheme.copyWith(
        backgroundColor: Colors.white,
        selectedColor: leaf,
        side: const BorderSide(color: line),
        shape: const StadiumBorder()),
    dialogTheme: DialogThemeData(
        backgroundColor: cream,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24))),
    navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: leaf,
        height: 68,
        labelTextStyle: WidgetStateProperty.all(const TextStyle(
            fontFamily: 'Work Sans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: ink))),
    snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: ink,
        shape: rounded,
        contentTextStyle:
            const TextStyle(fontFamily: 'Work Sans', color: Colors.white)),
  );
}

String money(num value) {
  final s = value.round().toString();
  return '${s.replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}đ';
}

String folded(String s) {
  const groups = {
    'a': 'àáạảãâầấậẩẫăằắặẳẵ',
    'e': 'èéẹẻẽêềếệểễ',
    'i': 'ìíịỉĩ',
    'o': 'òóọỏõôồốộổỗơờớợởỡ',
    'u': 'ùúụủũưừứựửữ',
    'y': 'ỳýỵỷỹ',
    'd': 'đ',
  };
  s = s.toLowerCase();
  groups.forEach((k, v) {
    for (final c in v.split('')) {
      s = s.replaceAll(c, k);
    }
  });
  return s;
}
