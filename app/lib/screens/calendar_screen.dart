import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/recommendation_history.dart';
import '../services/api_service.dart';
import '../widgets/trendfit_mark.dart';

/// 캘린더(위클리 아카이브) — 4번째 탭. (Figma "위클리 아카이브" 프레임, 2026-07-28 결정으로 MVP 승격)
/// `RecommendationLog` 이력을 주 단위(월~일)로 묶어 그날 추천받은 코디를 돌아본다.
/// 공유/스토리 내보내기는 PRD상 "커뮤니티/공유 = 제외" 항목이라 UI에서 뺐다.
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final ImagePicker _picker = ImagePicker();
  late DateTime _weekStart;
  late Future<List<RecommendationHistoryItem>> _historyFuture;
  int _shiftDirection = 0;

  /// 업로드 직후 새로고침 없이 바로 반영하기 위한 로컬 오버라이드 (logId -> 착용샷 URL).
  final Map<int, String> _wornPhotoOverrides = {};
  int? _uploadingLogId;

  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _weekStart = DateTime(now.year, now.month, now.day).subtract(Duration(days: now.weekday - 1));
    _load();
  }

  void _load() {
    _historyFuture = _apiService.fetchWeeklyHistory(AppSession.userId!, weekStart: _weekStart);
  }

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _shiftDirection = deltaWeeks.sign;
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
      _load();
    });
  }

  /// AI가 추천해준 코디 사진과 별개로, 그날 실제로 입은 모습을 직접 등록한다.
  Future<void> _uploadWornPhoto(RecommendationHistoryItem entry) async {
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (image == null) return;
    setState(() => _uploadingLogId = entry.logId);
    try {
      final url = await _apiService.uploadWornPhoto(AppSession.userId!, entry.logId, image);
      if (!mounted) return;
      setState(() => _wornPhotoOverrides[entry.logId] = url);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('착용샷 등록에 실패했어요: $e')));
    } finally {
      if (mounted) setState(() => _uploadingLogId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: FutureBuilder<List<RecommendationHistoryItem>>(
                future: _historyFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('기록을 불러오지 못했어요.\n${snapshot.error}', textAlign: TextAlign.center),
                    );
                  }
                  final byDay = <int, RecommendationHistoryItem>{};
                  for (final entry in snapshot.data ?? []) {
                    byDay[entry.date.weekday] = entry;
                  }
                  return _buildWeekGrid(byDay)
                      .animate(key: ValueKey(_weekStart))
                      .fadeIn(duration: AppMotion.base)
                      .slideX(begin: 0.06 * (_shiftDirection == 0 ? 1 : _shiftDirection), end: 0, duration: AppMotion.base, curve: AppMotion.enter);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final weekOfMonth = ((_weekStart.day - 1) ~/ 7) + 1;
    final monthLabel = _monthName(_weekStart.month);
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const TrendFitMark(size: 26, radius: 6),
              const SizedBox(width: 12),
              Text('WEEKLY ARCHIVE', style: AppTextStyles.wordmark.copyWith(fontSize: 18)),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$monthLabel / WEEK $weekOfMonth', style: AppTextStyles.trackedLabel),
              Row(
                children: [
                  IconButton(
                    onPressed: () => _shiftWeek(-1),
                    icon: const Icon(Icons.chevron_left, size: 20),
                    color: AppColors.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                  IconButton(
                    onPressed: () => _shiftWeek(1),
                    icon: const Icon(Icons.chevron_right, size: 20),
                    color: AppColors.textPrimary,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text('이번 주 코디 기록', style: AppTextStyles.displayHeavy.copyWith(fontSize: 24)),
          const SizedBox(height: 12),
          const Divider(color: AppColors.black, thickness: 1, height: 1),
        ],
      ),
    );
  }

  Widget _buildWeekGrid(Map<int, RecommendationHistoryItem> byDay) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
      child: Column(
        children: [
          for (int row = 0; row < 3; row++) ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: _staggered(_dayCard(row * 2 + 1, byDay[row * 2 + 1]), row * 2)),
                const SizedBox(width: 12),
                Expanded(child: _staggered(_dayCard(row * 2 + 2, byDay[row * 2 + 2]), row * 2 + 1)),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _staggered(_dayCard(7, byDay[7], fullWidth: true, height: 260), 6),
        ],
      ),
    );
  }

  Widget _staggered(Widget child, int index) {
    return child
        .animate()
        .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * index)
        .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: AppMotion.base, curve: AppMotion.enter);
  }

  Widget _dayCard(int weekday, RecommendationHistoryItem? entry, {bool fullWidth = false, double height = 160}) {
    final date = _weekStart.add(Duration(days: weekday - 1));
    final dateLabel = '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final aiImagePath = entry?.items.isNotEmpty == true ? entry!.items.first.croppedImagePath : null;
    final wornUrl = entry == null ? null : (_wornPhotoOverrides[entry.logId] ?? entry.wornPhotoUrl);
    final caption = entry?.requestText;
    final uploading = entry != null && _uploadingLogId == entry.logId;

    return Container(
      height: height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: entry == null ? null : AppShadows.soft),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.chipBackground),
            if (wornUrl != null)
              Image.network(_apiService.imageUrl(wornUrl), fit: BoxFit.cover)
            else if (aiImagePath != null)
              Image.network(_apiService.imageUrl(aiImagePath), fit: BoxFit.cover)
            else
              // 기록 없는 요일 — 자극적인 스톡사진 대신 은은한 아이콘만 두어 깔끔하게 비워둔다.
              const Center(child: Icon(Icons.checkroom_outlined, color: AppColors.textPlaceholder, size: 28)),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: entry == null ? 0.05 : 0.55)],
                ),
              ),
            ),
            if (wornUrl != null)
              Positioned(
                top: 10,
                left: 10,
                child: DecoratedBox(
                  decoration: BoxDecoration(color: AppColors.white, borderRadius: BorderRadius.circular(999)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    child: Text('MY LOOK', style: TextStyle(color: AppColors.black, fontSize: 10, fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
            if (entry != null)
              Positioned(
                top: 8,
                right: 8,
                child: InkWell(
                  onTap: uploading ? null : () => _uploadWornPhoto(entry),
                  borderRadius: BorderRadius.circular(999),
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.55), borderRadius: BorderRadius.circular(999)),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: uploading
                          ? const SizedBox(
                              width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                          : const Icon(Icons.add_a_photo_outlined, size: 14, color: AppColors.white),
                    ),
                  ),
                ),
              ),
            Positioned(
              left: 12,
              right: 12,
              bottom: 10,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _dayLabels[weekday - 1],
                    style: AppTextStyles.trackedLabelBig.copyWith(
                      color: entry == null ? AppColors.textTertiary : AppColors.white,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    caption != null && caption.isNotEmpty ? caption : '기록 없음',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: entry == null ? AppColors.textTertiary : AppColors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  Text(
                    dateLabel,
                    style: TextStyle(
                      color: (entry == null ? AppColors.textTertiary : AppColors.white).withValues(alpha: 0.8),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _monthName(int month) {
    const names = [
      'JANUARY', 'FEBRUARY', 'MARCH', 'APRIL', 'MAY', 'JUNE',
      'JULY', 'AUGUST', 'SEPTEMBER', 'OCTOBER', 'NOVEMBER', 'DECEMBER',
    ];
    return names[month - 1];
  }
}
