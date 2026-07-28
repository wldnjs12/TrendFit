import 'package:flutter/material.dart';
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
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: TrendFitBottomNav(
        currentIndex: _index,
        onTap: (value) => setState(() => _index = value),
      ),
    );
  }
}
