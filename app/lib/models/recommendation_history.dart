import 'recommendation_result.dart';

/// 백엔드 RecommendationHistoryItemResponse에 대응. 캘린더(위클리 아카이브) 화면에서 쓴다.
class RecommendationHistoryItem {
  final int logId;
  final DateTime date;
  final List<RecommendedClothingItem> items;
  final String? requestText;
  final String? wornPhotoUrl;

  RecommendationHistoryItem({
    required this.logId,
    required this.date,
    required this.items,
    this.requestText,
    this.wornPhotoUrl,
  });

  factory RecommendationHistoryItem.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];
    return RecommendationHistoryItem(
      logId: json['logId'],
      date: DateTime.parse(json['date']),
      items: itemsJson.map((e) => RecommendedClothingItem.fromJson(e)).toList(),
      requestText: json['requestText'],
      wornPhotoUrl: json['wornPhotoUrl'],
    );
  }
}
