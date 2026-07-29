import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/app_session.dart';
import '../models/clothing_item.dart';
import '../models/recommendation_history.dart';
import '../models/recommendation_result.dart';
import '../models/trend_article.dart';
import '../models/user_me.dart';
import '../models/user_preference.dart';

/// 백엔드 REST API 호출 서비스.
/// baseUrl 은 로컬 개발 시 backend(:8080) 를 가리키며,
/// 실기기 테스트 시 PC의 로컬 IP로 교체해야 한다.
class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8080'});

  final String baseUrl;

  /// 서버가 내려준 상대 이미지 경로("/api/images/...")를 실제로 fetch 가능한 URL로 만든다.
  String imageUrl(String path) => '$baseUrl$path';

  /// 로그인 세션(JWT)이 있으면 Authorization 헤더를 함께 보낸다.
  /// (/api/users/me 등 인증이 필요한 엔드포인트에서 사용, conventions.md §4)
  Map<String, String> get _authHeaders {
    final token = AppSession.accessToken;
    return {
      'Content-Type': 'application/json; charset=UTF-8',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// 액세스 토큰(유효기간 30분)이 만료돼 401이 오면 리프레시 토큰으로 한 번 재발급받아
  /// 같은 요청을 재시도한다. 세션이 오래 열려있어도 "로그인이 필요합니다" 오류 없이
  /// 자연스럽게 이어지도록 하기 위함이다 — [send]는 매 호출마다 최신 _authHeaders를
  /// 다시 읽어야 하므로 헤더를 미리 만들지 말고 클로저 안에서 만들어야 한다.
  Future<http.Response> _withAuthRetry(Future<http.Response> Function() send) async {
    var res = await send();
    if (res.statusCode == 401 && await _refreshSession()) {
      res = await send();
    }
    return res;
  }

  /// 서버가 리프레시 토큰을 매번 새로 발급/교체(rotation)하기 때문에, 화면 진입 시 흔한
  /// 여러 API 동시 호출이 각자 401 -> refresh를 따로 시도하면 먼저 도착한 요청이 토큰을
  /// 교체해버려 나머지 요청들은 "이미 교체된(구) 토큰"으로 refresh를 시도해 실패한다 —
  /// 실제로는 로그인 세션이 멀쩡한데도 "로그인이 필요합니다" 오류가 뜨는 원인이었다.
  /// 진행 중인 refresh를 정적으로 공유해 앱 전체에서 실제 HTTP 요청은 한 번만 나가도록 한다.
  static Future<bool>? _refreshInFlight;

  Future<bool> _refreshSession() {
    return _refreshInFlight ??= _doRefresh().whenComplete(() => _refreshInFlight = null);
  }

  Future<bool> _doRefresh() async {
    final refreshToken = AppSession.refreshToken;
    if (refreshToken == null) return false;
    try {
      final res = await http.post(
        Uri.parse('$baseUrl/api/auth/refresh'),
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );
      if (res.statusCode != 200) return false;

      final body = jsonDecode(utf8.decode(res.bodyBytes));
      await AppSession.save(
        userId: body['userId'],
        accessToken: body['accessToken'],
        refreshToken: body['refreshToken'],
        email: body['email'],
        nickname: body['nickname'],
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> submitOnboarding(int userId, List<String> styleTags, String? bodyInfo) async {
    final res = await _withAuthRetry(() => http.post(
          Uri.parse('$baseUrl/api/users/onboarding?userId=$userId'),
          headers: _authHeaders,
          body: jsonEncode({'styleTags': styleTags, 'bodyInfo': bodyInfo}),
        ));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
  }

  Future<UserPreference> fetchOnboarding(int userId) async {
    final res = await _withAuthRetry(
        () => http.get(Uri.parse('$baseUrl/api/users/onboarding?userId=$userId'), headers: _authHeaders));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return UserPreference.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 회원관리 — 로그인된 본인 계정 정보 조회. (/api/users/me, JWT 인증 필요)
  Future<UserMe> fetchMe() async {
    final res =
        await _withAuthRetry(() => http.get(Uri.parse('$baseUrl/api/users/me'), headers: _authHeaders));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return UserMe.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 회원관리 — 프로필 사진 등록/교체. (/api/users/me/profile-image, JWT 인증 필요)
  Future<String> uploadProfileImage(XFile image) async {
    Future<http.Response> send() async {
      final uri = Uri.parse('$baseUrl/api/users/me/profile-image');
      final request = http.MultipartRequest('POST', uri);
      final token = AppSession.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    final res = await _withAuthRetry(send);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['profileImageUrl'] as String;
  }

  /// 회원관리 — 회원 탈퇴. (/api/users/me DELETE, JWT 인증 필요)
  Future<void> deleteAccount() async {
    final res =
        await _withAuthRetry(() => http.delete(Uri.parse('$baseUrl/api/users/me'), headers: _authHeaders));
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _apiError(res);
    }
  }

  Future<List<ClothingItem>> fetchClosetItems(int userId) async {
    final res = await _withAuthRetry(
        () => http.get(Uri.parse('$baseUrl/api/closet/items?userId=$userId'), headers: _authHeaders));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => ClothingItem.fromJson(e)).toList();
  }

  /// 다중 이미지 일괄 업로드. 반환값은 Vision 태깅만 끝난 미확정(unconfirmed) 아이템들이며,
  /// [confirmClosetItem]으로 핏/재질을 확정해야 옷장에서 완전히 쓸 수 있다.
  Future<List<ClothingItem>> uploadClosetItems(int userId, List<XFile> images) async {
    Future<http.Response> send() async {
      final uri = Uri.parse('$baseUrl/api/closet/items?userId=$userId');
      final request = http.MultipartRequest('POST', uri);
      final token = AppSession.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      for (final image in images) {
        final bytes = await image.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes('images', bytes, filename: image.name));
      }
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    final res = await _withAuthRetry(send);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => ClothingItem.fromJson(e)).toList();
  }

  Future<ClothingItem> confirmClosetItem(int itemId, {required String fit, String? material}) async {
    final res = await _withAuthRetry(() => http.patch(
          Uri.parse('$baseUrl/api/closet/items/$itemId/confirm'),
          headers: _authHeaders,
          body: jsonEncode({'fit': fit, 'material': material}),
        ));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return ClothingItem.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// [lat]/[lon]을 생략하면 서버가 서울시청 좌표를 기본값으로 쓴다(RecommendationRequest 참고).
  Future<RecommendationResult> requestRecommendation(int userId, String requestText, {double? lat, double? lon}) async {
    final res = await _withAuthRetry(() => http.post(
          Uri.parse('$baseUrl/api/recommendations?userId=$userId'),
          headers: _authHeaders,
          body: jsonEncode({'requestText': requestText, 'lat': lat, 'lon': lon}),
        ));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return RecommendationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 추천 결과 화면에서 "오늘의 코디로 결정하기"를 눌렀을 때만 호출한다 — 이때부터 캘린더에
  /// 노출된다(RecommendationLog.confirmed). 그냥 나가거나 "다른 옵션 추천받기"를 누르면
  /// 호출하지 않아, 받아만 보고 채택하지 않은 추천은 캘린더에 남지 않는다.
  Future<void> confirmRecommendation(int userId, int logId) async {
    final res = await _withAuthRetry(() => http.patch(
          Uri.parse('$baseUrl/api/recommendations/$logId/confirm?userId=$userId'),
          headers: _authHeaders,
        ));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
  }

  /// 캘린더에서 "오늘 실제로 입은 사진"을 등록/교체한다. AI가 추천해준 코디 이미지와는
  /// 별개로 저장된다 — Vision 재분석은 하지 않고 그대로 저장만 한다.
  Future<String> uploadWornPhoto(int userId, int logId, XFile image) async {
    Future<http.Response> send() async {
      final uri = Uri.parse('$baseUrl/api/recommendations/$logId/worn-photo?userId=$userId');
      final request = http.MultipartRequest('POST', uri);
      final token = AppSession.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    final res = await _withAuthRetry(send);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return body['wornPhotoUrl'] as String;
  }

  /// 캘린더의 빈 날짜를 눌러 착용샷만 바로 등록한다(AI 추천 없이 새 이력 생성, route 2).
  /// [forDate]는 사용자가 캘린더에서 고른 날짜 — "내일/수요일" 같은 해석이 필요 없다.
  Future<RecommendationHistoryItem> createWornPhotoEntry(int userId, DateTime forDate, XFile image) async {
    Future<http.Response> send() async {
      final dateStr = forDate.toIso8601String().substring(0, 10);
      final uri = Uri.parse('$baseUrl/api/recommendations/worn-photo?userId=$userId&forDate=$dateStr');
      final request = http.MultipartRequest('POST', uri);
      final token = AppSession.accessToken;
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: image.name));
      final streamed = await request.send();
      return http.Response.fromStream(streamed);
    }

    final res = await _withAuthRetry(send);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return RecommendationHistoryItem.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 홈 화면 "트렌드 리포트" 갤러리.
  Future<List<TrendArticle>> fetchTrendReport() async {
    final res = await http.get(Uri.parse('$baseUrl/api/trends/report'));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => TrendArticle.fromJson(e)).toList();
  }

  /// 캘린더(위클리 아카이브). [weekStart]를 생략하면 서버가 이번 주 월요일부터 조회한다.
  Future<List<RecommendationHistoryItem>> fetchWeeklyHistory(int userId, {DateTime? weekStart}) async {
    final query = weekStart == null
        ? 'userId=$userId'
        : 'userId=$userId&weekStart=${weekStart.toIso8601String().substring(0, 10)}';
    final res = await _withAuthRetry(
        () => http.get(Uri.parse('$baseUrl/api/recommendations/history?$query'), headers: _authHeaders));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => RecommendationHistoryItem.fromJson(e)).toList();
  }

  /// 백엔드 GlobalExceptionHandler가 내려주는 {"message": "..."} 형태를 그대로 노출한다.
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
    return Exception('요청 처리 중 오류가 발생했습니다. (${res.statusCode})');
  }
}
