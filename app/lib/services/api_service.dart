import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../config/app_session.dart';
import '../models/clothing_item.dart';
import '../models/recommendation_history.dart';
import '../models/recommendation_result.dart';
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

  Future<void> submitOnboarding(int userId, List<String> styleTags, String? bodyInfo) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/onboarding?userId=$userId'),
      headers: _authHeaders,
      body: jsonEncode({'styleTags': styleTags, 'bodyInfo': bodyInfo}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
  }

  Future<UserPreference> fetchOnboarding(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/users/onboarding?userId=$userId'), headers: _authHeaders);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return UserPreference.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 회원관리 — 로그인된 본인 계정 정보 조회. (/api/users/me, JWT 인증 필요)
  Future<UserMe> fetchMe() async {
    final res = await http.get(Uri.parse('$baseUrl/api/users/me'), headers: _authHeaders);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return UserMe.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 회원관리 — 회원 탈퇴. (/api/users/me DELETE, JWT 인증 필요)
  Future<void> deleteAccount() async {
    final res = await http.delete(Uri.parse('$baseUrl/api/users/me'), headers: _authHeaders);
    if (res.statusCode != 200 && res.statusCode != 204) {
      throw _apiError(res);
    }
  }

  Future<List<ClothingItem>> fetchClosetItems(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/closet/items?userId=$userId'), headers: _authHeaders);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => ClothingItem.fromJson(e)).toList();
  }

  /// 다중 이미지 일괄 업로드. 반환값은 Vision 태깅만 끝난 미확정(unconfirmed) 아이템들이며,
  /// [confirmClosetItem]으로 핏/재질을 확정해야 옷장에서 완전히 쓸 수 있다.
  Future<List<ClothingItem>> uploadClosetItems(int userId, List<XFile> images) async {
    final uri = Uri.parse('$baseUrl/api/closet/items?userId=$userId');
    final request = http.MultipartRequest('POST', uri);
    final token = AppSession.accessToken;
    if (token != null) request.headers['Authorization'] = 'Bearer $token';
    for (final image in images) {
      final bytes = await image.readAsBytes();
      request.files.add(http.MultipartFile.fromBytes('images', bytes, filename: image.name));
    }

    final streamed = await request.send();
    final res = await http.Response.fromStream(streamed);
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => ClothingItem.fromJson(e)).toList();
  }

  Future<ClothingItem> confirmClosetItem(int itemId, {required String fit, String? material}) async {
    final res = await http.patch(
      Uri.parse('$baseUrl/api/closet/items/$itemId/confirm'),
      headers: _authHeaders,
      body: jsonEncode({'fit': fit, 'material': material}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return ClothingItem.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// [lat]/[lon]을 생략하면 서버가 서울시청 좌표를 기본값으로 쓴다(RecommendationRequest 참고).
  Future<RecommendationResult> requestRecommendation(int userId, String requestText, {double? lat, double? lon}) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/recommendations?userId=$userId'),
      headers: _authHeaders,
      body: jsonEncode({'requestText': requestText, 'lat': lat, 'lon': lon}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return RecommendationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  /// 캘린더(위클리 아카이브). [weekStart]를 생략하면 서버가 이번 주 월요일부터 조회한다.
  Future<List<RecommendationHistoryItem>> fetchWeeklyHistory(int userId, {DateTime? weekStart}) async {
    final query = weekStart == null
        ? 'userId=$userId'
        : 'userId=$userId&weekStart=${weekStart.toIso8601String().substring(0, 10)}';
    final res = await http.get(Uri.parse('$baseUrl/api/recommendations/history?$query'), headers: _authHeaders);
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
