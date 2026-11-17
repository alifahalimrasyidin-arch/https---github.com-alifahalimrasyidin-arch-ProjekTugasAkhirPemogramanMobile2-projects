import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Palet utama: hijau daun sebagai warna merek, hijau hutan untuk permukaan gelap,
/// kuning panen sebagai aksen kecil.
class AppColors {
  static const primary = Color(0xFF2E7D4F);
  static const dark = Color(0xFF123524);
  static const tint = Color(0xFFE6F2EA);
  static const bg = Color(0xFFF5F8F5);
  static const ink = Color(0xFF17261E);
  static const muted = Color(0xFF5F6F66);
  static const line = Color(0xFFDCE6DF);
  static const harvest = Color(0xFFE9B44C);
  static const danger = Color(0xFFC0432F);

  // Versi tema gelap
  static const bgDark = Color(0xFF0E1A13);
  static const surfaceDark = Color(0xFF17261E);
  static const inkDark = Color(0xFFEAF2EC);
  static const mutedDark = Color(0xFF9DB0A4);
  static const lineDark = Color(0xFF2A3D32);
  static const tintDark = Color(0xFF1F3A2B);
  static const accentDark = Color(0xFF5BBE86);
}

/// Satu-satunya sumber status tema. Ubah nilainya, seluruh aplikasi ikut berganti.
final ValueNotifier<ThemeMode> themeMode = ValueNotifier(ThemeMode.light);

/// Warna yang menyesuaikan tema aktif. Pemakaian: context.ink, context.surface, dst.
extension AppContext on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
  Color get bg => isDark ? AppColors.bgDark : AppColors.bg;
  Color get surface => isDark ? AppColors.surfaceDark : Colors.white;
  Color get ink => isDark ? AppColors.inkDark : AppColors.ink;
  Color get muted => isDark ? AppColors.mutedDark : AppColors.muted;
  Color get line => isDark ? AppColors.lineDark : AppColors.line;
  Color get tint => isDark ? AppColors.tintDark : AppColors.tint;
  Color get accent => isDark ? AppColors.accentDark : AppColors.primary;
}

ThemeData buildTheme([Brightness brightness = Brightness.light]) {
  final dark = brightness == Brightness.dark;
  final bg = dark ? AppColors.bgDark : AppColors.bg;
  final surface = dark ? AppColors.surfaceDark : Colors.white;
  final ink = dark ? AppColors.inkDark : AppColors.ink;
  final line = dark ? AppColors.lineDark : AppColors.line;
  final accent = dark ? AppColors.accentDark : AppColors.primary;
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: brightness,
  ).copyWith(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    surface: surface,
    onSurface: ink,
    error: AppColors.danger,
  );
  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    scaffoldBackgroundColor: bg,
  );
  final text = GoogleFonts.plusJakartaSansTextTheme(base.textTheme)
      .apply(bodyColor: ink, displayColor: ink);

  OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: c, width: w),
      );
  final buttonShape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  return base.copyWith(
    textTheme: text,
    appBarTheme: AppBarTheme(
      backgroundColor: bg,
      foregroundColor: ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: text.titleLarge?.copyWith(fontWeight: FontWeight.w700),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: surface,
      border: border(line),
      enabledBorder: border(line),
      focusedBorder: border(AppColors.primary, 1.6),
      errorBorder: border(AppColors.danger),
      focusedErrorBorder: border(AppColors.danger, 1.6),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: buttonShape,
        textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: accent,
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    chipTheme: ChipThemeData(
      selectedColor: AppColors.primary,
      backgroundColor: surface,
      side: BorderSide(color: line),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      showCheckmark: false,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: dark ? AppColors.lineDark : AppColors.dark,
      contentTextStyle: const TextStyle(color: Colors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    dividerTheme: DividerThemeData(color: line, space: 1),
  );
}
