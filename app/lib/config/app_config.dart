/// MVP 단계 공통 설정.
///
/// 로그인/회원가입(Google OAuth2)이 아직 없어 고정 userId를 쓴다 — 백엔드
/// `users` 테이블에 해당 id row가 미리 있어야 한다(수동 INSERT 필요).
/// 실기기 테스트 시 [apiBaseUrl]을 PC의 로컬 IP로 교체해야 한다.
class AppConfig {
  const AppConfig._();

  static const int currentUserId = 1;
  static const String apiBaseUrl = 'http://localhost:8080';
}
