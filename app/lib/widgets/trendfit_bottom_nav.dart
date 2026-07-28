import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Figma "Bottom Navigation Bar" 4탭: 홈 · 옷장 · 캘린더 · 프로필.
/// (CLAUDE.md §4 — 3탭 원칙에서 Figma 디자인 확정으로 캘린더 탭이 승격됨, 2026-07-28)
class TrendFitBottomNav extends StatelessWidget {
  const TrendFitBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const _items = [
    (icon: Icons.home_outlined, activeIcon: Icons.home, label: 'HOME'),
    (icon: Icons.checkroom_outlined, activeIcon: Icons.checkroom, label: 'CLOSET'),
    (icon: Icons.calendar_today_outlined, activeIcon: Icons.calendar_today, label: 'CALENDAR'),
    (icon: Icons.person_outline, activeIcon: Icons.person, label: 'PROFILE'),
  ];

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.black)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(_items.length, (index) {
              final item = _items[index];
              final active = index == currentIndex;
              final color = active ? AppColors.black : AppColors.textTertiary;
              return InkWell(
                onTap: () => onTap(index),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(active ? item.activeIcon : item.icon, size: 20, color: color),
                      const SizedBox(height: 4),
                      Text(
                        item.label,
                        style: AppTextStyles.trackedLabel.copyWith(color: color),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
