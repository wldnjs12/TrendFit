/// 백엔드 UserMeResponse(/api/users/me)에 대응.
class UserMe {
  final int id;
  final String email;
  final String nickname;
  final String? profileImageUrl;
  final String createdAt;

  UserMe({
    required this.id,
    required this.email,
    required this.nickname,
    this.profileImageUrl,
    required this.createdAt,
  });

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      profileImageUrl: json['profileImageUrl'],
      createdAt: json['createdAt'],
    );
  }
}
