package com.trendfit.global.config;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

/**
 * Claude API 클라이언트 빈. 실제 API 키/모델은 ClaudeProperties(application.yml)에서 주입한다.
 * 도메인 컨텍스트(trend, recommendation)는 이 빈을 주입받아 사용하고, 직접 SDK 클라이언트를
 * 생성하지 않는다.
 */
@Configuration
@RequiredArgsConstructor
public class ClaudeClientConfig {

    private final ClaudeProperties claudeProperties;

    @Bean
    public AnthropicClient anthropicClient() {
        return AnthropicOkHttpClient.builder()
                .apiKey(claudeProperties.getApiKey())
                .build();
    }
}
