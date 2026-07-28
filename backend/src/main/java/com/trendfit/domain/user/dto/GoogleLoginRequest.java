package com.trendfit.domain.user.dto;

/**
 * 프론트(Flutter google_sign_in)가 발급받은 Google 액세스 토큰으로 로그인/가입을 요청한다.
 * Flutter Web에서는 ID 토큰이 아닌 OAuth2 액세스 토큰만 발급되므로(GoogleTokenVerifier 참고)
 * 액세스 토큰을 받는다.
 */
public record GoogleLoginRequest(String accessToken) {
}
