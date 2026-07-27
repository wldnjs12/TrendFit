import 'package:flutter/material.dart';
import 'closet_screen.dart';

/// 온보딩 화면 (PRD 4.2, 5. 사용자 흐름 1단계)
/// - 회원가입
/// - 스타일 이미지 선택 -> 취향 태그 생성
/// - "몇 벌만 올려도 됩니다" 안내로 등록 부담을 낮춤
///
/// TODO(5주차): 실제 스타일 이미지 선택 UI와 UserPreference 저장 API 연동.
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TrendFit', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text('요즘 유행을, 내 옷장으로.'),
              const SizedBox(height: 32),
              const Text('옷장을 다 채우지 않아도 돼요.\n몇 벌만 올려도 바로 시작할 수 있어요.'),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  // TODO: 스타일 취향 선택 플로우 이후 옷장 등록으로 이동
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ClosetScreen()),
                  );
                },
                child: const Text('시작하기'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
