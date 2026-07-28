import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/app_theme.dart';

/// 검은 사각형 배경 + 흰색 "T" 글자 하나로 이루어진 앱 로고 마크.
/// (web/icons, web/favicon.png와 동일한 컨셉을 Flutter 위젯으로도 재사용)
class TrendFitMark extends StatelessWidget {
  const TrendFitMark({super.key, this.size = 40, this.dark = true, this.radius});

  final double size;
  /// true면 검은 배경 + 흰 T, false면 흰 배경 + 검은 T.
  final bool dark;
  final double? radius;

  @override
  Widget build(BuildContext context) {
    final bg = dark ? AppColors.black : AppColors.white;
    final fg = dark ? AppColors.white : AppColors.black;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(radius ?? size * 0.22),
        border: dark ? null : Border.all(color: AppColors.black, width: 1),
      ),
      child: Text(
        'T',
        style: GoogleFonts.syne(
          fontWeight: FontWeight.w800,
          fontSize: size * 0.56,
          height: 1,
          color: fg,
        ),
      ),
    );
  }
}
