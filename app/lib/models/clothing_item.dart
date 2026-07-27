/// 백엔드 ClothingItem 엔티티에 대응하는 클라이언트 모델.
/// (backend/src/main/java/com/trendfit/domain/closet/ClothingItem.java 참고)
class ClothingItem {
  final int id;
  final String category; // TOP, BOTTOM, OUTER, DRESS, SHOES, ACCESSORY
  final String color;
  final String? pattern;
  final String? fit;
  final String? material;
  final String imagePath;
  final String? croppedImagePath;
  final bool confirmed;

  ClothingItem({
    required this.id,
    required this.category,
    required this.color,
    this.pattern,
    this.fit,
    this.material,
    required this.imagePath,
    this.croppedImagePath,
    required this.confirmed,
  });

  factory ClothingItem.fromJson(Map<String, dynamic> json) {
    return ClothingItem(
      id: json['id'],
      category: json['category'],
      color: json['color'],
      pattern: json['pattern'],
      fit: json['fit'],
      material: json['material'],
      imagePath: json['imagePath'],
      croppedImagePath: json['croppedImagePath'],
      confirmed: json['confirmed'] ?? false,
    );
  }
}
