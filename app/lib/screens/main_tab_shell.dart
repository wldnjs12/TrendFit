import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import 'calendar_screen.dart';
import 'closet_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';
import '../widgets/trendfit_bottom_nav.dart';

/// 온보딩 이후 진입하는 메인 화면. 하단 네비게이션 4탭: 홈 · 옷장 · 캘린더 · 프로필
/// (CLAUDE.md §4 — Figma 디자인 확정으로 3탭 원칙에서 캘린더 탭이 승격됨, 2026-07-28).
class MainTabShell extends StatefulWidget {
  const MainTabShell({super.key});

  @override
  State<MainTabShell> createState() => _MainTabShellState();
}

class _MainTabShellState extends State<MainTabShell> {
  int _index = 0;

  static const _screens = [
    HomeScreen(),
    ClosetScreen(),
    CalendarScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack 대신 전 탭을 계속 마운트해둔 채 opacity만 애니메이션한다 —
      // 탭을 넘나들 때 각 화면(검색 결과, 스크롤 위치 등)의 상태는 그대로 유지하면서
      // 전환에는 자연스러운 크로스페이드를 준다.
      body: Stack(
        children: List.generate(_screens.length, (i) {
          final active = i == _index;
          return IgnorePointer(
            ignoring: !active,
            child: AnimatedOpacity(
              opacity: active ? 1 : 0,
              duration: AppMotion.base,
              curve: AppMotion.enter,
              child: _screens[i],
            ),
          );
        }),
      ),
      bottomNavigationBar: TrendFitBottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
