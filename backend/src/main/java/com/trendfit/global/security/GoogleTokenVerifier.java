package com.trendfit.global.security;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpHeaders;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;
import org.springframework.web.client.RestClientException;

import java.net.URI;

/**
 * Flutter 클라이언트가 google_sign_in으로 발급받은 Google 액세스 토큰을 서버에서 검증한다.
 *
 * Flutter Web에서 google_sign_in(google_sign_in_web)은 ID 토큰(JWT)이 아니라 OAuth2 액세스
 * 토큰만 발급한다 — Google이 예전 Sign-In JS SDK(gapi.auth2, ID 토큰 발급)를 접고 Identity
 * Services(google.accounts.oauth2, 액세스 토큰 발급)로 옮기면서 생긴 동작이다. 그래서 ID 토큰
 * 검증(tokeninfo?id_token=) 대신, (1) tokeninfo?access_token= 으로 토큰이 우리 클라이언트
 * ID(aud/azp) 앞으로 발급된 게 맞는지 확인하고, (2) 표준 OIDC UserInfo 엔드포인트를 액세스
 * 토큰으로 호출해 sub/email/name을 받아온다.
 *
 * MVP 트래픽 규모에서는 이 방식으로 충분하지만, 호출량이 커지면 Google의 공개 JWK로
 * 서명을 직접 검증하는 방식(google-api-client의 GoogleIdTokenVerifier, ID 토큰 전제)으로
 * 교체를 검토한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class GoogleTokenVerifier {

    private static final String TOKENINFO_ENDPOINT = "https://oauth2.googleapis.com/tokeninfo?access_token=";
    private static final String USERINFO_ENDPOINT = "https://www.googleapis.com/oauth2/v3/userinfo";

    private final GoogleAuthProperties googleAuthProperties;
    private final RestClient restClient = RestClient.create();

    public GoogleUserInfo verify(String accessToken) {
        if (accessToken == null || accessToken.isBlank()) {
            throw new IllegalArgumentException("Google 액세스 토큰이 필요합니다.");
        }

        TokenInfoResponse tokenInfo = fetchTokenInfo(accessToken);
        String expectedClientId = googleAuthProperties.getClientId();
        if (expectedClientId != null && !expectedClientId.isBlank()
                && !expectedClientId.equals(tokenInfo.aud()) && !expectedClientId.equals(tokenInfo.azp())) {
            log.warn("[GoogleTokenVerifier] aud/azp 불일치: expected={}, aud={}, azp={}",
                    expectedClientId, tokenInfo.aud(), tokenInfo.azp());
            throw new IllegalArgumentException("허용되지 않은 클라이언트에서 발급된 토큰입니다.");
        }

        UserInfoResponse userInfo = fetchUserInfo(accessToken);
        if (userInfo == null || userInfo.sub() == null || userInfo.email() == null) {
            throw new IllegalArgumentException("Google 사용자 정보를 가져오지 못했습니다.");
        }
        if (!Boolean.TRUE.equals(userInfo.email_verified())) {
            throw new IllegalArgumentException("이메일 인증이 완료되지 않은 Google 계정입니다.");
        }

        String nickname = userInfo.name() != null && !userInfo.name().isBlank()
                ? userInfo.name()
                : userInfo.email().substring(0, userInfo.email().indexOf('@'));
        return new GoogleUserInfo(userInfo.sub(), userInfo.email(), nickname);
    }

    private TokenInfoResponse fetchTokenInfo(String accessToken) {
        try {
            return restClient.get()
                    .uri(URI.create(TOKENINFO_ENDPOINT + accessToken))
                    .retrieve()
                    .body(TokenInfoResponse.class);
        } catch (RestClientException e) {
            log.warn("[GoogleTokenVerifier] 토큰 검증 실패: {}", e.getMessage());
            throw new IllegalArgumentException("Google 로그인 토큰이 유효하지 않습니다.");
        }
    }

    private UserInfoResponse fetchUserInfo(String accessToken) {
        try {
            return restClient.get()
                    .uri(URI.create(USERINFO_ENDPOINT))
                    .header(HttpHeaders.AUTHORIZATION, "Bearer " + accessToken)
                    .retrieve()
                    .body(UserInfoResponse.class);
        } catch (RestClientException e) {
            log.warn("[GoogleTokenVerifier] 사용자 정보 조회 실패: {}", e.getMessage());
            throw new IllegalArgumentException("Google 사용자 정보를 가져오지 못했습니다.");
        }
    }

    public record GoogleUserInfo(String oauthId, String email, String nickname) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record TokenInfoResponse(String aud, String azp) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record UserInfoResponse(String sub, String email, Boolean email_verified, String name) {
    }
}
