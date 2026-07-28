import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// 옷장 등록 시 핏/재질처럼 AI가 확신하지 못하는 속성을
/// 틴더 스타일 스와이프로 1~2초 만에 보정하는 카드. (PRD 4.2 F2)
///
/// 오른쪽 스와이프(또는 확인 버튼) = 제안된 속성 확정
/// 왼쪽 스와이프(또는 거절 버튼) = 다음 후보 속성으로 재질문
///
/// TODO(3주차): Dismissible 또는 제스처 기반 스와이프 애니메이션 구현.
class SwipeConfirmCard extends StatelessWidget {
  const SwipeConfirmCard({
    super.key,
    required this.imageUrl,
    required this.question,
    required this.onConfirm,
    required this.onReject,
  });

  final String imageUrl;
  final String question; // 예: "이 옷 오버핏 맞아요?"
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRect(
              child: Image.network(imageUrl, height: 280, fit: BoxFit.cover),
            ),
            const SizedBox(height: 20),
            Text(question, style: AppTextStyles.koreanHeadline.copyWith(fontSize: 18)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton(
                  onPressed: onReject,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.chipBackground,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.close, color: AppColors.textPrimary),
                ),
                IconButton(
                  onPressed: onConfirm,
                  style: IconButton.styleFrom(
                    backgroundColor: AppColors.black,
                    shape: const RoundedRectangleBorder(),
                    padding: const EdgeInsets.all(16),
                  ),
                  icon: const Icon(Icons.check, color: AppColors.white),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
