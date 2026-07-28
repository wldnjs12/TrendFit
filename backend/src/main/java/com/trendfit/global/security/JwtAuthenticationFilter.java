package com.trendfit.global.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Optional;

/**
 * Authorization: Bearer {accessToken} 헤더를 읽어 SecurityContext에 인증 정보(principal=userId)를
 * 채운다. 토큰이 없거나 유효하지 않아도 요청 자체는 통과시킨다 — permitAll 엔드포인트가 대부분이라
 * 인증 실패를 여기서 막지 않고, 인증이 실제로 필요한 엔드포인트는 SecurityConfig의
 * authorizeHttpRequests에서 authenticated()로 막는다.
 */
@Component
@RequiredArgsConstructor
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private static final String HEADER = "Authorization";
    private static final String PREFIX = "Bearer ";

    private final JwtTokenProvider jwtTokenProvider;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        extractToken(request)
                .flatMap(jwtTokenProvider::resolveAccessTokenUserId)
                .ifPresent(userId -> {
                    var authentication = new UsernamePasswordAuthenticationToken(
                            userId, null, List.of(new SimpleGrantedAuthority("ROLE_USER")));
                    SecurityContextHolder.getContext().setAuthentication(authentication);
                });
        filterChain.doFilter(request, response);
    }

    private Optional<String> extractToken(HttpServletRequest request) {
        String header = request.getHeader(HEADER);
        if (header != null && header.startsWith(PREFIX)) {
            return Optional.of(header.substring(PREFIX.length()));
        }
        return Optional.empty();
    }
}
