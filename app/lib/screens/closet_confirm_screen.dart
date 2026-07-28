import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_theme.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';
import '../widgets/swipe_confirm_card.dart';
import '../widgets/trendfit_top_bar.dart';

/// 방금 등록한(미확정) 옷들의 핏/재질을 순서대로 보정한다. (PRD 4.2 F2)
///
/// 핏은 스와이프 카드로 예/아니오를 골라 좁혀나가고("오버핏인가요?" -> "슬림핏인가요?"
/// -> 둘 다 아니면 레귤러), 재질은 자유 입력 대신 자주 쓰는 칩 중에서 한 번에 고른다 —
/// 둘 다 "1~2초 만에" 확정한다는 의도를 살리면서 실제 입력 난이도를 낮췄다.
class ClosetConfirmScreen extends StatefulWidget {
  const ClosetConfirmScreen({super.key, required this.items});

  final List<ClothingItem> items;

  @override
  State<ClosetConfirmScreen> createState() => _ClosetConfirmScreenState();
}

enum _Phase { fitQuestion, materialPick }

class _ClosetConfirmScreenState extends State<ClosetConfirmScreen> {
  static const List<(String, String)> _fitQuestions = [
    ('이 옷, 오버핏인가요?', 'OVERSIZED'),
    ('그럼 슬림핏인가요?', 'SLIM'),
  ];

  static const List<String> _materials = ['코튼', '데님', '니트', '울', '폴리에스터', '가죽', '린넨', '기타'];

  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);

  int _itemIndex = 0;
  int _fitStep = 0;
  _Phase _phase = _Phase.fitQuestion;
  bool _submitting = false;
  bool _fitConfirmed = false;

  ClothingItem get _currentItem => widget.items[_itemIndex];

  Future<void> _onFitDecision(bool matched) async {
    if (matched) {
      setState(() => _phase = _Phase.materialPick);
      return;
    }
    if (_fitStep < _fitQuestions.length - 1) {
      setState(() => _fitStep++);
    } else {
      // 둘 다 아니면 레귤러
      setState(() => _phase = _Phase.materialPick);
    }
  }

  String _decidedFit() {
    if (_phase != _Phase.materialPick) {
      return 'REGULAR';
    }
    // materialPick 단계로 넘어온 시점의 _fitStep이 마지막까지 갔다면(=오버핏/슬림핏 모두
    // 아니오였다면) REGULAR, 아니면 해당 질문에서 "예"로 확정된 핏이다.
    return _fitConfirmed ? _fitQuestions[_fitStep].$2 : 'REGULAR';
  }

  Future<void> _onMaterialPicked(String material) async {
    setState(() => _submitting = true);
    try {
      await _apiService.confirmClosetItem(_currentItem.id, fit: _decidedFit(), material: material);
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
      _fitStep = 0;
      _fitConfirmed = false;
      _phase = _Phase.fitQuestion;
    });
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = _currentItem.croppedImagePath ?? _currentItem.imagePath;

    return Scaffold(
      appBar: TrendFitTopBar(
        onBack: () => Navigator.of(context).pop(),
        actions: [
          Text('${_itemIndex + 1} / ${widget.items.length}',
              style: AppTextStyles.trackedLabel.copyWith(color: AppColors.textPrimary)),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Center(
            child: _phase == _Phase.fitQuestion
                ? SwipeConfirmCard(
                    imageUrl: _apiService.imageUrl(imagePath),
                    question: _fitQuestions[_fitStep].$1,
                    onConfirm: () {
                      _fitConfirmed = true;
                      _onFitDecision(true);
                    },
                    onReject: () {
                      _fitConfirmed = false;
                      _onFitDecision(false);
                    },
                  )
                : _buildMaterialPicker(),
          ),
        ),
      ),
    );
  }

  Widget _buildMaterialPicker() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('재질을 골라주세요', style: AppTextStyles.headingBold.copyWith(fontSize: 20)),
        const SizedBox(height: 20),
        if (_submitting)
          const CircularProgressIndicator()
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _materials.map((material) {
              return ChoiceChip(
                label: Text(material),
                selected: false,
                onSelected: (_) => _onMaterialPicked(material),
                shape: const RoundedRectangleBorder(),
                side: const BorderSide(color: AppColors.borderLight),
                backgroundColor: AppColors.white,
                labelStyle: const TextStyle(color: AppColors.textPrimary),
              );
            }).toList(),
          ),
      ],
    );
  }
}
