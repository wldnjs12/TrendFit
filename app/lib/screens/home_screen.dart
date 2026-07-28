import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/recommendation_result.dart';
import '../services/api_service.dart';

/// 홈 = 오늘의 코디. (CLAUDE.md §4)
/// 켜자마자 날씨+트렌드 기반 추천을 받을 수 있는 입력창을 보여준다.
/// "오늘 뭐 입지?" 같은 일반 요청과 "흰 치마인데 뭐랑 매치하지?" 같은
/// 앵커 아이템 요청을 같은 입력창에서 자연어로 받는다(PRD 4.2 F3).
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final TextEditingController _controller = TextEditingController();
  bool _loading = false;
  String? _errorMessage;
  RecommendationResult? _result;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _requestRecommendation() async {
    final requestText = _controller.text.trim();
    if (requestText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('오늘 뭐 입을지, 또는 매치하고 싶은 아이템을 입력해주세요.')),
      );
      return;
    }

    setState(() {
      _loading = true;
      _errorMessage = null;
    });
    try {
      final result = await _apiService.requestRecommendation(AppConfig.currentUserId, requestText);
      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오늘의 코디')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              decoration: const InputDecoration(
                hintText: '예: 오늘 성수동 데이트, 뭐 입지? / 흰 치마인데 뭐랑 매치하지?',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _requestRecommendation(),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _loading ? null : _requestRecommendation,
              child: _loading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('추천받기'),
            ),
            const SizedBox(height: 16),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
      );
    }

    final result = _result;
    if (result == null) {
      return const Center(child: Text('추천 결과가 여기에 실제 옷 사진으로 표시됩니다.'));
    }

    return ListView(
      children: [
        if (result.stylingNote != null) ...[
          Text(result.stylingNote!, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 16),
        ],
        if (result.items.isEmpty)
          const Text('추천할 조합을 찾지 못했어요. 옷장을 더 채워보세요.')
        else
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: result.items.map((item) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: item.croppedImagePath == null
                    ? Container(
                        width: 120,
                        height: 160,
                        color: Colors.grey.shade200,
                        alignment: Alignment.center,
                        child: Text(item.category),
                      )
                    : Image.network(
                        _apiService.imageUrl(item.croppedImagePath!),
                        width: 120,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
              );
            }).toList(),
          ),
        if (result.plusOne != null) ...[
          const SizedBox(height: 24),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('+1 아이템 제안', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  Text(result.plusOne!.itemName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  if (result.plusOne!.reason != null) Text(result.plusOne!.reason!),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
