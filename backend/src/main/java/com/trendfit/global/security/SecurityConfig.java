package com.trendfit.global.security;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.trendfit.global.exception.ErrorResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.MediaType;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.CorsConfigurationSource;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;

import java.util.List;

/**
 * Google OAuth2 로그인 + JWT 세션 보안 설정. (conventions.md §4)
 *
 * 회원가입/로그인(/api/auth/**)과 이미지 조회는 인증 없이 열어두고, 본인 계정 조회/탈퇴
 * (/api/users/me)만 JWT 인증을 강제한다. 옷장/추천/트렌드 등 나머지 API는 아직 userId를
 * 쿼리 파라미터로 받는 기존 방식을 유지하는 과도기라(이번 작업 범위 밖) 그대로 permitAll로 둔다 —
 * JWT 인프라를 전체 API로 확장하는 것은 별도 작업으로 진행한다.
 */
@Configuration
@EnableWebSecurity
@RequiredArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;
    private final ObjectMapper objectMapper;

    @Value("${trendfit.cors.allowed-origins}")
    private String allowedOrigins;

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())
                .cors(cors -> cors.configurationSource(corsConfigurationSource()))
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS))
                .authorizeHttpRequests(auth -> auth
                        .requestMatchers("/api/auth/google", "/api/auth/refresh", "/api/images/**").permitAll()
                        .requestMatchers("/api/auth/logout", "/api/users/me", "/api/users/me/**").authenticated()
                        .anyRequest().permitAll())
                .exceptionHandling(handling -> handling.authenticationEntryPoint((request, response, authException) -> {
                    response.setStatus(401);
                    response.setContentType(MediaType.APPLICATION_JSON_VALUE);
                    response.setCharacterEncoding("UTF-8");
                    response.getWriter().write(
                            objectMapper.writeValueAsString(new ErrorResponse("로그인이 필요합니다.")));
                }))
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class);
        return http.build();
    }

    private CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of(allowedOrigins.split("\\s*,\\s*")));
        configuration.setAllowedMethods(List.of("GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/api/**", configuration);
        return source;
    }
}
