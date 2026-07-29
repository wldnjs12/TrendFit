import 'package:flutter/material.dart';

import '../config/app_theme.dart';

/// 상의/하의(+아우터 등) 여러 벌로 구성된 코디를 한 칸에 모두 보여주는 모자이크.
/// 이미지 1장이면 그대로 채우고, 여러 장이면 2열로 나눠 세트 전체가 보이게 한다.
/// (캘린더/위클리 리포트에서 추천 코디의 첫 번째 아이템만 보이던 문제 수정.)
class OutfitMosaic extends StatelessWidget {
  const OutfitMosaic({super.key, required this.imageUrls});

  final List<String> imageUrls;

  @override
  Widget build(BuildContext context) {
    if (imageUrls.isEmpty) return const SizedBox.shrink();
    // BoxFit.cover는 타일 비율과 안 맞는(세로로 긴) 사진의 위아래를 잘라내 옷 일부만 보이게
    // 만든다 — 옷 전체가 항상 보이도록 contain으로 채운다.
    if (imageUrls.length == 1) {
      return ColoredBox(color: AppColors.chipBackground, child: Image.network(imageUrls.single, fit: BoxFit.contain));
    }
    final rows = <Widget>[];
    for (var i = 0; i < imageUrls.length; i += 2) {
      final rowUrls = imageUrls.sublist(i, i + 2 > imageUrls.length ? imageUrls.length : i + 2);
      if (rows.isNotEmpty) rows.add(const SizedBox(height: 2));
      rows.add(Expanded(
        child: Row(
          children: [
            for (var j = 0; j < rowUrls.length; j++) ...[
              if (j > 0) const SizedBox(width: 2),
              Expanded(
                child: ColoredBox(
                  color: AppColors.chipBackground,
                  child: Image.network(rowUrls[j], fit: BoxFit.contain),
                ),
              ),
            ],
          ],
        ),
      ));
    }
    return Column(children: rows);
  }
}
