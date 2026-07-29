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
/// productUrl 등은 네이버쇼핑 검색 API(A6, 2026-07-29 결정)로 매칭된 실제 판매 상품 정보다 —
/// 매칭되는 상품이 없으면 모두 null이며, 이 경우 프론트는 링크 없이 itemName/reason만 보여준다.
class PlusOneSuggestion {
  final String itemName;
  final String? reason;
  final String? category;
  final String? productUrl;
  final String? productImageUrl;
  final String? mallName;
  final String? price;

  PlusOneSuggestion({
    required this.itemName,
    this.reason,
    this.category,
    this.productUrl,
    this.productImageUrl,
    this.mallName,
    this.price,
  });

  factory PlusOneSuggestion.fromJson(Map<String, dynamic> json) {
    return PlusOneSuggestion(
      itemName: json['itemName'],
      reason: json['reason'],
      category: json['category'],
      productUrl: json['productUrl'],
      productImageUrl: json['productImageUrl'],
      mallName: json['mallName'],
      price: json['price'],
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
