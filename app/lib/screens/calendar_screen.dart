import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/recommendation_history.dart';
import '../services/api_service.dart';

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
  late DateTime _weekStart;
  late Future<List<RecommendationHistoryItem>> _historyFuture;

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
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
      _load();
    });
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
                  return _buildWeekGrid(byDay);
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
              const Icon(Icons.menu, size: 18, color: AppColors.textPrimary),
              const SizedBox(width: 16),
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
                Expanded(child: _dayCard(row * 2 + 1, byDay[row * 2 + 1])),
                const SizedBox(width: 12),
                Expanded(child: _dayCard(row * 2 + 2, byDay[row * 2 + 2])),
              ],
            ),
            const SizedBox(height: 12),
          ],
          _dayCard(7, byDay[7], fullWidth: true, height: 260),
        ],
      ),
    );
  }

  Widget _dayCard(int weekday, RecommendationHistoryItem? entry, {bool fullWidth = false, double height = 160}) {
    final date = _weekStart.add(Duration(days: weekday - 1));
    final dateLabel = '${date.month.toString().padLeft(2, '0')}.${date.day.toString().padLeft(2, '0')}';
    final imagePath = entry?.items.isNotEmpty == true ? entry!.items.first.croppedImagePath : null;
    final caption = entry?.requestText;

    return SizedBox(
      height: height,
      width: fullWidth ? double.infinity : null,
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(color: AppColors.chipBackground),
            if (imagePath != null)
              Image.network(_apiService.imageUrl(imagePath), fit: BoxFit.cover)
            else
              // 기록 없는 요일의 배경(임시 예시 이미지) — 낮은 불투명도로 "기록 있음"과 구분한다.
              Opacity(
                opacity: 0.35,
                child: Image.network(
                  'https://images.unsplash.com/photo-1573311392049-4186e3a47e9c?w=400&q=80&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
              ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withValues(alpha: entry == null ? 0.15 : 0.55)],
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
