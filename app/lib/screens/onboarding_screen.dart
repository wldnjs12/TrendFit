import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/style_tags.dart';
import '../services/api_service.dart';
import 'main_tab_shell.dart';

/// 온보딩 화면 (PRD 4.2, architecture.md §3 "1. 온보딩")
/// - 스타일 취향 선택(최소 1개 이상 필수, 다중 선택)
/// - 체형 정보 입력(선택)
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final TextEditingController _bodyInfoController = TextEditingController();
  final Set<String> _selectedTags = {};
  bool _submitting = false;

  @override
  void dispose() {
    _bodyInfoController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedTags.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('스타일 취향을 최소 1개 이상 선택해주세요.')),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      await _apiService.submitOnboarding(
        AppConfig.currentUserId,
        _selectedTags.toList(),
        _bodyInfoController.text.trim().isEmpty ? null : _bodyInfoController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainTabShell()),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('TrendFit', style: Theme.of(context).textTheme.headlineMedium),
              const SizedBox(height: 12),
              const Text('요즘 유행을, 내 옷장으로.'),
              const SizedBox(height: 32),
              const Text('좋아하는 스타일을 골라주세요 (여러 개 선택 가능)',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: kStyleTags.map((tag) {
                  final selected = _selectedTags.contains(tag);
                  return FilterChip(
                    label: Text(tag),
                    selected: selected,
                    onSelected: (value) {
                      setState(() {
                        if (value) {
                          _selectedTags.add(tag);
                        } else {
                          _selectedTags.remove(tag);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              const Text('체형 정보 (선택)', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyInfoController,
                decoration: const InputDecoration(
                  hintText: '예: 상체가 발달한 편, 키 170cm 등',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 32),
              const Text('옷장을 다 채우지 않아도 돼요.\n몇 벌만 올려도 바로 시작할 수 있어요.'),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Text('시작하기'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
