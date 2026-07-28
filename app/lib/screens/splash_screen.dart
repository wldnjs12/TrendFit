import 'dart:async';
import 'package:flutter/material.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import 'login_screen.dart';
import 'main_tab_shell.dart';

/// 스플래시 화면. (Figma "스플래시 화면") 잠깐 브랜드 워드마크를 보여준 뒤, 저장된 로그인
/// 세션이 있으면 바로 메인 탭으로, 없으면 로그인 화면으로 넘어간다(회원관리 — 로그인 유지).
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
      final next = AppSession.isLoggedIn ? const MainTabShell() : const LoginScreen();
      Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => next));
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
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
              child: FittedBox(
                fit: BoxFit.fill,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Text(
                    'TRENDFIT',
                    style: AppTextStyles.wordmark.copyWith(fontWeight: FontWeight.w700, letterSpacing: -2),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
