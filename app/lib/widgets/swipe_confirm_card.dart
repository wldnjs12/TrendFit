import 'package:flutter/material.dart';

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
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(imageUrl, height: 240, fit: BoxFit.cover),
            ),
            const SizedBox(height: 16),
            Text(question, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                IconButton.filledTonal(
                  onPressed: onReject,
                  icon: const Icon(Icons.close),
                ),
                IconButton.filled(
                  onPressed: onConfirm,
                  icon: const Icon(Icons.check),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
