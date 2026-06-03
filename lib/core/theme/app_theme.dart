import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum AppThemeType {
  australianOpen, // 1월 (블루 & 옐로우)
  frenchOpen,     // 5월 (클레이 & 그린)
  wimbledon,      // 7월 (그린 & 골드)
  usOpen,         // 8월 (다크 & 네온)
  minimalist,     // 무채색
}

class AppTheme {
  static ThemeData getTheme(AppThemeType type) {
    switch (type) {
      case AppThemeType.australianOpen:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF0072CE),
          secondary: const Color(0xFFE0FF00),
          background: const Color(0xFFE6F2FF),
          surface: Colors.white,
          fontFamily: GoogleFonts.manropeTextTheme(ThemeData.light().textTheme),
          borderRadius: 16.0,
        );

      case AppThemeType.frenchOpen:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFFC35332), // Terracotta
          secondary: const Color(0xFF6B8E23), // Olive
          background: const Color(0xFFFDF5E6), // Warm Beige
          surface: Colors.white,
          fontFamily: GoogleFonts.loraTextTheme(ThemeData.light().textTheme),
          borderRadius: 12.0,
        );

      case AppThemeType.wimbledon:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF006633),
          secondary: const Color(0xFFD4AF37), // Gold
          background: const Color(0xFFF5F7F5),
          surface: Colors.white,
          fontFamily: GoogleFonts.playfairDisplayTextTheme(ThemeData.light().textTheme),
          borderRadius: 8.0,
        ).copyWith(
          cardTheme: CardThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8.0),
              side: BorderSide(color: Colors.grey.shade300),
            ),
            elevation: 0,
            color: Colors.white,
          ),
        );

      case AppThemeType.usOpen: // Hardcourt Night
        return _buildTheme(
          brightness: Brightness.dark,
          primary: const Color(0xFFCCFF00), // Neon Yellow
          secondary: const Color(0xFF0052FF), // Electric Blue
          background: const Color(0xFF0F172A), // Night
          surface: const Color(0xFF1E293B),
          fontFamily: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
          borderRadius: 16.0,
        ).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFCCFF00),
            secondary: Color(0xFF0052FF),
            surface: Color(0xFF1E293B),
            background: Color(0xFF0F172A),
            onPrimary: Colors.black,
            onBackground: Colors.white,
            onSurface: Colors.white,
          ),
        );

      case AppThemeType.minimalist:
        return _buildTheme(
          brightness: Brightness.light,
          primary: const Color(0xFF222222),
          secondary: const Color(0xFF00E676), // Mint
          background: Colors.grey.shade50,
          surface: Colors.white,
          fontFamily: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
          borderRadius: 0.0,
        ).copyWith(
          appBarTheme: const AppBarTheme(
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            elevation: 0,
          ),
          cardTheme: const CardThemeData(
            color: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(),
          ),
        );
    }
  }

  static ThemeData _buildTheme({
    required Brightness brightness,
    required Color primary,
    required Color secondary,
    required Color background,
    required Color surface,
    required TextTheme fontFamily,
    required double borderRadius,
  }) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: primary,
      brightness: brightness,
      primary: primary,
      secondary: secondary,
      surface: surface,
      background: background,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: background,
      colorScheme: colorScheme,
      textTheme: fontFamily,
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: colorScheme.onBackground,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: colorScheme.onBackground,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: brightness == Brightness.dark ? 4 : 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadius),
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        selectedColor: secondary.withOpacity(0.2),
        secondaryLabelStyle: TextStyle(color: secondary, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(borderRadius)),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: primary,
        thumbColor: primary,
      ),
    );
  }

  static String getThemeName(AppThemeType type) {
    switch (type) {
      case AppThemeType.australianOpen: return 'Australian Open (Blue/Light)';
      case AppThemeType.frenchOpen: return 'Roland Garros (Clay/Warm)';
      case AppThemeType.wimbledon: return 'Wimbledon (Green/Classic)';
      case AppThemeType.usOpen: return 'US Open Night (Dark/Neon)';
      case AppThemeType.minimalist: return 'Minimalist (B&W/Flat)';
    }
  }
}
