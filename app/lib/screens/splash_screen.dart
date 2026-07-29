import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../widgets/trendfit_mark.dart';
import 'login_screen.dart';
import 'main_tab_shell.dart';
import 'signup_info_screen.dart';

/// 스플래시 화면. (Figma "스플래시 화면") 잠깐 브랜드 워드마크를 보여준 뒤, 세션 상태에 따라
/// 분기한다: 로그인 안 됨 -> 로그인 화면, 로그인은 됐지만 온보딩 미완료(2단계 온보딩 도중
/// 새로고침/재접속 등) -> 온보딩 이어서, 둘 다 완료 -> 바로 메인 탭(회원관리 — 로그인 유지).
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(milliseconds: 1200), () {
      if (!mounted) return;
      final Widget next;
      if (!AppSession.isLoggedIn) {
        next = const LoginScreen();
      } else if (!AppSession.onboardingCompleted) {
        next = const SignupInfoScreen();
      } else {
        next = const MainTabShell();
      }
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          transitionDuration: AppMotion.slow,
          pageBuilder: (_, animation, __) => FadeTransition(opacity: animation, child: next),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          const Positioned(top: 0, left: 0, right: 0, child: Divider(color: AppColors.black, height: 1, thickness: 1)),
          const Positioned(bottom: 0, left: 0, right: 0, child: Divider(color: AppColors.black, height: 1, thickness: 1)),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TrendFitMark(size: 96, radius: 20)
                    .animate()
                    .fadeIn(duration: AppMotion.slow, curve: AppMotion.enter)
                    .scale(begin: const Offset(0.7, 0.7), end: const Offset(1, 1), duration: AppMotion.slow, curve: AppMotion.spring),
                const SizedBox(height: 20),
                Text('TRENDFIT', style: AppTextStyles.wordmark.copyWith(letterSpacing: 4, fontSize: 18))
                    .animate()
                    .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * 3)
                    .slideY(begin: 0.3, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
