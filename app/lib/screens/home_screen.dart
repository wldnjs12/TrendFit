import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/recommendation_result.dart';
import '../models/trend_article.dart';
import '../services/api_service.dart';
import '../widgets/trendfit_top_bar.dart';
import 'calendar_screen.dart';
import 'recommendation_result_screen.dart';

enum _LocationStatus { loading, available, denied, unavailable }

/// 홈 = 오늘의 코디. (CLAUDE.md §4, Figma "홈 (오늘의 추천) v2")
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

  Position? _position;
  _LocationStatus _locationStatus = _LocationStatus.loading;

  late Future<List<TrendArticle>> _trendReportFuture;

  @override
  void initState() {
    super.initState();
    // 검색을 눌러야만 위치를 요청하던 걸 화면 진입 시 바로 시도하도록 변경 —
    // 사용자가 "위치 자동설정이 안 된다"고 느끼는 원인이었다.
    _initLocation();
    _trendReportFuture = _apiService.fetchTrendReport();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _initLocation() async {
    setState(() => _locationStatus = _LocationStatus.loading);
    final position = await _resolvePosition();
    if (!mounted) return;
    setState(() {
      _position = position;
      _locationStatus = position != null ? _LocationStatus.available : _locationStatus;
    });
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
      // 이미 위치를 확보했으면 재요청하지 않고 그대로 쓴다.
      final position = _position ?? await _resolvePosition();
      final result = await _apiService.requestRecommendation(
        AppSession.userId!,
        requestText,
        lat: position?.latitude,
        lon: position?.longitude,
      );
      setState(() => _result = result);
    } catch (e) {
      setState(() => _errorMessage = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  /// 정확한 날씨 조회를 위한 위치 자동 감지. 권한이 없거나 실패하면 null을 반환해
  /// 서버가 기본 좌표(서울시청)로 폴백하도록 둔다 — 위치 접근이 추천 기능을 막아서는 안 된다.
  /// 실패 사유는 [_locationStatus]에 반영해 화면에 조용히 묻히지 않게 한다.
  Future<Position?> _resolvePosition() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (mounted) setState(() => _locationStatus = _LocationStatus.unavailable);
        return null;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (mounted) setState(() => _locationStatus = _LocationStatus.denied);
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      if (mounted) setState(() => _locationStatus = _LocationStatus.available);
      return position;
    } catch (_) {
      if (mounted) setState(() => _locationStatus = _LocationStatus.unavailable);
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TrendFitTopBar(),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar()
                  .animate()
                  .fadeIn(duration: AppMotion.base)
                  .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 32),
              _buildSectionHeader()
                  .animate()
                  .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger)
                  .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 24),
              _buildBody()
                  .animate()
                  .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * 2)
                  .slideY(begin: 0.05, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
              const SizedBox(height: 40),
              _buildTrendReport()
                  .animate()
                  .fadeIn(duration: AppMotion.base, delay: AppMotion.stagger * 3)
                  .slideY(begin: 0.05, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// 홈을 좀 더 다채롭게 — 실제 트렌드 매체(보그 코리아·W코리아·하입비스트 코리아)에서 긁어온
  /// 사진들을 가로 갤러리로 보여준다. 탭하면 원문 기사로 이동한다.
  Widget _buildTrendReport() {
    return FutureBuilder<List<TrendArticle>>(
      future: _trendReportFuture,
      builder: (context, snapshot) {
        final articles = snapshot.data ?? [];
        if (snapshot.connectionState != ConnectionState.done || articles.isEmpty) {
          return const SizedBox.shrink();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('TREND REPORT', style: AppTextStyles.trackedLabel.copyWith(letterSpacing: 2)),
            const SizedBox(height: 4),
            Text('오늘의 트렌드 리포트', style: AppTextStyles.headingBold),
            const SizedBox(height: 16),
            SizedBox(
              height: 220,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: articles.length,
                separatorBuilder: (_, __) => const SizedBox(width: 12),
                itemBuilder: (context, index) => _trendCard(articles[index]),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _trendCard(TrendArticle article) {
    return InkWell(
      onTap: () => _openLink(article.link),
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Container(
        width: 160,
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.soft),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: AppColors.chipBackground),
              Image.network(
                article.imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withValues(alpha: 0.65)],
                  ),
                ),
              ),
              Positioned(
                left: 12,
                right: 12,
                bottom: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(article.sourceName.toUpperCase(),
                        style: const TextStyle(color: AppColors.white, fontSize: 10, letterSpacing: 1)),
                    const SizedBox(height: 4),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border.fromBorderSide(BorderSide(color: AppColors.black)),
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: AppShadows.soft,
      ),
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Row(
          children: [
            const SizedBox(width: 8),
            const Icon(Icons.auto_awesome, size: 20, color: AppColors.textSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _controller,
                style: const TextStyle(fontSize: 16, color: AppColors.textPrimary),
                decoration: const InputDecoration(
                  isDense: true,
                  border: InputBorder.none,
                  hintText: '흰 치마인데 뭐랑 매치하지?',
                ),
                onSubmitted: (_) => _requestRecommendation(),
              ),
            ),
            SizedBox(
              height: 40,
              child: ElevatedButton(
                onPressed: _loading ? null : _requestRecommendation,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 24)),
                child: _loading
                    ? const SizedBox(
                        height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                    : const Text('SEARCH'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('오늘의 추천 코디', style: AppTextStyles.headingBold),
        InkWell(
          onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const CalendarScreen())),
          child: const DecoratedBox(
            decoration: BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.textSecondary))),
            child: Padding(
              padding: EdgeInsets.only(bottom: 2),
              child: Text('VIEW MORE'),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Text(_errorMessage!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.danger)),
      );
    }

    final result = _result;
    if (result == null) {
      return AspectRatio(
        aspectRatio: 4 / 5,
        child: Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.card),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(color: AppColors.chipBackground),
                // 아직 추천 결과가 없을 때 보여주는 예시 이미지(임시 무드 사진).
                Image.network(
                  'https://images.unsplash.com/photo-1525507119028-ed4c629a60a3?w=400&q=80&auto=format&fit=crop',
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black.withValues(alpha: 0.55)],
                    ),
                  ),
                ),
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text(
                      '위에 오늘 입을 옷을 물어보면\n실제 옷장 사진으로 코디를 추천해드려요.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.white, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final items = result.items;
    final hero = items.isNotEmpty ? items.first : null;
    final keyPiece = items.length > 1 ? items[1] : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AspectRatio(
          aspectRatio: 4 / 5,
          child: Container(
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(AppRadius.card), boxShadow: AppShadows.card),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.card),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Container(color: AppColors.chipBackground),
                  if (hero?.croppedImagePath != null)
                    Image.network(_apiService.imageUrl(hero!.croppedImagePath!), fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black.withValues(alpha: 0.6)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 24,
                    right: 24,
                    bottom: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (items.isEmpty)
                          const Text('추천할 조합을 찾지 못했어요. 옷장을 더 채워보세요.', style: TextStyle(color: AppColors.white))
                        else ...[
                          const Text('TODAY\'S PICK', style: TextStyle(color: AppColors.white, fontSize: 12, letterSpacing: 1.2)),
                          const SizedBox(height: 8),
                          Text('오늘의 추천 코디', style: AppTextStyles.headingBold.copyWith(color: AppColors.white)),
                          if (result.stylingNote != null) ...[
                            const SizedBox(height: 8),
                            Text(result.stylingNote!, style: AppTextStyles.bodyOnDark.copyWith(fontSize: 14)),
                          ],
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (keyPiece != null) ...[
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.white,
              border: Border.all(color: AppColors.borderSubtle),
              borderRadius: BorderRadius.circular(AppRadius.card),
              boxShadow: AppShadows.soft,
            ),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('TODAY\'S KEY PIECE', style: TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(keyPiece.category, style: AppTextStyles.headingBold),
                  const SizedBox(height: 16),
                  if (keyPiece.croppedImagePath != null)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: SizedBox(
                        height: 180,
                        width: double.infinity,
                        child: Image.network(_apiService.imageUrl(keyPiece.croppedImagePath!), fit: BoxFit.cover),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
        if (result.plusOne != null) ...[
          const SizedBox(height: 24),
          DecoratedBox(
            decoration: BoxDecoration(color: AppColors.black, borderRadius: BorderRadius.circular(AppRadius.card)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (result.plusOne!.productImageUrl != null) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.button),
                      child: Image.network(
                        result.plusOne!.productImageUrl!,
                        width: 64,
                        height: 64,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                      ),
                    ),
                    const SizedBox(width: 16),
                  ],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('+1 아이템 제안', style: TextStyle(color: AppColors.white, fontSize: 14, letterSpacing: 1.4)),
                        const SizedBox(height: 12),
                        Text(result.plusOne!.itemName,
                            style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                        if (result.plusOne!.reason != null) ...[
                          const SizedBox(height: 6),
                          Text(result.plusOne!.reason!, style: AppTextStyles.bodyOnDark),
                        ],
                        if (result.plusOne!.productUrl != null) ...[
                          const SizedBox(height: 14),
                          InkWell(
                            onTap: () => _openLink(result.plusOne!.productUrl!),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (result.plusOne!.price != null) ...[
                                  Text('${result.plusOne!.price}원',
                                      style: const TextStyle(color: AppColors.white, fontWeight: FontWeight.w700, fontSize: 14)),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  result.plusOne!.mallName != null
                                      ? '${result.plusOne!.mallName}에서 보기'
                                      : '구매하러 가기',
                                  style: const TextStyle(color: AppColors.white, decoration: TextDecoration.underline, fontSize: 13),
                                ),
                                const SizedBox(width: 2),
                                const Icon(Icons.arrow_outward, size: 14, color: AppColors.white),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        if (items.isNotEmpty) ...[
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => RecommendationResultScreen(result: result)),
              ),
              child: const Text('전체 코디 자세히 보기'),
            ),
          ),
        ],
      ],
    );
  }
}
