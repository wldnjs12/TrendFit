import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';
import 'trendfit_mark.dart';

/// Figma "Header - Top AppBar" 공통 컴포넌트. 반투명 배경 + T 마크 + TRENDFIT 워드마크.
class TrendFitTopBar extends StatelessWidget implements PreferredSizeWidget {
  const TrendFitTopBar({super.key, this.leading, this.actions, this.onBack});

  final Widget? leading;
  final List<Widget>? actions;
  final VoidCallback? onBack;

  @override
  Size get preferredSize => const Size.fromHeight(56);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xF2F9F9F9),
        border: Border(bottom: BorderSide(color: AppColors.borderHairline)),
      ),
      child: SafeArea(
        bottom: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 20),
              if (onBack != null)
                IconButton(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back, size: 18, color: AppColors.textPrimary),
                  padding: EdgeInsets.zero,
                )
              else if (leading != null)
                leading!
              else
                const TrendFitMark(size: 28, radius: 6),
              const SizedBox(width: 12),
              Text('TRENDFIT', style: AppTextStyles.wordmark),
              const Spacer(),
              if (actions != null) ...actions!,
              const SizedBox(width: 20),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: AppMotion.fast).slideY(begin: -0.3, end: 0, duration: AppMotion.fast, curve: AppMotion.enter);
  }
}
