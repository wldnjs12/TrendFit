import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';
import '../widgets/ai_loading_indicator.dart';
import '../widgets/pressable_scale.dart';
import '../widgets/trendfit_top_bar.dart';

/// 방금 등록한(미확정) 옷들의 핏/재질을 순서대로 확정한다. (PRD 4.2 F2)
///
/// 스와이프로 예/아니오를 반복해서 좁혀나가던 방식 대신, 핏(오버핏/레귤러핏/슬림핏)과
/// 소재를 한 화면에서 칩으로 바로 골라 확정한다 — 선택지가 뻔히 보이는 편이 더 빠르고
/// 직관적이다.
class ClosetConfirmScreen extends StatefulWidget {
  const ClosetConfirmScreen({super.key, required this.items});

  final List<ClothingItem> items;

  @override
  State<ClosetConfirmScreen> createState() => _ClosetConfirmScreenState();
}

class _ClosetConfirmScreenState extends State<ClosetConfirmScreen> {
  static const List<(String, String)> _fits = [
    ('오버핏', 'OVERSIZED'),
    ('레귤러핏', 'REGULAR'),
    ('슬림핏', 'SLIM'),
  ];

  static const List<String> _materials = ['코튼', '데님', '니트', '울', '폴리에스터', '가죽', '린넨', '기타'];

  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);

  int _itemIndex = 0;
  String? _selectedFit;
  String? _selectedMaterial;
  bool _submitting = false;

  ClothingItem get _currentItem => widget.items[_itemIndex];

  bool get _canConfirm => _selectedFit != null && _selectedMaterial != null && !_submitting;

  Future<void> _confirmItem() async {
    if (!_canConfirm) return;
    setState(() => _submitting = true);
    try {
      await _apiService.confirmClosetItem(_currentItem.id, fit: _selectedFit!, material: _selectedMaterial!);
      _goToNextItem();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _goToNextItem() {
    if (_itemIndex >= widget.items.length - 1) {
      Navigator.of(context).pop(true);
      return;
    }
    setState(() {
      _itemIndex++;
      _selectedFit = null;
      _selectedMaterial = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _currentItem.croppedImagePath ?? _currentItem.imagePath;

    return Scaffold(
      appBar: TrendFitTopBar(
        onBack: () => Navigator.of(context).pop(),
        actions: [
          DecoratedBox(
            decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(999)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Text('${_itemIndex + 1} / ${widget.items.length}',
                  style: AppTextStyles.trackedLabel.copyWith(color: AppColors.white)),
            ),
          ).animate(key: ValueKey(_itemIndex)).fadeIn(duration: AppMotion.fast).scale(
                begin: const Offset(0.85, 0.85),
                end: const Offset(1, 1),
                duration: AppMotion.fast,
                curve: AppMotion.spring,
              ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: AnimatedSwitcher(
            duration: AppMotion.base,
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            transitionBuilder: (child, animation) => FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(animation),
                child: ScaleTransition(
                  scale: Tween(begin: 0.97, end: 1.0).animate(CurvedAnimation(parent: animation, curve: AppMotion.enter)),
                  child: child,
                ),
              ),
            ),
            child: Column(
              key: ValueKey(_itemIndex),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.card),
                  child: Container(
                    height: 300,
                    width: double.infinity,
                    decoration: BoxDecoration(boxShadow: AppShadows.card, color: AppColors.chipBackground),
                    // BoxFit.cover는 세로로 긴 사진의 위아래를 잘라내 옷 일부만 보이게
                    // 만든다 — 옷 전체가 항상 보이도록 contain으로 채운다(빈 여백은 배경색).
                    child: CachedNetworkImage(imageUrl: _apiService.imageUrl(imagePath), fit: BoxFit.contain),
                  ),
                ),
                const SizedBox(height: 28),
                Text('핏감이 어떤가요?', style: AppTextStyles.koreanHeadline.copyWith(fontSize: 19)),
                const SizedBox(height: 12),
                _choiceRow(
                  options: _fits.map((f) => f.$1).toList(),
                  selected: _selectedFit == null
                      ? null
                      : _fits.firstWhere((f) => f.$2 == _selectedFit).$1,
                  onSelected: (label) => setState(() => _selectedFit = _fits.firstWhere((f) => f.$1 == label).$2),
                ),
                const SizedBox(height: 28),
                Text('소재는 뭔가요?', style: AppTextStyles.koreanHeadline.copyWith(fontSize: 19)),
                const SizedBox(height: 12),
                _choiceRow(
                  options: _materials,
                  selected: _selectedMaterial,
                  onSelected: (label) => setState(() => _selectedMaterial = label),
                ),
                const SizedBox(height: 36),
                PressableScale(
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _canConfirm ? _confirmItem : null,
                      child: _submitting ? const AiLoadingIndicator(dotSize: 5) : const Text('CONFIRM'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _choiceRow({required List<String> options, required String? selected, required ValueChanged<String> onSelected}) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.asMap().entries.map((entry) {
        final label = entry.value;
        final isSelected = label == selected;
        return ChoiceChip(
          label: Text(label),
          selected: isSelected,
          onSelected: (_) => onSelected(label),
          showCheckmark: false,
          shape: const StadiumBorder(),
          side: BorderSide(color: isSelected ? AppColors.black : AppColors.borderLight),
          selectedColor: AppColors.black,
          backgroundColor: AppColors.white,
          labelStyle: TextStyle(color: isSelected ? AppColors.white : AppColors.textPrimary, fontWeight: FontWeight.w600),
        ).animate().fadeIn(duration: AppMotion.fast, delay: AppMotion.stagger * entry.key).scale(
              begin: const Offset(0.9, 0.9),
              end: const Offset(1, 1),
              duration: AppMotion.fast,
              curve: AppMotion.enter,
            );
      }).toList(),
    );
  }
}
