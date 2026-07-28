import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../config/style_tags.dart';
import '../services/api_service.dart';
import '../widgets/step_indicator.dart';
import '../widgets/trendfit_top_bar.dart';
import 'main_tab_shell.dart';

/// 취향 선택 (STEP 02). (Figma "취향 선택 및 권한 설정")
/// 승인된 12개 태그 어휘집(open-decisions.md A7, 2026-07-27 결정)을 유지하며, Figma의 포토카드
/// 그리드 스타일대로 태그별 무드보드 사진(kStyleTagImages, 임시 예시 이미지)을 보여준다.
/// 네트워크 이미지가 실패하면 고정 톤 블록으로 폴백한다.
///
/// 최초 온보딩([initialTags]가 null)에서는 완료 시 [MainTabShell]로 진입하고,
/// 프로필의 "취향 재설정"([initialTags]가 있는 경우)에서는 완료 시 이전 화면으로 pop(true)한다.
class StylePreferenceScreen extends StatefulWidget {
  const StylePreferenceScreen({super.key, this.initialTags, this.initialBodyInfo});

  final List<String>? initialTags;
  final String? initialBodyInfo;

  bool get _isReconfigure => initialTags != null;

  @override
  State<StylePreferenceScreen> createState() => _StylePreferenceScreenState();
}

class _StylePreferenceScreenState extends State<StylePreferenceScreen> {
  static const _cardTones = [
    Color(0xFF2B2B2B), Color(0xFF6B5B4F), Color(0xFF8A7E72), Color(0xFF4A5D52),
    Color(0xFF7A6A6A), Color(0xFF3E3A36), Color(0xFF5B5347), Color(0xFF6F6259),
    Color(0xFF44403A), Color(0xFF8C7B6B), Color(0xFF524F4C), Color(0xFF615C52),
  ];

  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  late final TextEditingController _bodyInfoController =
      TextEditingController(text: widget.initialBodyInfo ?? '');
  late final Set<String> _selectedTags = {...?widget.initialTags};
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
        AppSession.userId!,
        _selectedTags.toList(),
        _bodyInfoController.text.trim().isEmpty ? null : _bodyInfoController.text.trim(),
      );
      if (!mounted) return;
      if (widget._isReconfigure) {
        Navigator.of(context).pop(true);
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const MainTabShell()),
        );
      }
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
      appBar: TrendFitTopBar(onBack: () => Navigator.of(context).pop()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (widget._isReconfigure)
                Text('취향 재설정', style: AppTextStyles.trackedLabelBig.copyWith(color: AppColors.textPrimary))
              else
                const StepIndicator(step: 2, total: 2, label: '스타일 취향'),
              const SizedBox(height: 8),
              Text('당신의 스타일 취향을\n선택해주세요', style: AppTextStyles.displayHeavy.copyWith(fontSize: 26))
                  .animate()
                  .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger)
                  .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 12),
              Text(
                '선택하신 스타일을 바탕으로 오늘 날씨와 트렌드에 맞는 최적의 코디를 제안해드립니다 (최소 1개 선택)',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 1.1,
                ),
                itemCount: kStyleTags.length,
                itemBuilder: (context, index) {
                  final tag = kStyleTags[index];
                  final selected = _selectedTags.contains(tag);
                  return _tagCard(tag, _cardTones[index % _cardTones.length], selected)
                      .animate()
                      .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * index)
                      .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), duration: AppMotion.base, curve: AppMotion.enter);
                },
              ),
              const SizedBox(height: 4),
              Text(
                '* 사진은 스타일 무드 참고용 예시 이미지입니다.',
                style: TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.7), fontSize: 11),
              ),
              const SizedBox(height: 32),
              Text('체형 정보 (선택)', style: AppTextStyles.trackedLabel.copyWith(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              TextField(
                controller: _bodyInfoController,
                decoration: const InputDecoration(hintText: '예: 상체가 발달한 편, 키 170cm 등'),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('NEXT'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tagCard(String tag, Color tone, bool selected) {
    return InkWell(
      onTap: () => setState(() {
        if (selected) {
          _selectedTags.remove(tag);
        } else {
          _selectedTags.add(tag);
        }
      }),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
        fit: StackFit.expand,
        children: [
          DecoratedBox(decoration: BoxDecoration(color: tone)),
          if (kStyleTagImages[tag] != null)
            Image.network(
              kStyleTagImages[tag]!,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null ? child : const SizedBox.shrink(),
              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
            ),
          AnimatedContainer(
            duration: AppMotion.fast,
            curve: AppMotion.enter,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withValues(alpha: 0.35)],
              ),
              border: selected ? Border.all(color: AppColors.white, width: 2) : null,
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Text(
              tag.toUpperCase(),
              style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 15),
            ),
          ),
          Positioned(
            top: 8,
            right: 8,
            child: AnimatedScale(
              scale: selected ? 1 : 0,
              duration: AppMotion.fast,
              curve: AppMotion.spring,
              child: const Icon(Icons.check_circle, color: AppColors.white, size: 20),
            ),
          ),
        ],
        ),
      ),
    );
  }
}
