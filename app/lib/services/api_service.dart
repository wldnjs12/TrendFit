import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/clothing_item.dart';
import '../models/recommendation_result.dart';
import '../models/user_preference.dart';

/// 백엔드 REST API 호출 서비스.
/// baseUrl 은 로컬 개발 시 backend(:8080) 를 가리키며,
/// 실기기 테스트 시 PC의 로컬 IP로 교체해야 한다.
class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8080'});

  final String baseUrl;

  /// 서버가 내려준 상대 이미지 경로("/api/images/...")를 실제로 fetch 가능한 URL로 만든다.
  String imageUrl(String path) => '$baseUrl$path';

  Future<void> submitOnboarding(int userId, List<String> styleTags, String? bodyInfo) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/users/onboarding?userId=$userId'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'styleTags': styleTags, 'bodyInfo': bodyInfo}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
  }

  Future<UserPreference> fetchOnboarding(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/users/onboarding?userId=$userId'));
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return UserPreference.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<List<ClothingItem>> fetchClosetItems(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/closet/items?userId=$userId'));
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
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'fit': fit, 'material': material}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return ClothingItem.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
  }

  Future<RecommendationResult> requestRecommendation(int userId, String requestText) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/recommendations?userId=$userId'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'requestText': requestText}),
    );
    if (res.statusCode != 200) {
      throw _apiError(res);
    }
    return RecommendationResult.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
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
