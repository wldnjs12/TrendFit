import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/user_preference.dart';
import '../services/api_service.dart';
import 'onboarding_screen.dart';

/// 프로필 화면 (CLAUDE.md §4) — 취향 태그 조회/재설정.
/// 로그인/회원가입(Google OAuth2)이 아직 없어 계정 관리 UI는 자리만 잡아둔다.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  late Future<UserPreference> _preferenceFuture;

  @override
  void initState() {
    super.initState();
    _preferenceFuture = _apiService.fetchOnboarding(AppConfig.currentUserId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('프로필')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<UserPreference>(
          future: _preferenceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('아직 온보딩을 완료하지 않았어요.\n${snapshot.error}', textAlign: TextAlign.center),
              );
            }

            final preference = snapshot.data!;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('내 스타일 취향', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: preference.styleTags.map((tag) => Chip(label: Text(tag))).toList(),
                ),
                if (preference.bodyInfo != null && preference.bodyInfo!.isNotEmpty) ...[
                  const SizedBox(height: 24),
                  Text('체형 정보', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(preference.bodyInfo!),
                ],
                const SizedBox(height: 32),
                OutlinedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const OnboardingScreen()),
                    );
                  },
                  child: const Text('취향 다시 설정하기'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
