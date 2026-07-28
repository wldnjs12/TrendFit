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

  static bool get isLoggedIn => userId != null && accessToken != null;

  static const _keyUserId = 'session.userId';
  static const _keyAccessToken = 'session.accessToken';
  static const _keyRefreshToken = 'session.refreshToken';
  static const _keyEmail = 'session.email';
  static const _keyNickname = 'session.nickname';

  /// 앱 시작 시 저장된 세션을 복원한다.
  static Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    userId = prefs.getInt(_keyUserId);
    accessToken = prefs.getString(_keyAccessToken);
    refreshToken = prefs.getString(_keyRefreshToken);
    email = prefs.getString(_keyEmail);
    nickname = prefs.getString(_keyNickname);
  }

  static Future<void> save({
    required int userId,
    required String accessToken,
    required String refreshToken,
    required String email,
    required String nickname,
  }) async {
    AppSession.userId = userId;
    AppSession.accessToken = accessToken;
    AppSession.refreshToken = refreshToken;
    AppSession.email = email;
    AppSession.nickname = nickname;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyUserId, userId);
    await prefs.setString(_keyAccessToken, accessToken);
    await prefs.setString(_keyRefreshToken, refreshToken);
    await prefs.setString(_keyEmail, email);
    await prefs.setString(_keyNickname, nickname);
  }

  /// 로그아웃/회원탈퇴 시 로컬 세션을 완전히 비운다.
  static Future<void> clear() async {
    userId = null;
    accessToken = null;
    refreshToken = null;
    email = null;
    nickname = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyAccessToken);
    await prefs.remove(_keyRefreshToken);
    await prefs.remove(_keyEmail);
    await prefs.remove(_keyNickname);
  }
}
