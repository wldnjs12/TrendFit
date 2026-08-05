import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';
import '../widgets/ai_loading_indicator.dart';
import '../widgets/trendfit_top_bar.dart';
import 'closet_confirm_screen.dart';
import 'closet_upload_screen.dart';

/// 내 옷장 v2 — 보유 의류 조회/등록. (Figma "내 옷장 v2", PRD 4.2 F2)
/// 사진 업로드 -> Vision 자동 태깅 + 크롭은 [ClosetUploadScreen]에서, 애매한 속성(핏/재질)
/// 보정은 [ClosetConfirmScreen]에서 처리한다.
class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);

  static const _categories = ['전체', 'TOP', 'BOTTOM', 'OUTER', 'DRESS', 'SHOES', 'ACCESSORY'];
  static const _categoryLabels = {
    'TOP': '상의',
    'BOTTOM': '하의',
    'OUTER': '아우터',
    'DRESS': '원피스',
    'SHOES': '신발',
    'ACCESSORY': '액세서리',
  };

  String _filter = '전체';
  late Future<List<ClothingItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _apiService.fetchClosetItems(AppSession.userId!);
  }

  void _reload() {
    setState(() {
      _itemsFuture = _apiService.fetchClosetItems(AppSession.userId!);
    });
  }

  Future<void> _openUpload() async {
    final uploaded = await Navigator.of(context).push<List<ClothingItem>>(
      MaterialPageRoute(builder: (_) => const ClosetUploadScreen()),
    );
    if (uploaded == null || uploaded.isEmpty || !mounted) return;

    final confirmedAll = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => ClosetConfirmScreen(items: uploaded)),
    );
    if (confirmedAll == true) {
      _reload();
    }
  }

  /// 아이템 카드를 탭하면 여는 해시태그 편집 시트. 저장되면 목록을 다시 불러온다.
  Future<void> _openTagEditor(ClothingItem item) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (context) => _TagEditorSheet(item: item, apiService: _apiService),
    );
    if (saved == true) _reload();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TrendFitTopBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: _openUpload,
        backgroundColor: AppColors.black,
        child: const Icon(Icons.add, color: AppColors.white),
      ).animate().scale(
            begin: const Offset(0, 0),
            end: const Offset(1, 1),
            duration: AppMotion.slow,
            curve: AppMotion.spring,
          ),
      body: SafeArea(
        top: false,
        child: FutureBuilder<List<ClothingItem>>(
          future: _itemsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('옷장을 불러오지 못했어요.\n${snapshot.error}', textAlign: TextAlign.center));
            }

            final items = (snapshot.data ?? [])
                .where((item) => _filter == '전체' || item.category == _filter)
                .toList();

            return CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PERSONAL COLLECTION',
                            style: TextStyle(color: AppColors.textTertiary, fontSize: 12, letterSpacing: 1.2)),
                        const SizedBox(height: 4),
                        Text('내 옷장', style: AppTextStyles.displayHeavy.copyWith(fontSize: 28)),
                        const SizedBox(height: 20),
                        _buildFilterChips(),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 96),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final card = index == items.length ? _addItemCard() : _itemCard(items[index]);
                        return card
                            .animate()
                            .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * (index % 6))
                            .scale(begin: const Offset(0.94, 0.94), end: const Offset(1, 1), duration: AppMotion.base, curve: AppMotion.enter);
                      },
                      childCount: items.length + 1,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = _categories[index];
          final selected = category == _filter;
          final label = category == '전체' ? '전체' : (_categoryLabels[category] ?? category);
          return ChoiceChip(
            label: Text(label),
            selected: selected,
            onSelected: (_) => setState(() => _filter = category),
            showCheckmark: false,
            shape: const StadiumBorder(),
            side: BorderSide(color: selected ? AppColors.black : AppColors.borderLight),
            selectedColor: AppColors.black,
            backgroundColor: AppColors.white,
            labelStyle: TextStyle(color: selected ? AppColors.white : AppColors.textPrimary, fontSize: 13),
          );
        },
      ),
    );
  }

  Widget _itemCard(ClothingItem item) {
    final imagePath = item.croppedImagePath ?? item.imagePath;
    return InkWell(
      // 눌러서 해시태그(언제/어떤 상황에 입을 옷인지 메모)를 추가할 수 있게 한다.
      onTap: () => _openTagEditor(item),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.chipBackground),
              // BoxFit.cover는 카드 비율과 안 맞는(세로로 긴) 사진의 위아래를 잘라내 옷 일부만
              // 보이게 만든다 — 옷 전체가 항상 보이도록 contain으로 채운다(빈 여백은 배경색).
              CachedNetworkImage(imageUrl: _apiService.imageUrl(imagePath), fit: BoxFit.contain),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                  ),
                ),
              ),
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Text(
                  _categoryLabels[item.category] ?? item.category,
                  style: const TextStyle(color: AppColors.white, fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              if (item.tags.isNotEmpty)
                Positioned(
                  top: 8,
                  left: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.tag, size: 10, color: AppColors.white),
                          const SizedBox(width: 2),
                          Text('${item.tags.length}', style: const TextStyle(color: AppColors.white, fontSize: 10)),
                        ],
                      ),
                    ),
                  ),
                ),
              if (!item.confirmed)
                Positioned(
                  top: 8,
                  right: 8,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(999)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      child: Text('보정 필요', style: TextStyle(color: AppColors.white, fontSize: 10)),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _addItemCard() {
    return InkWell(
      onTap: _openUpload,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: AppColors.borderLight),
          borderRadius: BorderRadius.circular(AppRadius.card),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add, color: AppColors.textTertiary),
              SizedBox(height: 8),
              Text('새 아이템 추가', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

/// 옷장 아이템 하나에 해시태그(자유 텍스트 메모)를 달거나 떼는 바텀시트.
/// 저장된 태그는 추천 요청 시 프롬프트에 "#태그" 형태로 그대로 실려 AI가 참고한다
/// (ClaudeRecommendationEngine.buildPrompt 참고).
class _TagEditorSheet extends StatefulWidget {
  const _TagEditorSheet({required this.item, required this.apiService});

  final ClothingItem item;
  final ApiService apiService;

  @override
  State<_TagEditorSheet> createState() => _TagEditorSheetState();
}

class _TagEditorSheetState extends State<_TagEditorSheet> {
  late final List<String> _tags = List.of(widget.item.tags);
  final _controller = TextEditingController();
  bool _saving = false;

  void _addTag() {
    final text = _controller.text.trim();
    if (text.isEmpty || _tags.contains(text)) {
      _controller.clear();
      return;
    }
    setState(() {
      _tags.add(text);
      _controller.clear();
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await widget.apiService.updateClothingItemTags(widget.item.id, _tags);
      if (mounted) Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final imagePath = widget.item.croppedImagePath ?? widget.item.imagePath;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.button),
                child: SizedBox(
                  width: 56,
                  height: 56,
                  child: CachedNetworkImage(imageUrl: widget.apiService.imageUrl(imagePath), fit: BoxFit.cover),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text('해시태그 추가', style: AppTextStyles.headingBold.copyWith(fontSize: 18))),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            '언제, 어떤 상황에 입을 옷인지 태그로 남겨두면 AI 추천 요청 시 참고해요.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
          const SizedBox(height: 16),
          if (_tags.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _tags
                  .map((tag) => Chip(
                        label: Text('#$tag'),
                        onDeleted: () => setState(() => _tags.remove(tag)),
                        backgroundColor: AppColors.chipBackground,
                        side: BorderSide.none,
                      ))
                  .toList(),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: const InputDecoration(hintText: '예: 데이트, 여름'),
                  onSubmitted: (_) => _addTag(),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(onPressed: _addTag, icon: const Icon(Icons.add_circle, color: AppColors.black)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving ? const AiLoadingIndicator(dotSize: 5) : const Text('저장'),
            ),
          ),
        ],
      ),
    );
  }
}
