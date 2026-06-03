import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'features/home/presentation/screens/main_navigation_screen.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/screens/terms_screen.dart';
import 'core/theme/app_theme.dart';

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
          home: const AuthGate(),
        );
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final user = snapshot.data;

        if (user == null) {
          // 1. 유저 정보 없음 -> 로그인 화면
          return const LoginScreen();
        }

        // 2. 유저 정보 있음 -> 약관 동의 여부 체크
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance.collection('users').doc(user.uid).get(),
          builder: (context, docSnapshot) {
            if (docSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(body: Center(child: CircularProgressIndicator()));
            }

            final data = docSnapshot.data?.data() as Map<String, dynamic>?;
            final hasAgreed = data?['hasAgreedToTerms'] ?? false;

            if (hasAgreed) {
              // 3. 동의 완료 -> 메인 화면 (자동 로그인)
              return const MainNavigationScreen();
            } else {
              // 4. 동의 미완료 -> 약관 동의 화면
              return TermsScreen(
                onAgreed: () {
                  // 동의 완료 시 상태 갱신을 위해 앱 재빌드 유도 (간단한 라우팅 트릭)
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
                  );
                },
              );
            }
          },
        );
      },
    );
  }
}
