import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../models/recommendation_history.dart';
import '../services/api_service.dart';
import '../utils/image_saver.dart';

/// 한 주(7일)가 모두 채워졌을 때, 인스타그램 스토리(9:16)에 올리기 좋은 합성 이미지를 만들어
/// 저장할 수 있는 바텀시트. 인스타그램 API와는 무관한 로컬 이미지 합성/다운로드 기능이다
/// (calendar_screen.dart 상단 주석 참고).
class WeeklyReportSheet extends StatefulWidget {
  const WeeklyReportSheet({
    super.key,
    required this.apiService,
    required this.weekStart,
    required this.byDay,
  });

  final ApiService apiService;
  final DateTime weekStart;
  final Map<int, RecommendationHistoryItem> byDay;

  static const double canvasWidth = 320;
  static const double canvasHeight = canvasWidth * 16 / 9;

  @override
  State<WeeklyReportSheet> createState() => _WeeklyReportSheetState();
}

class _WeeklyReportSheetState extends State<WeeklyReportSheet> {
  static const _dayLabels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  final GlobalKey _boundaryKey = GlobalKey();
  bool _imagesReady = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _preloadImages());
  }

  String? _imageUrlFor(int weekday) {
    final entry = widget.byDay[weekday];
    if (entry == null) return null;
    final path = entry.wornPhotoUrl ??
        (entry.items.isNotEmpty ? entry.items.first.croppedImagePath : null);
    return path == null ? null : widget.apiService.imageUrl(path);
  }

  Future<void> _preloadImages() async {
    final urls = [for (int day = 1; day <= 7; day++) _imageUrlFor(day)].whereType<String>();
    await Future.wait(urls.map((url) => precacheImage(NetworkImage(url), context)));
    if (mounted) setState(() => _imagesReady = true);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
      // 1080px 폭 근처의 스토리 해상도를 목표로 pixelRatio를 역산한다.
      final image = await boundary.toImage(pixelRatio: 1080 / WeeklyReportSheet.canvasWidth);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      final bytes = byteData!.buffer.asUint8List();
      final filename = 'trendfit_weekly_${_fileDateLabel(widget.weekStart)}.png';
      await saveOrShareImage(bytes, filename);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('이미지 저장에 실패했어요: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String _fileDateLabel(DateTime date) =>
      '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('위클리 리포트', style: AppTextStyles.headingBold),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              '인스타그램 스토리에 바로 올리기 좋은 크기로 만들었어요.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 20),
            RepaintBoundary(
              key: _boundaryKey,
              child: SizedBox(
                width: WeeklyReportSheet.canvasWidth,
                height: WeeklyReportSheet.canvasHeight,
                child: Stack(
                  children: [
                    _buildCanvas(),
                    if (!_imagesReady)
                      const Positioned.fill(
                        child: ColoredBox(
                          color: Colors.black45,
                          child: Center(child: CircularProgressIndicator(color: AppColors.white)),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: (_imagesReady && !_saving) ? _save : null,
                child: _saving
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('이미지 저장하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCanvas() {
    final weekOfMonth = ((widget.weekStart.day - 1) ~/ 7) + 1;
    return Container(
      color: AppColors.black,
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('T',
                  style: GoogleFonts.syne(fontWeight: FontWeight.w800, fontSize: 18, height: 1, color: AppColors.white)),
              const SizedBox(width: 6),
              const Text('TRENDFIT', style: TextStyle(color: AppColors.white, fontSize: 12, letterSpacing: 2, fontWeight: FontWeight.w700)),
            ],
          ),
          const SizedBox(height: 14),
          Text('WEEKLY ARCHIVE · ${widget.weekStart.month}월 $weekOfMonth주차',
              style: const TextStyle(color: AppColors.textTertiary, fontSize: 10, letterSpacing: 1.2)),
          const SizedBox(height: 4),
          const Text('이번 주 코디 기록', style: TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          const SizedBox(height: 14),
          Expanded(
            child: GridView.count(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              physics: const NeverScrollableScrollPhysics(),
              children: [for (int day = 1; day <= 7; day++) _reportTile(day)],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reportTile(int weekday) {
    final url = _imageUrlFor(weekday);
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: AppColors.chipBackground),
          if (url != null) Image.network(url, fit: BoxFit.cover),
          Positioned(
            left: 6,
            bottom: 6,
            child: Text(
              _dayLabels[weekday - 1],
              style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
