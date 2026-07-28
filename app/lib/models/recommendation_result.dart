/// 백엔드 RecommendedItemResponse에 대응.
class RecommendedClothingItem {
  final int id;
  final String category;
  final String? croppedImagePath;

  RecommendedClothingItem({
    required this.id,
    required this.category,
    this.croppedImagePath,
  });

  factory RecommendedClothingItem.fromJson(Map<String, dynamic> json) {
    return RecommendedClothingItem(
      id: json['id'],
      category: json['category'],
      croppedImagePath: json['croppedImagePath'],
    );
  }
}

/// 백엔드 PlusOneResponse에 대응.
class PlusOneSuggestion {
  final String itemName;
  final String? reason;
  final String? category;

  PlusOneSuggestion({required this.itemName, this.reason, this.category});

  factory PlusOneSuggestion.fromJson(Map<String, dynamic> json) {
    return PlusOneSuggestion(
      itemName: json['itemName'],
      reason: json['reason'],
      category: json['category'],
    );
  }
}

/// 백엔드 RecommendationResponse에 대응.
class RecommendationResult {
  final int logId;
  final List<RecommendedClothingItem> items;
  final String? stylingNote;
  final PlusOneSuggestion? plusOne;

  RecommendationResult({
    required this.logId,
    required this.items,
    this.stylingNote,
    this.plusOne,
  });

  factory RecommendationResult.fromJson(Map<String, dynamic> json) {
    final List<dynamic> itemsJson = json['items'] ?? [];
    return RecommendationResult(
      logId: json['logId'],
      items: itemsJson.map((e) => RecommendedClothingItem.fromJson(e)).toList(),
      stylingNote: json['stylingNote'],
      plusOne: json['plusOne'] == null ? null : PlusOneSuggestion.fromJson(json['plusOne']),
    );
  }
}
