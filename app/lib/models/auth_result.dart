/// 백엔드 AuthTokenResponse에 대응.
class AuthResult {
  final String accessToken;
  final String refreshToken;
  final int userId;
  final String email;
  final String nickname;
  final bool isNewUser;
  final bool onboardingCompleted;

  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.userId,
    required this.email,
    required this.nickname,
    required this.isNewUser,
    required this.onboardingCompleted,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      accessToken: json['accessToken'],
      refreshToken: json['refreshToken'],
      userId: json['userId'],
      email: json['email'],
      nickname: json['nickname'],
      isNewUser: json['isNewUser'] ?? false,
      onboardingCompleted: json['onboardingCompleted'] ?? false,
    );
  }
}
