import 'package:flutter/material.dart';
import 'recommendation_screen.dart';

/// 옷장 등록/조회 화면 (PRD 4.2 F2, 5. 사용자 흐름 2단계)
/// - 사진 여러 장 업로드 -> Vision 자동 태깅 + 크롭
/// - 애매한 속성(핏/재질)은 스와이프 카드로 보정
///
/// TODO(3~5주차): 이미지 피커, 업로드, 스와이프 보정 카드(widgets/) 연동.
class ClosetScreen extends StatelessWidget {
  const ClosetScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 옷장')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('옷장이 비어있어요. 사진을 올려보세요.'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // TODO: 이미지 피커 -> ApiService.uploadClosetItems 연동
              },
              child: const Text('사진으로 옷 등록하기'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const RecommendationScreen()),
                );
              },
              child: const Text('오늘의 코디 추천 받기 →'),
            ),
          ],
        ),
      ),
    );
  }
}
