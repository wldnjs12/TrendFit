/// 백엔드 UserMeResponse(/api/users/me)에 대응.
class UserMe {
  final int id;
  final String email;
  final String nickname;
  final String createdAt;

  UserMe({required this.id, required this.email, required this.nickname, required this.createdAt});

  factory UserMe.fromJson(Map<String, dynamic> json) {
    return UserMe(
      id: json['id'],
      email: json['email'],
      nickname: json['nickname'],
      createdAt: json['createdAt'],
    );
  }
}
