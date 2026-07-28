package com.trendfit.domain.user.controller;

import com.trendfit.domain.user.dto.AuthTokenResponse;
import com.trendfit.domain.user.dto.GoogleLoginRequest;
import com.trendfit.domain.user.dto.RefreshTokenRequest;
import com.trendfit.domain.user.service.AuthService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

/**
 * Google OAuth2 로그인/JWT 재발급/로그아웃 API. (conventions.md §4)
 */
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/google")
    public AuthTokenResponse googleLogin(@RequestBody GoogleLoginRequest request) {
        return authService.googleLogin(request.accessToken());
    }

    @PostMapping("/refresh")
    public AuthTokenResponse refresh(@RequestBody RefreshTokenRequest request) {
        return authService.refresh(request.refreshToken());
    }

    @PostMapping("/logout")
    public void logout(@AuthenticationPrincipal Long userId) {
        authService.logout(userId);
    }
}
