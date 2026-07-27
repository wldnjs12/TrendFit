import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/clothing_item.dart';

/// 백엔드 REST API 호출 서비스.
/// baseUrl 은 로컬 개발 시 backend(:8080) 를 가리키며,
/// 실기기 테스트 시 PC의 로컬 IP로 교체해야 한다.
///
/// TODO(5주차): 온보딩/옷장/추천 화면과 실제로 연결.
class ApiService {
  ApiService({this.baseUrl = 'http://localhost:8080'});

  final String baseUrl;

  Future<List<ClothingItem>> fetchClosetItems(int userId) async {
    final res = await http.get(Uri.parse('$baseUrl/api/closet/items?userId=$userId'));
    if (res.statusCode != 200) {
      throw Exception('옷장 조회 실패: ${res.statusCode}');
    }
    final List<dynamic> body = jsonDecode(utf8.decode(res.bodyBytes));
    return body.map((e) => ClothingItem.fromJson(e)).toList();
  }

  Future<Map<String, dynamic>> requestRecommendation(int userId, String requestText) async {
    final res = await http.post(
      Uri.parse('$baseUrl/api/recommendations?userId=$userId'),
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'requestText': requestText}),
    );
    if (res.statusCode != 200) {
      throw Exception('추천 요청 실패: ${res.statusCode}');
    }
    return jsonDecode(utf8.decode(res.bodyBytes));
  }
}
