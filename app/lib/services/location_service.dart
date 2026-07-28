import 'dart:convert';
import 'package:http/http.dart' as http;

/// 위경도를 "경기도 안성시" 같은 사람이 읽을 수 있는 지역명으로 바꾼다.
/// 무료·API 키 불필요한 OpenStreetMap Nominatim을 쓴다(요청 빈도가 낮은
/// 개인용 위치 표시 정도라 사용 정책 범위 안에 든다).
class LocationService {
  const LocationService._();

  static Future<String?> reverseGeocode(double lat, double lon) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse'
        '?format=json&lat=$lat&lon=$lon&accept-language=ko&zoom=10',
      );
      final res = await http.get(uri, headers: {'Accept': 'application/json'}).timeout(const Duration(seconds: 6));
      if (res.statusCode != 200) return null;

      final body = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
      final address = body['address'] as Map<String, dynamic>?;
      if (address == null) return null;

      final province = address['province'] as String?;
      final city = address['city'] as String?;
      final borough = (address['borough'] ?? address['county'] ?? address['city_district']) as String?;

      if (province != null && city != null) return '$province $city';
      if (city != null && borough != null) return '$city $borough';
      return city ?? province ?? borough ?? body['display_name'] as String?;
    } catch (_) {
      return null;
    }
  }
}
