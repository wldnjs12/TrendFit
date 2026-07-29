import 'package:shared_preferences/shared_preferences.dart';

/// 로그인 세션(JWT + 사용자 식별 정보)을 앱 전역에서 들고 있는 정적 홀더.
/// SharedPreferences에 영속화해 앱을 재시작해도 로그인 상태가 유지되도록 한다
/// (회원관리 요구사항 — 로그인 세션 유지).
class AppSession {
  const AppSession._();

  static int? userId;
  static String? accessToken;
  static String? refreshToken;
  static String? email;
  static String? nickname;

  /// 로그인 시점의 onboardingCompleted 서버 응답을 세션에도 들고 있는다 — 온보딩(회원정보+
  /// 스타일 취향 2단계)을 끝내기 전에 새로고침/재접속하면 로그인 세션은 이미 저장돼 있어서,
  /// 이 값 없이 isLoggedIn만 보면 스플래시가 온보딩을 건너뛰고 바로 홈으로 보내버린다.
  static bool onboardingCompleted = false;

  static bool get isLoggedIn => userId != null && accessToken != null;

  static const _keyUserId = 'session.userId';
  static const _keyAccessToken = 'session.accessToken';
  static const _keyRefreshToken = 'session.refreshToken';
  static const _keyEmail = 'session.email';
  static const _keyNickname = 'session.nickname';
  static const _keyOnboardingCompleted = 'session.onboardingCompleted';

  /// 앱 시작 시 저장된 세션을 복원한다.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt(_keyUserId);
    accessToken = prefs.getString(_keyAccessToken);
    refreshToken = prefs.getString(_keyRefreshToken);
    email = prefs.getString(_keyEmail);
    nickname = prefs.getString(_keyNickname);
    onboardingCompleted = prefs.getBool(_keyOnboardingCompleted) ?? false;
  }

  static Future<void> save({
    required int userId,
    required String accessToken,
    required String refreshToken,
    required String email,
    required String nickname,
    required bool onboardingCompleted,
  }) async {
    AppSession.userId = userId;
    AppSession.accessToken = accessToken;
    AppSession.refreshToken = refreshToken;
    AppSession.email = email;
    AppSession.nickname = nickname;
    AppSession.onboardingCompleted = onboardingCompleted;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyNickname, nickname);
    await prefs.setBool(_keyOnboardingCompleted, onboardingCompleted);
  }

  /// 최초 온보딩(회원정보+스타일 취향)을 끝냈을 때 호출 — 이후 재접속 시 스플래시가 다시
  /// 온보딩 화면으로 보내지 않도록 세션에도 반영한다.
  static Future<void> markOnboardingCompleted() async {
    onboardingCompleted = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyOnboardingCompleted, true);
  }

  /// 로그아웃/회원탈퇴 시 로컬 세션을 완전히 비운다.
  static Future<void> clear() async {
    userId = null;
    accessToken = null;
    refreshToken = null;
    email = null;
    nickname = null;
    onboardingCompleted = false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyNickname);
    await prefs.remove(_keyOnboardingCompleted);
  }
}
