import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../models/user_me.dart';
import '../models/user_preference.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../widgets/trendfit_top_bar.dart';
import 'login_screen.dart';
import 'style_preference_screen.dart';

/// 프로필 v2 — 취향 태그 조회/재설정, 계정 정보. (Figma "프로필 v2", CLAUDE.md §4)
/// 로그인 세션(AppSession)의 이메일/닉네임을 표시하고, 로그아웃/회원탈퇴는 각각
/// AuthService.logout() / ApiService.deleteAccount()로 백엔드와 실제 연동된다.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final AuthService _authService = AuthService();
  final ImagePicker _picker = ImagePicker();
  late Future<UserPreference> _preferenceFuture;
  bool _processingAccountAction = false;
  String _locationSubtitle = '위치 확인 중...';
  bool _locationTappable = false;

  UserMe? _me;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
    _loadLocation();
    _loadMe();
  }

  void _load() {
    _preferenceFuture = _apiService.fetchOnboarding(AppSession.userId!);
  }

  Future<void> _loadMe() async {
    try {
      final me = await _apiService.fetchMe();
      if (mounted) setState(() => _me = me);
    } catch (_) {
      // 프로필 사진은 부가 정보라 조회 실패해도 화면 전체를 막지 않는다.
    }
  }

  Future<void> _pickProfileImage() async {
    // 웹은 imageQuality를 지원하지 않아 maxWidth/maxHeight로 원본 크기를 제한한다 —
    // 안 그러면 큰 사진이 서버의 multipart 크기 제한에 걸려 브라우저에 "Load failed"로만
    // 보이는 네트워크 에러가 난다. 아바타는 800px면 충분하다.
    final image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 800, maxHeight: 800);
    if (image == null) return;
    setState(() => _uploadingPhoto = true);
    try {
      final url = await _apiService.uploadProfileImage(image);
      if (!mounted) return;
      setState(() {
        _me = _me == null
            ? null
            : UserMe(id: _me!.id, email: _me!.email, nickname: _me!.nickname, profileImageUrl: url, createdAt: _me!.createdAt);
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('프로필 사진 등록에 실패했어요: $e')));
    } finally {
      if (mounted) setState(() => _uploadingPhoto = false);
    }
  }

  /// 실제 기기 위치 권한 상태를 그대로 보여준다 — 예전엔 "서울시 강남구"가 항상
  /// 하드코딩되어 있고 탭해도 반응이 없는 가짜 UI였다.
  Future<void> _loadLocation() async {
    setState(() {
      _locationSubtitle = '위치 확인 중...';
      _locationTappable = false;
    });
    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        if (!mounted) return;
        setState(() {
          _locationSubtitle = '기기 위치 서비스가 꺼져 있어요';
          _locationTappable = true;
        });
        return;
      }
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        setState(() {
          _locationSubtitle = '위치 접근이 거부되어 있어요 (탭하여 다시 시도)';
          _locationTappable = true;
        });
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.low),
      );
      final placeName = await LocationService.reverseGeocode(position.latitude, position.longitude);
      if (!mounted) return;
      setState(() {
        _locationSubtitle = placeName ?? '위치를 확인했지만 지역명을 가져오지 못했어요';
        _locationTappable = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _locationSubtitle = '위치를 가져오지 못했어요 (탭하여 다시 시도)';
        _locationTappable = true;
      });
    }
  }

  Future<void> _reconfigure() async {
    final current = await _preferenceFuture;
    if (!mounted) return;
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => StylePreferenceScreen(initialTags: current.styleTags, initialBodyInfo: current.bodyInfo),
      ),
    );
    if (changed == true) {
      setState(_load);
    }
  }

  Future<void> _logout() async {
    setState(() => _processingAccountAction = true);
    try {
      await _authService.logout();
      _goToLogin();
    } finally {
      if (mounted) setState(() => _processingAccountAction = false);
    }
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('회원 탈퇴'),
        content: const Text('탈퇴하면 계정 정보와 취향 프로필이 삭제되며 되돌릴 수 없습니다.\n정말 탈퇴하시겠어요?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('취소')),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('탈퇴', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _processingAccountAction = true);
    try {
      await _apiService.deleteAccount();
      await _authService.logout();
      _goToLogin();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _processingAccountAction = false);
    }
  }

  void _goToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const TrendFitTopBar(),
      body: SafeArea(
        top: false,
        child: FutureBuilder<UserPreference>(
          future: _preferenceFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(
                child: Text('아직 온보딩을 완료하지 않았어요.\n${snapshot.error}', textAlign: TextAlign.center),
              );
            }

            final preference = snapshot.data!;
            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildIdentity()
                      .animate()
                      .fadeIn(duration: AppMotion.base)
                      .slideY(begin: 0.08, end: 0, duration: AppMotion.base, curve: AppMotion.enter),
                  const SizedBox(height: 32),
                  _sectionLabel('PREFERENCE'),
                  const SizedBox(height: 12),
                  _actionRow(
                    icon: Icons.refresh,
                    label: '취향 재설정',
                    subtitle: preference.styleTags.isEmpty ? '설정된 취향이 없어요' : preference.styleTags.join(' · '),
                    onTap: _reconfigure,
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel('ADDITIONAL INFO'),
                  const SizedBox(height: 12),
                  if (preference.bodyInfo != null && preference.bodyInfo!.isNotEmpty)
                    _infoRow('BODY INFO', preference.bodyInfo!)
                  else
                    _infoRow('BODY INFO', '등록된 정보가 없어요'),
                  const SizedBox(height: 8),
                  Text(
                    '* 성별과 체형 정보는 개인화된 스타일 추천을 위해 정교하게 활용됩니다.',
                    style: TextStyle(color: AppColors.textTertiary.withValues(alpha: 0.8), fontSize: 11),
                  ),
                  const SizedBox(height: 32),
                  _sectionLabel('ENVIRONMENT'),
                  const SizedBox(height: 12),
                  _actionRow(
                    icon: Icons.location_on_outlined,
                    label: '지역 및 날씨',
                    subtitle: _locationSubtitle,
                    onTap: _locationTappable ? _loadLocation : null,
                  ),
                  const SizedBox(height: 40),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _processingAccountAction ? null : _logout,
                        child: const Text('LOGOUT', style: TextStyle(color: AppColors.textPrimary, letterSpacing: 1)),
                      ),
                      TextButton(
                        onPressed: _processingAccountAction ? null : _deleteAccount,
                        child: const Text('DELETE ACCOUNT', style: TextStyle(color: AppColors.danger, letterSpacing: 1)),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildIdentity() {
    final nickname = AppSession.nickname ?? 'TRENDFIT USER';
    final email = AppSession.email ?? '';
    final profileImageUrl = _me?.profileImageUrl;
    return Row(
      children: [
        InkWell(
          onTap: _uploadingPhoto ? null : _pickProfileImage,
          customBorder: const CircleBorder(),
          child: Stack(
            children: [
              ClipOval(
                child: Container(
                  width: 64,
                  height: 64,
                  color: AppColors.chipBackground,
                  child: profileImageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: _apiService.imageUrl(profileImageUrl),
                          fit: BoxFit.cover,
                          errorWidget: (context, url, error) =>
                              const Icon(Icons.person, color: AppColors.textTertiary, size: 32),
                        )
                      : const Icon(Icons.person, color: AppColors.textTertiary, size: 32),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.black,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: _uploadingPhoto
                        ? const SizedBox(
                            width: 10, height: 10, child: CircularProgressIndicator(strokeWidth: 1.5, color: AppColors.white))
                        : const Icon(Icons.add_a_photo_outlined, size: 10, color: AppColors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(nickname, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(height: 2),
              Text(email, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionLabel(String text) {
    return DecoratedBox(
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.black))),
      child: Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text, style: AppTextStyles.trackedLabelBig.copyWith(color: AppColors.textPrimary)),
      ),
    );
  }

  Widget _actionRow({required IconData icon, required String label, String? subtitle, VoidCallback? onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.textPrimary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(subtitle, style: const TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                  ],
                ],
              ),
            ),
            if (onTap != null) const Icon(Icons.chevron_right, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.textTertiary, fontSize: 12, letterSpacing: 1)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontSize: 15)),
        ],
      ),
    );
  }
}
