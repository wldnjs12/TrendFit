package com.trendfit.global.config;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.ai.claude.* 값을 바인딩.
 * 실제 API 키는 CLAUDE_API_KEY 환경변수로 주입하며, 절대 커밋하지 않는다.
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.ai.claude")
public class ClaudeProperties {
    private String apiKey;
    private String model;
}
