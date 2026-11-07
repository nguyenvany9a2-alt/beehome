import 'package:flutter/material.dart';

const honey = Color(0xFFF4BE43),
    ink = Color(0xFF173A35),
    cream = Color(0xFFFAF9F4),
    muted = Color(0xFF687873);
ThemeData beeTheme() => ThemeData(
  useMaterial3: true,
  scaffoldBackgroundColor: cream,
  colorScheme: ColorScheme.fromSeed(
    seedColor: ink,
    primary: ink,
    secondary: honey,
    surface: Colors.white,
  ),
  fontFamily: 'Arial',
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 42,
      fontWeight: FontWeight.w800,
      color: ink,
      height: 1.15,
    ),
    headlineMedium: TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    titleLarge: TextStyle(
      fontSize: 21,
      fontWeight: FontWeight.w700,
      color: ink,
    ),
    bodyMedium: TextStyle(fontSize: 15, color: ink, height: 1.5),
  ),
  inputDecorationTheme: InputDecorationTheme(
    filled: true,
    fillColor: Colors.white,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE4DE)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFDDE4DE)),
    ),
    contentPadding: const EdgeInsets.all(16),
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 19),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 17),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
  ),
);
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
