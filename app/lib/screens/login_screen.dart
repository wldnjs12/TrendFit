import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../services/auth_service.dart';
import 'main_tab_shell.dart';
import 'signup_info_screen.dart';

/// 로그인. (Figma "로그인 및 회원가입")
/// Figma 시안은 카카오/구글/애플 3개 버튼을 보여주지만, 백엔드 User.authProvider는
/// GOOGLE만 지원하도록 이미 결정되어 있어(open-decisions.md B3) Google 버튼만 노출한다.
/// google_sign_in으로 발급받은 액세스 토큰을 백엔드(/api/auth/google)로 보내 로그인/가입을
/// 처리하고, 응답의 onboardingCompleted 값으로 다음 화면을 분기한다.
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _loading = false;

  Future<void> _continueWithGoogle() async {
    setState(() => _loading = true);
    try {
      final result = await _authService.signInWithGoogle();
      if (!mounted) return;
      if (result == null) {
        // 사용자가 Google 로그인 팝업을 취소한 경우 — 조용히 로그인 화면에 머문다.
        return;
      }
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => result.onboardingCompleted ? const MainTabShell() : const SignupInfoScreen(),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
          child: Column(
            children: [
              Text('TRENDFIT', style: AppTextStyles.wordmark),
              const Spacer(),
              Text('WELCOME TO THE CURATED SPACE', style: AppTextStyles.trackedLabel),
              const SizedBox(height: 12),
              Text('나만의 스타일을 완성하세요', style: AppTextStyles.koreanHeadline, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(
                '로그인하여 트렌드핏의 단독 컬렉션을 만나보세요.',
                textAlign: TextAlign.center,
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _loading ? null : _continueWithGoogle,
                  icon: _loading
                      ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.g_mobiledata, size: 24),
                  label: const Text('GOOGLE로 계속하기'),
                ),
              ),
              const Spacer(),
              const Text(
                '© 2026 TRENDFIT ARCHIVE. ALL RIGHTS RESERVED.',
                style: TextStyle(color: AppColors.textPlaceholder, fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
