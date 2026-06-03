import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 테니스 공 네온 옐로우
  static const Color tennisNeon = Color(0xFFCCFF00);
  
  // 하드코트 일렉트릭 블루
  static const Color hardcourtBlue = Color(0xFF0052FF);
  
  // 깊은 어두운 배경색 (야간 경기장 느낌)
  static const Color nightBackground = Color(0xFF0F172A);
  
  // 카드 및 표면 색상 (배경보다 살짝 밝은 어두운 색)
  static const Color surfaceDark = Color(0xFF1E293B);

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: nightBackground,
      colorScheme: const ColorScheme.dark(
        primary: tennisNeon,
        secondary: hardcourtBlue,
        surface: surfaceDark,
        background: nightBackground,
        onPrimary: Colors.black, // 네온 배경 위엔 검은 글씨
        onBackground: Colors.white,
        onSurface: Colors.white,
      ),
      // 폰트 설정 (추후 pubspec.yaml에 google_fonts 추가 필요)
      textTheme: GoogleFonts.manropeTextTheme(ThemeData.dark().textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: nightBackground,
        elevation: 0,
        centerTitle: false,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: tennisNeon,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: tennisNeon,
          foregroundColor: Colors.black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: tennisNeon,
        inactiveTrackColor: surfaceDark.withOpacity(0.5),
        thumbColor: tennisNeon,
        overlayColor: tennisNeon.withOpacity(0.2),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surfaceDark,
        selectedColor: hardcourtBlue.withOpacity(0.3),
        labelStyle: const TextStyle(color: Colors.white70),
        secondaryLabelStyle: const TextStyle(color: hardcourtBlue, fontWeight: FontWeight.bold),
        side: BorderSide(color: Colors.grey.shade800),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceDark,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: tennisNeon, width: 1.5),
        ),
        hintStyle: TextStyle(color: Colors.grey.shade500),
      ),
    );
  }
}
