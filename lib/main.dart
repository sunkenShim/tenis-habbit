import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';
import 'core/theme/app_theme.dart';

// 전역 테마 상태 관리
final themeNotifier = ValueNotifier<AppThemeType>(AppThemeType.usOpen);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<AppThemeType>(
      valueListenable: themeNotifier,
      builder: (context, currentThemeType, child) {
        return MaterialApp(
          title: 'Tennis Habit',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getTheme(currentThemeType),
          home: const MainNavigationScreen(),
        );
      },
    );
  }
}
