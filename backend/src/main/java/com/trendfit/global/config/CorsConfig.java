package com.trendfit.global.config;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

/**
 * Flutter Web(별도 오리진)이 REST API를 호출할 수 있도록 CORS를 허용한다.
 * 프론트(Vercel)와 백엔드(Render/Railway)가 별도 도메인으로 배포되므로(architecture.md §4)
 * 이 설정이 없으면 브라우저에서의 모든 API 호출이 차단된다.
 */
@Configuration
public class CorsConfig implements WebMvcConfigurer {

    private final String[] allowedOrigins;

    public CorsConfig(@Value("${trendfit.cors.allowed-origins}") String allowedOrigins) {
        this.allowedOrigins = allowedOrigins.split("\\s*,\\s*");
    }

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins(allowedOrigins)
                .allowedMethods("GET", "POST", "PATCH", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*");
    }
}
