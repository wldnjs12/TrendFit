import 'package:flutter/material.dart';
import 'screens/onboarding_screen.dart';

/// TrendFit 앱 진입점.
///
/// 실제 화면 구현은 5주차(PRD 10. 개발 로드맵) 작업 범위이며,
/// 현재는 온보딩 화면으로 진입하는 뼈대만 구성되어 있다.
void main() {
  runApp(const TrendFitApp());
}

class TrendFitApp extends StatelessWidget {
  const TrendFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrendFit',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorSchemeSeed: const Color(0xFF2B6CB0),
        useMaterial3: true,
      ),
      home: const OnboardingScreen(),
    );
  }
}
