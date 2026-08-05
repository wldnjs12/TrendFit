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
  static const _calendarIndex = 2;

  int _index = 0;
  // 로그인 직후 홈만 보고 있어도 옷장/캘린더/프로필의 initState 네트워크 호출이 전부 동시에
  // 발동해 홈이 필요로 하는 대역폭과 경쟁하던 문제가 있었다 — 방문한 탭만 실제로 마운트한다.
  final Set<int> _visitedTabs = {0};
  final _calendarKey = GlobalKey<CalendarScreenState>();

  late final List<Widget> _screens = [
    const HomeScreen(),
    const ClosetScreen(),
    CalendarScreen(key: _calendarKey),
    const ProfileScreen(),
  ];

  void _onTap(int value) {
    setState(() {
      _index = value;
      _visitedTabs.add(value);
    });
    // 4개 탭 모두 계속 마운트돼 있는 채로 opacity만 바뀌는 구조라(아래 주석 참고),
    // 다른 탭(홈)에서 추천을 확정해도 캘린더 탭은 그 갱신을 모른다. 캘린더 탭으로
    // 들어올 때마다 이력을 다시 불러와 "새로고침해야 반영되는" 문제를 없앤다.
    if (value == _calendarIndex) {
      _calendarKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // IndexedStack 대신 방문한 탭을 계속 마운트해둔 채 opacity만 애니메이션한다 —
      // 탭을 넘나들 때 각 화면(검색 결과, 스크롤 위치 등)의 상태는 그대로 유지하면서
      // 전환에는 자연스러운 크로스페이드를 준다. 아직 방문 안 한 탭은 아예 마운트하지 않는다.
      body: Stack(
        children: List.generate(_screens.length, (i) {
          if (!_visitedTabs.contains(i)) {
            return const SizedBox.shrink();
          }
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
        onTap: _onTap,
      ),
    );
  }
}
