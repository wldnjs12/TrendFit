import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

/// 온보딩/옷장등록 등 여러 단계로 이루어진 플로우에서 공통으로 쓰는 진행 표시.
/// "STEP 0N OF M" 라벨 + 도트 진행바를 한 곳에서만 관리해 화면마다 포맷이
/// 제각각이던 문제를 없앤다.
class StepIndicator extends StatelessWidget {
  const StepIndicator({super.key, required this.step, required this.total, this.label});

  /// 1부터 시작하는 현재 단계.
  final int step;
  final int total;
  /// 라벨 우측에 덧붙일 설명(예: "옷장 등록"). 없으면 생략.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final stepText = step.toString().padLeft(2, '0');
    final totalText = total.toString().padLeft(2, '0');
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('STEP $stepText', style: AppTextStyles.trackedLabelBig.copyWith(color: AppColors.textPrimary)),
        Text(' / $totalText', style: AppTextStyles.trackedLabelBig),
        if (label != null) ...[
          const SizedBox(width: 8),
          Text(label!, style: AppTextStyles.trackedLabel),
        ],
        const Spacer(),
        Row(
          children: List.generate(total, (i) {
            final active = i < step;
            return AnimatedContainer(
              duration: AppMotion.base,
              curve: AppMotion.enter,
              margin: const EdgeInsets.only(left: 4),
              width: active ? 18 : 10,
              height: 4,
              decoration: BoxDecoration(
                color: active ? AppColors.black : AppColors.textPlaceholder,
                borderRadius: BorderRadius.circular(2),
              ),
            );
          }),
        ),
      ],
    ).animate().fadeIn(duration: AppMotion.base).slideX(begin: -0.05, end: 0, duration: AppMotion.base, curve: AppMotion.enter);
  }
}
