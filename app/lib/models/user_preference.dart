/// 백엔드 UserPreferenceResponse에 대응.
class UserPreference {
  final int id;
  final int userId;
  final List<String> styleTags;
  final String? bodyInfo;

  UserPreference({
    required this.id,
    required this.userId,
    required this.styleTags,
    this.bodyInfo,
  });

  factory UserPreference.fromJson(Map<String, dynamic> json) {
    final List<dynamic> tags = json['styleTags'] ?? [];
    return UserPreference(
      id: json['id'],
      userId: json['userId'],
      styleTags: tags.cast<String>(),
      bodyInfo: json['bodyInfo'],
    );
  }
}
