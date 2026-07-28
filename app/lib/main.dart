import 'package:flutter/material.dart';
import 'config/app_session.dart';
import 'config/app_theme.dart';
import 'screens/splash_screen.dart';

/// TrendFit 앱 진입점. (Figma 디자인 동기화, 2026-07-28)
/// 로컬에 저장된 로그인 세션(JWT)을 먼저 복원한 뒤 앱을 띄운다 — 그래야 스플래시가
/// "로그인 유지 여부"를 바로 판단해 로그인 화면을 건너뛸 수 있다.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppSession.load();
  runApp(const TrendFitApp());
}

class TrendFitApp extends StatelessWidget {
  const TrendFitApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrendFit',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      builder: (context, child) => _MobileWidthWrapper(child: child),
    );
  }
}

/// 웹에서 화면이 모바일 폭 그대로 늘어나 보이는 문제를 막는 래퍼.
/// (docs/architecture.md §4 배포 구성 — 최대 폭 컨테이너 + 중앙 정렬 + 여백 배경)
class _MobileWidthWrapper extends StatelessWidget {
  const _MobileWidthWrapper({required this.child});

  final Widget? child;

  static const _maxWidth = 430.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFFE5E5E5),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: _maxWidth),
          child: child,
        ),
      ),
    );
  }
}
