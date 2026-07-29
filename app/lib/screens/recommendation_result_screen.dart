import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/recommendation_result.dart';
import '../services/api_service.dart';
import '../widgets/trendfit_top_bar.dart';

/// AI 추천 결과 상세. (Figma "AI 추천: 내 옷장 풀 코디" / "AI 추천: 스타일 업그레이드")
/// 두 프레임은 시각적으로 다르지만 데이터 계약은 동일한 [RecommendationResult]이므로,
/// plusOne 유무로 두 모드를 한 화면에서 분기한다 — plusOne이 없으면 옷장 안에서 완결되는
/// "풀 코디", 있으면 +1 아이템까지 포함한 "스타일 업그레이드".
///
/// "오늘의 코디로 결정하기"를 눌러야만 캘린더에 기록된다(ApiService.confirmRecommendation) —
/// 그냥 뒤로 가거나 "다른 옵션 추천받기"를 누르면 이 요청은 캘린더에 남지 않는다.
class RecommendationResultScreen extends StatefulWidget {
  const RecommendationResultScreen({super.key, required this.result});

  final RecommendationResult result;

  @override
  State<RecommendationResultScreen> createState() => _RecommendationResultScreenState();
}

class _RecommendationResultScreenState extends State<RecommendationResultScreen> {
  static const _categoryLabels = {
    'TOP': '상의',
    'BOTTOM': '하의',
    'OUTER': '아우터',
    'DRESS': '원피스',
    'SHOES': '신발',
    'ACCESSORY': '액세서리',
  };

  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  bool _confirming = false;

  RecommendationResult get result => widget.result;

  bool get _isUpgrade => result.plusOne != null;

  Future<void> _confirmAndClose() async {
    setState(() => _confirming = true);
    try {
      await _apiService.confirmRecommendation(AppSession.userId!, result.logId);
      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('캘린더 저장에 실패했어요: $e')),
      );
      setState(() => _confirming = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final apiService = _apiService;
    return Scaffold(
      appBar: TrendFitTopBar(onBack: () => Navigator.of(context).pop()),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeading()
                  .animate()
                  .fadeIn(duration: AppMotion.base)
                  .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 24),
              _buildInsightBox()
                  .animate()
                  .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger)
                  .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 40),
              const Text('MY CLOSET', style: TextStyle(color: AppColors.textTertiary, fontSize: 14, letterSpacing: 1.6)),
              const SizedBox(height: 16),
              ...result.items.asMap().entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 24),
                    child: _itemCard(apiService, entry.value)
                        .animate()
                        .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * (2 + entry.key))
                        .slideY(begin: 0.06, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
                  )),
              if (_isUpgrade) ...[
                const SizedBox(height: 8),
                _buildPlusOneCard()
                    .animate()
                    .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * (2 + result.items.length))
                    .slideY(begin: 0.06, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              ],
              const SizedBox(height: 40),
              const Divider(color: AppColors.borderSubtle, height: 1),
              const SizedBox(height: 32),
              Center(
                child: Text('READY TO WEAR?', style: AppTextStyles.trackedLabel.copyWith(letterSpacing: 3.2)),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _confirming ? null : _confirmAndClose,
                  child: _confirming
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('오늘의 코디로 결정하기'),
                ),
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: _confirming ? null : () => Navigator.of(context).pop(),
                  child: const Text('다른 옵션 추천받기', style: TextStyle(color: AppColors.textPrimary)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeading() {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.black))),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isUpgrade ? 'AI 추천: 스타일 업그레이드' : 'AI 추천: 내 옷장 풀 코디',
              style: AppTextStyles.displayHeavy.copyWith(fontSize: 28),
            ),
            const SizedBox(height: 4),
            Text('EDITION NO. ${result.logId.toString().padLeft(3, '0')}',
                style: const TextStyle(color: AppColors.textTertiary, fontSize: 16)),
          ],
        ),
      ),
    );
  }

  Widget _buildInsightBox() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.borderHairline),
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 18, color: AppColors.textPrimary),
                const SizedBox(width: 8),
                const Text('AI STYLE ADVISORY', style: TextStyle(fontSize: 14, letterSpacing: 1, color: AppColors.textPrimary)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              result.stylingNote ?? '이 조합으로 오늘 하루를 스타일링해보세요.',
              style: AppTextStyles.body.copyWith(height: 1.6),
            ),
          ],
        ),
      ),
    );
  }

  Widget _itemCard(ApiService apiService, RecommendedClothingItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: AspectRatio(
              aspectRatio: 1,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.chipBackground),
                  if (item.croppedImagePath != null)
                    Image.network(apiService.imageUrl(item.croppedImagePath!), fit: BoxFit.cover)
                  else
                    // 옷장 사진이 없을 때 대체하는 예시 이미지.
                    Image.network(
                      'https://images.unsplash.com/photo-1467043237213-65f2da53396f?w=400&q=80&auto=format&fit=crop',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                    ),
                  Positioned(
                    left: 16,
                    top: 16,
                    child: DecoratedBox(
                      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(999)),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        child: Text('내 옷장 아이템',
                            style: TextStyle(color: AppColors.white, fontSize: 10, letterSpacing: 0.5)),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(_categoryLabels[item.category]?.toUpperCase() ?? item.category,
            style: const TextStyle(color: AppColors.textTertiary, fontSize: 14)),
        Text(_categoryLabels[item.category] ?? item.category, style: AppTextStyles.koreanHeadline.copyWith(fontSize: 20)),
      ],
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Widget _buildPlusOneCard() {
    final plusOne = result.plusOne!;
    return DecoratedBox(
      decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(AppRadius.card)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('RECOMMEND · +1 ITEM', style: TextStyle(color: AppColors.white, fontSize: 14, letterSpacing: 1.6)),
            const SizedBox(height: 12),
            if (plusOne.productImageUrl != null) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: Image.network(
                  plusOne.productImageUrl!,
                  height: 140,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
              const SizedBox(height: 16),
            ],
            Text(plusOne.itemName, style: const TextStyle(color: AppColors.white, fontSize: 22, fontWeight: FontWeight.bold)),
            if (plusOne.reason != null) ...[
              const SizedBox(height: 8),
              Text(plusOne.reason!, style: AppTextStyles.bodyOnDark),
            ],
            if (plusOne.productUrl != null) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () => _openLink(plusOne.productUrl!),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.white,
                    side: const BorderSide(color: AppColors.white),
                  ),
                  child: Text(
                    plusOne.price != null
                        ? '${plusOne.price}원 · ${plusOne.mallName ?? "쇼핑몰"}에서 구매하기'
                        : '${plusOne.mallName ?? "쇼핑몰"}에서 구매하기',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
