/// MVP 단계 공통 설정.
///
/// 실기기 테스트 시 [apiBaseUrl]을 PC의 로컬 IP로 교체해야 한다.
class AppConfig {
  const AppConfig._();

  /// 배포 빌드(Vercel)에서는 --dart-define=API_BASE_URL=https://<railway-domain>으로
  /// 오버라이드한다(app/vercel-build.sh 참고). 로컬 개발(flutter run)은 기본값(localhost:8080)을 쓴다.
  static const String apiBaseUrl =
      String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8080');

  /// Google Cloud Console "OAuth 2.0 클라이언트 ID" (웹 애플리케이션 유형). 비밀값이 아니라
  /// 클라이언트 코드에 그대로 둬도 되는 공개 식별자다. backend의 .env(TRENDFIT_ID),
  /// web/index.html의 google-signin-client_id meta 태그와 반드시 같은 값이어야 한다.
  static const String googleWebClientId =
      '406450564519-1bpdop9rh4s3dfiud5fst2fqs39o4d9p.apps.googleusercontent.com';
}
