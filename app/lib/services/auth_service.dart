import 'dart:convert';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../models/auth_result.dart';

/// Google 로그인(google_sign_in) + 백엔드 JWT 발급/재발급/로그아웃 연동.
/// (conventions.md §4 — Google OAuth2 로그인 + JWT 세션)
class AuthService {
  AuthService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final String baseUrl;

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: const ['email', 'profile'],
    clientId: AppConfig.googleWebClientId,
  );

  /// Google 로그인 팝업을 띄우고, 발급받은 액세스 토큰으로 백엔드에 로그인/가입을 요청한다.
  /// Flutter Web에서는 ID 토큰이 아니라 OAuth2 액세스 토큰만 발급되므로(백엔드
  /// GoogleTokenVerifier가 이를 UserInfo 엔드포인트로 검증) accessToken을 사용한다.
  /// 사용자가 팝업을 닫아 로그인을 취소하면 null을 반환한다.
  Future<AuthResult?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final accessToken = googleAuth.accessToken;
    if (accessToken == null) {
      throw Exception('Google 로그인 토큰을 가져오지 못했습니다. 잠시 후 다시 시도해주세요.');
    }

    final res = await http.post(
      Uri.parse('$baseUrl/api/auth/google'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'accessToken': accessToken}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }

    final result = AuthResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    await AppSession.save(
      userId: result.userId,
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      email: result.email,
      nickname: result.nickname,
      onboardingCompleted: result.onboardingCompleted,
    );
    return result;
  }

  /// 서버(리프레시 토큰 무효화)와 Google 세션 모두 로그아웃하고 로컬 세션을 비운다.
  Future<void> logout() async {
    final token = AppSession.accessToken;
    try {
      if (token != null) {
        await http.post(
          Uri.parse('$baseUrl/api/auth/logout'),
          headers: {'Authorization': 'Bearer $token'},
        );
      }
    } catch (_) {
      // 서버 로그아웃 실패해도 로컬 세션은 비운다 — 토큰 만료로 인한 401 등은 무시 가능.
    }
    await _googleSignIn.signOut();
    await AppSession.clear();
  }

  Exception _apiError(http.Response res) {
    try {
      final body = jsonDecode(utf8.decode(res.bodyBytes));
      final message = body is Map ? body['message'] : null;
      if (message is String && message.isNotEmpty) {
        return Exception(message);
      }
    } catch (_) {
      // 본문이 JSON이 아니면 아래 기본 메시지로 폴백한다.
    }
    return Exception('로그인 처리 중 오류가 발생했습니다. (${res.statusCode})');
  }
}
