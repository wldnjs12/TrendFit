package com.trendfit.domain.user.service;

import com.trendfit.domain.user.dto.AuthTokenResponse;
import com.trendfit.domain.user.entity.User;
import com.trendfit.domain.user.repository.UserPreferenceRepository;
import com.trendfit.domain.user.repository.UserRepository;
import com.trendfit.global.security.GoogleTokenVerifier;
import com.trendfit.global.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/**
 * Google OAuth2 로그인/가입, JWT 재발급, 로그아웃. (conventions.md §4, service-policy.md §1)
 * 자체 비밀번호 로그인은 도입하지 않는다 — Google 액세스 토큰 검증만으로 회원을 식별한다.
 */
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final UserPreferenceRepository userPreferenceRepository;
    private final GoogleTokenVerifier googleTokenVerifier;
    private final JwtTokenProvider jwtTokenProvider;

    @Transactional
    public AuthTokenResponse googleLogin(String accessToken) {
        GoogleTokenVerifier.GoogleUserInfo googleUser = googleTokenVerifier.verify(accessToken);

        boolean isNewUser = false;
        User user = userRepository.findByAuthProviderAndOauthId(User.AuthProvider.GOOGLE, googleUser.oauthId())
                .orElse(null);
        if (user == null) {
            user = userRepository.findByEmail(googleUser.email()).orElse(null);
        }
        if (user == null) {
            user = userRepository.save(
                    new User(googleUser.email(), googleUser.nickname(), User.AuthProvider.GOOGLE, googleUser.oauthId()));
            isNewUser = true;
        }

        return issueTokens(user, isNewUser);
    }

    @Transactional
    public AuthTokenResponse refresh(String refreshToken) {
        Long userId = jwtTokenProvider.resolveRefreshTokenUserId(refreshToken)
                .orElseThrow(() -> new IllegalArgumentException("리프레시 토큰이 유효하지 않습니다."));
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));
        if (user.getRefreshToken() == null || !user.getRefreshToken().equals(refreshToken)) {
            throw new IllegalArgumentException("리프레시 토큰이 유효하지 않습니다. 다시 로그인해주세요.");
        }
        return issueTokens(user, false);
    }

    @Transactional
    public void logout(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));
        user.updateRefreshToken(null);
    }

    private AuthTokenResponse issueTokens(User user, boolean isNewUser) {
        String accessToken = jwtTokenProvider.createAccessToken(user.getId());
        String refreshToken = jwtTokenProvider.createRefreshToken(user.getId());
        user.updateRefreshToken(refreshToken);

        boolean onboardingCompleted = userPreferenceRepository.findByUserId(user.getId()).isPresent();
        return new AuthTokenResponse(
                accessToken, refreshToken, user.getId(), user.getEmail(), user.getNickname(),
                isNewUser, onboardingCompleted);
    }
}
