package com.trendfit.domain.user.dto;

/**
 * 로그인/토큰 재발급 응답. onboardingCompleted로 프론트가 회원정보/스타일 입력 화면으로
 * 보낼지, 바로 메인 탭으로 보낼지 분기한다(architecture.md §3 온보딩 흐름).
 */
public record AuthTokenResponse(
        String accessToken,
        String refreshToken,
        Long userId,
        String email,
        String nickname,
        boolean isNewUser,
        boolean onboardingCompleted
) {
}
