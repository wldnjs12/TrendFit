import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_theme.dart';

/// Claude 호출(옷 등록 태깅, 추천 생성)은 수 초가 걸린다. 그냥 스피너만 보여주면 멈춘 것처럼
/// 느껴진다는 피드백이 있어, "AI가 분석 중" 문구 + 순차로 깜빡이는 점 3개로 "지금 진행 중"임을
/// 명확히 전달하는 공용 위젯. 버튼 안(compact)과 화면 전체(라벨 포함) 두 곳에서 재사용한다.
class AiLoadingIndicator extends StatelessWidget {
  const AiLoadingIndicator({
    super.key,
    this.label,
    this.color = AppColors.white,
    this.dotSize = 6,
  });

  /// 점 옆에 붙일 문구. null이면 점만 표시(버튼 내부용).
  final String? label;
  final Color color;
  final double dotSize;

  @override
  Widget build(BuildContext context) {
    final dots = Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) => _buildDot(i)),
    );

    if (label == null) {
      return dots;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label!, style: AppTextStyles.body.copyWith(color: color, fontSize: 14)),
        const SizedBox(width: 8),
        dots,
      ],
    );
  }

  Widget _buildDot(int index) {
    return Padding(
      padding: EdgeInsets.only(left: index == 0 ? 0 : dotSize * 0.6),
      child: Container(
        width: dotSize,
        height: dotSize,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      )
          .animate(onPlay: (controller) => controller.repeat(), delay: Duration(milliseconds: index * 160))
          .fadeIn(duration: const Duration(milliseconds: 420), curve: Curves.easeInOut)
          .then()
          .fadeOut(duration: const Duration(milliseconds: 420), curve: Curves.easeInOut),
    );
  }
}

/// 히어로 카드처럼 넓은 영역이 처리 중임을 알리는 셔머(그라디언트 스윕) 오버레이.
class ShimmerOverlay extends StatefulWidget {
  const ShimmerOverlay({super.key});

  @override
  State<ShimmerOverlay> createState() => _ShimmerOverlayState();
}

class _ShimmerOverlayState extends State<ShimmerOverlay> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            final dx = _controller.value * 2 - 0.5;
            return LinearGradient(
              begin: Alignment(-1 + dx * 2, -0.3),
              end: Alignment(1 + dx * 2, 0.3),
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.22),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(bounds);
          },
          child: Container(color: AppColors.black.withValues(alpha: 0.12)),
        );
      },
    );
  }
}
