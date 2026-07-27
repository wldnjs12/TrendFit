import 'package:flutter/material.dart';

/// 코디 추천 요청/결과 화면 (PRD 4.2 F3, 5. 사용자 흐름 3~5단계)
/// - 자연어 요청 입력 (일반 요청 / 앵커 아이템 요청)
/// - 결과는 텍스트가 아니라 실제 보유 의류 사진으로 표시
/// - '+1 아이템' 쇼핑 링크 카드 표시
///
/// TODO(5주차): ApiService.requestRecommendation 연동, 결과 카드 UI 구현.
class RecommendationScreen extends StatefulWidget {
  const RecommendationScreen({super.key});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘 뭐 입지')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '예: 오늘 성수동 데이트, 뭐 입지? / 흰 치마인데 뭐랑 매치하지?',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                // TODO: ApiService.requestRecommendation(userId, _controller.text) 호출
              },
              child: const Text('추천받기'),
            ),
            const SizedBox(height: 24),
            const Expanded(
              child: Center(child: Text('추천 결과가 여기에 실제 옷 사진으로 표시됩니다.')),
            ),
          ],
        ),
      ),
    );
  }
}
