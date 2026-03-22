import 'package:flutter/material.dart';

class AppTheme {
  static const primary = Color(0xFF1565C0);
  static const primaryDark = Color(0xFF0D47A1);
  static const secondary = Color(0xFF00897B);
  static const background = Color(0xFFF0F4F8);
  static const surface = Colors.white;
  static const textDark = Color(0xFF0F172A);
  static const textMedium = Color(0xFF64748B);
  static const textLight = Color(0xFF94A3B8);
  static const border = Color(0xFFE2E8F0);

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primary,
          brightness: Brightness.light,
          surface: surface,
        ).copyWith(
          secondary: secondary,
          surface: background,
        ),
        scaffoldBackgroundColor: background,
        appBarTheme: const AppBarTheme(
          backgroundColor: surface,
          foregroundColor: textDark,
          elevation: 0,
          scrolledUnderElevation: 1,
          shadowColor: Color(0x1A000000),
          centerTitle: false,
          titleTextStyle: TextStyle(
            color: textDark,
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
          ),
          iconTheme: IconThemeData(color: textDark),
        ),
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: border, width: 1),
          ),
          color: surface,
          margin: EdgeInsets.zero,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: const Color(0xFFF8FAFC),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: primary, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFEF4444)),
          ),
          labelStyle: const TextStyle(color: textMedium, fontSize: 14),
          hintStyle: const TextStyle(color: textLight, fontSize: 14),
          prefixIconColor: textMedium,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            minimumSize: const Size(double.infinity, 50),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: primary,
            foregroundColor: Colors.white,
            elevation: 0,
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            textStyle: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: primary,
            side: const BorderSide(color: primary),
            padding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primary,
          foregroundColor: Colors.white,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        chipTheme: ChipThemeData(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(6),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          labelStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
        dividerTheme: const DividerThemeData(
          color: border,
          thickness: 1,
          space: 1,
        ),
        listTileTheme: const ListTileThemeData(
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        ),
        drawerTheme: const DrawerThemeData(
          backgroundColor: surface,
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(0),
              bottomRight: Radius.circular(0),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: -0.8,
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: textDark,
            letterSpacing: -0.5,
          ),
          titleLarge: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: textDark,
            letterSpacing: -0.3,
          ),
          titleMedium: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
          titleSmall: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textMedium,
          ),
          bodyLarge: TextStyle(fontSize: 15, color: textDark),
          bodyMedium: TextStyle(fontSize: 14, color: textMedium),
          bodySmall: TextStyle(fontSize: 12, color: textLight),
          labelLarge: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textDark,
          ),
        ),
      );

  // Statü renkleri — tüm ekranlarda tutarlı kullanım için
  static Color statusColor(String status) => switch (status) {
        'new' || 'scheduled' || 'sent' => const Color(0xFF3B82F6),
        'quoted' || 'in_progress' || 'draft' => const Color(0xFFF59E0B),
        'accepted' || 'completed' || 'paid' => const Color(0xFF10B981),
        'rejected' || 'overdue' || 'cancelled' => const Color(0xFFEF4444),
        _ => const Color(0xFF94A3B8),
      };

  static Color statusBg(String status) =>
      statusColor(status).withValues(alpha: 0.1);

  // Avatar rengi — isim baş harfine göre
  static Color avatarColor(String name) {
    const colors = [
      Color(0xFF3B82F6),
      Color(0xFF8B5CF6),
      Color(0xFFEC4899),
      Color(0xFFF59E0B),
      Color(0xFF10B981),
      Color(0xFF06B6D4),
      Color(0xFFF97316),
    ];
    final idx = (name.isEmpty ? 0 : name.codeUnitAt(0)) % colors.length;
    return colors[idx];
  }
}
