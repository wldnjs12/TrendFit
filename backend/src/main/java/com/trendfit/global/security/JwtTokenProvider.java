package com.trendfit.global.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.security.Keys;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import javax.crypto.SecretKey;
import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Optional;

/**
 * 액세스/리프레시 JWT 발급·검증. (conventions.md §4 — Google OAuth2 로그인 + JWT 세션)
 * 토큰 subject는 userId, "type" 클레임으로 access/refresh를 구분해 리프레시 토큰이
 * 액세스 토큰으로 오용되는 것을 막는다.
 */
@Component
@RequiredArgsConstructor
public class JwtTokenProvider {

    private static final String CLAIM_TYPE = "type";
    private static final String TYPE_ACCESS = "access";
    private static final String TYPE_REFRESH = "refresh";

    private final JwtProperties jwtProperties;

    private SecretKey key() {
        return Keys.hmacShaKeyFor(jwtProperties.getSecret().getBytes(StandardCharsets.UTF_8));
    }

    public String createAccessToken(Long userId) {
        return createToken(userId, TYPE_ACCESS, jwtProperties.getAccessTokenValidityMs());
    }

    public String createRefreshToken(Long userId) {
        return createToken(userId, TYPE_REFRESH, jwtProperties.getRefreshTokenValidityMs());
    }

    private String createToken(Long userId, String type, long validityMs) {
        Date now = new Date();
        return Jwts.builder()
                .subject(String.valueOf(userId))
                .claim(CLAIM_TYPE, type)
                .issuedAt(now)
                .expiration(new Date(now.getTime() + validityMs))
                .signWith(key())
                .compact();
    }

    /** 유효한 액세스 토큰이면 userId를 반환하고, 아니면(만료/위조/리프레시 토큰 오용) empty. */
    public Optional<Long> resolveAccessTokenUserId(String token) {
        return resolveUserId(token, TYPE_ACCESS);
    }

    /** 유효한 리프레시 토큰이면 userId를 반환하고, 아니면 empty. */
    public Optional<Long> resolveRefreshTokenUserId(String token) {
        return resolveUserId(token, TYPE_REFRESH);
    }

    private Optional<Long> resolveUserId(String token, String expectedType) {
        try {
            Claims claims = Jwts.parser().verifyWith(key()).build().parseSignedClaims(token).getPayload();
            if (!expectedType.equals(claims.get(CLAIM_TYPE, String.class))) {
                return Optional.empty();
            }
            return Optional.of(Long.valueOf(claims.getSubject()));
        } catch (JwtException | IllegalArgumentException e) {
            return Optional.empty();
        }
    }
}
