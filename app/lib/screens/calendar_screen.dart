import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/recommendation_history.dart';
import '../services/api_service.dart';
import '../widgets/outfit_mosaic.dart';
import '../widgets/trendfit_mark.dart';
import '../widgets/weekly_report_sheet.dart';

/// 캘린더(위클리 아카이브) — 4번째 탭. (Figma "위클리 아카이브" 프레임, 2026-07-28 결정으로 MVP 승격)
/// `RecommendationLog` 이력을 주 단위(월~일)로 묶어 그날 추천받은 코디를 돌아본다.
/// 한 주(7일)가 모두 채워지면 위클리 리포트 이미지를 만들어 저장할 수 있다 — 인스타그램 API
/// 직접 연동(로그인 필요, PRD상 이용약관 리스크로 스트레치)과는 무관한 로컬 이미지 합성/저장
/// 기능이라 "커뮤니티/공유 제외" 범위에 해당하지 않는다(PRD.md §4.3, 2026-07-29 범위 추가).
class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => CalendarScreenState();
}

/// MainTabShell이 모든 탭을 계속 마운트해둔 채 전환하는 구조라(IndexedStack이 아니라
/// opacity만 토글) 이 State는 initState 이후로 다시 생성되지 않는다. 그래서 탭 전환만으로는
/// 새 추천 확정 내역이 반영되지 않아 — MainTabShell이 GlobalKey로 이 State를 들고 있다가
/// 캘린더 탭으로 전환될 때마다 [refresh]를 호출해 최신 이력을 다시 불러온다.
class CalendarScreenState extends State<CalendarScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final ImagePicker _picker = ImagePicker();
  late DateTime _weekStart;
  late Future<List<RecommendationHistoryItem>> _historyFuture;
  int _shiftDirection = 0;

  /// 업로드 직후 새로고침 없이 바로 반영하기 위한 로컬 오버라이드 (logId -> 착용샷 URL).
  final Map<int, String> _wornPhotoOverrides = {};
  int? _uploadingLogId;

  /// 기록 없는 요일 카드를 탭해 새 착용샷 이력을 만드는 동안(route 2)의 로딩 상태.
  int? _creatingWeekday;

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

  /// 다른 화면(추천 확정 등)에서 돌아와 이 탭이 다시 활성화될 때 이력을 새로 불러온다.
  void refresh() => setState(_load);

  void _shiftWeek(int deltaWeeks) {
    setState(() {
      _shiftDirection = deltaWeeks.sign;
      _weekStart = _weekStart.add(Duration(days: 7 * deltaWeeks));
      _load();
    });
  }

  /// AI가 추천해준 코디 사진과 별개로, 그날 실제로 입은 모습을 직접 등록한다.
  Future<void> _uploadWornPhoto(RecommendationHistoryItem entry) async {
    // 웹은 imageQuality를 지원하지 않아 maxWidth/maxHeight로 원본 크기를 제한한다 —
    // 안 그러면 큰 사진이 서버의 multipart 크기 제한에 걸려 브라우저에 "Load failed"로만
    // 보이는 네트워크 에러가 난다.
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
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

  /// 기록 없는 요일 카드를 탭했을 때 — AI 추천을 거치지 않고 착용샷만으로 바로 새 이력을 만든다
  /// (route 2). 코디 저장(route 1)과 달리 확정 절차 없이 등록 즉시 캘린더에 반영된다.
  Future<void> _createWornPhotoForDay(int weekday) async {
    // 웹은 imageQuality를 지원하지 않아 maxWidth/maxHeight로 원본 크기를 제한한다 —
    // 안 그러면 큰 사진이 서버의 multipart 크기 제한에 걸려 브라우저에 "Load failed"로만
    // 보이는 네트워크 에러가 난다.
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1600, maxHeight: 1600);
    if (image == null) return;
    final date = _weekStart.add(Duration(days: weekday - 1));
    setState(() => _creatingWeekday = weekday);
    try {
      await _apiService.createWornPhotoEntry(AppSession.userId!, date, image);
      if (!mounted) return;
      setState(_load);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('착용샷 등록에 실패했어요: $e')));
    } finally {
      if (mounted) setState(() => _creatingWeekday = null);
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
          const SizedBox(height: 20),
          _buildReportCta(byDay),
        ],
      ),
    );
  }

  /// 7일이 모두 채워지면 위클리 리포트 이미지를 만들 수 있다는 걸 알려주고 진입점을 보여준다.
  Widget _buildReportCta(Map<int, RecommendationHistoryItem> byDay) {
    final filled = byDay.length;
    final complete = filled >= 7;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: complete ? AppColors.black : AppColors.chipBackground,
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.auto_awesome_mosaic_outlined, size: 20, color: complete ? AppColors.white : AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                complete ? '이번 주 기록이 모두 채워졌어요!' : '$filled/7일 채워지면 위클리 리포트를 만들 수 있어요',
                style: TextStyle(
                  color: complete ? AppColors.white : AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            if (complete)
              TextButton(
                onPressed: () => _openWeeklyReportSheet(byDay),
                style: TextButton.styleFrom(foregroundColor: AppColors.white),
                child: const Text('만들기'),
              ),
          ],
        ),
      ),
    );
  }

  void _openWeeklyReportSheet(Map<int, RecommendationHistoryItem> byDay) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.card))),
      builder: (context) => WeeklyReportSheet(apiService: _apiService, weekStart: _weekStart, byDay: byDay),
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
    final outfitUrls = entry == null
        ? const <String>[]
        : entry.items
            .map((item) => item.croppedImagePath)
            .whereType<String>()
            .map(_apiService.imageUrl)
            .toList();
    final wornUrl = entry == null ? null : (_wornPhotoOverrides[entry.logId] ?? entry.wornPhotoUrl);
    final caption = entry?.requestText;
    final uploading = entry != null && _uploadingLogId == entry.logId;
    final creating = entry == null && _creatingWeekday == weekday;

    final cardBody = Stack(
        fit: StackFit.expand,
        children: [
            Container(color: AppColors.chipBackground),
            if (wornUrl != null)
              CachedNetworkImage(imageUrl: _apiService.imageUrl(wornUrl), fit: BoxFit.cover)
            else if (outfitUrls.isNotEmpty)
              OutfitMosaic(imageUrls: outfitUrls)
            else
              // 기록 없는 요일 — 탭하면 바로 착용샷을 등록할 수 있다는 걸 아이콘으로 알려준다.
              Center(
                child: creating
                    ? const SizedBox(
                        width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.textPlaceholder))
                    : const Icon(Icons.add_a_photo_outlined, color: AppColors.textPlaceholder, size: 26),
              ),
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
                  // entry가 있는데 caption(requestText)만 없는 경우는 "사진만 바로 등록"한
                  // 케이스(route 2)라 실제로는 기록이 있다 — "기록 없음"이라고 하면 착용샷이
                  // 없다는 뜻으로 오해되므로, 이땐 아무 텍스트도 보여주지 않는다.
                  if (caption != null && caption.isNotEmpty)
                    Text(
                      caption,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    )
                  else if (entry == null)
                    const Text(
                      '탭해서 착용샷 등록',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.textTertiary, fontWeight: FontWeight.w600, fontSize: 13),
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
    );

    return Container(
      height: height,
      width: fullWidth ? double.infinity : null,
      decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: entry == null ? null : AppShadows.soft),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: entry == null
            ? InkWell(
                onTap: creating ? null : () => _createWornPhotoForDay(weekday),
                child: cardBody,
              )
            : cardBody,
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
