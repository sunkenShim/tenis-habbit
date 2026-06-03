import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isLoading = false;
  bool _isAppleSignInAvailable = false;

  @override
  void initState() {
    super.initState();
    _checkAppleSignIn();
  }

  Future<void> _checkAppleSignIn() async {
    final available = await SignInWithApple.isAvailable();
    if (mounted) setState(() => _isAppleSignInAvailable = available);
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // 사용자가 취소함
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
      // 로그인 성공 후 처리는 main.dart의 authStateChanges에서 감지하여 화면 이동
    } catch (e, stackTrace) {
      debugPrint('========== GOOGLE SIGN-IN ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('==========================================');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google 로그인에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _signInWithApple() async {
    setState(() => _isLoading = true);
    try {
      final appleIdCredential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final OAuthCredential credential = OAuthProvider('apple.com').credential(
        idToken: appleIdCredential.identityToken,
        accessToken: appleIdCredential.authorizationCode,
      );

      await FirebaseAuth.instance.signInWithCredential(credential);
    } catch (e, stackTrace) {
      debugPrint('========== APPLE SIGN-IN ERROR ==========');
      debugPrint('Error: $e');
      debugPrint('StackTrace: $stackTrace');
      debugPrint('=========================================');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Apple 로그인에 실패했습니다. 다시 시도해주세요.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // 임시 로고 대체
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.sports_tennis, size: 80, color: Theme.of(context).colorScheme.onPrimary),
              ),
              const SizedBox(height: 24),
              Text(
                'TENNIS HABIT',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                '하루 30초, 성장하는 테니스 습관',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const Spacer(),
              if (_isLoading)
                const CircularProgressIndicator()
              else
                Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _signInWithGoogle,
                        icon: Container(
                          width: 22,
                          height: 22,
                          decoration: const BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: Text(
                              'G',
                              style: TextStyle(
                                color: Color(0xFF4285F4),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                        label: const Text('Google로 계속하기'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black,
                        ),
                      ),
                    ),
                    if (_isAppleSignInAvailable) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: _signInWithApple,
                          icon: const Icon(Icons.apple, size: 28),
                          label: const Text('Apple로 계속하기'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white24),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
