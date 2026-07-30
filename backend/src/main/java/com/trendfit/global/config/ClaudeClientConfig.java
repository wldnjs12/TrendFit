package com.trendfit.global.config;

import com.anthropic.client.AnthropicClient;
import com.anthropic.client.okhttp.AnthropicOkHttpClient;
import lombok.RequiredArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.Duration;

/**
 * Claude API 클라이언트 빈. 실제 API 키/모델은 ClaudeProperties(application.yml)에서 주입한다.
 * 도메인 컨텍스트(trend, recommendation)는 이 빈을 주입받아 사용하고, 직접 SDK 클라이언트를
 * 생성하지 않는다.
 */
@Configuration
@RequiredArgsConstructor
public class ClaudeClientConfig {

    /** 기본값(SDK 내부 설정)에 맡기면 장애 시 무한정 대기할 수 있어 상한을 명시한다.
     * Vision 태깅(이미지 여러 장)이 가장 오래 걸리는 호출이라 이를 기준으로 넉넉히 잡는다. */
    private static final Duration REQUEST_TIMEOUT = Duration.ofSeconds(45);

    private final ClaudeProperties claudeProperties;

    @Bean
    public AnthropicClient anthropicClient() {
        return AnthropicOkHttpClient.builder()
                .apiKey(claudeProperties.getApiKey())
                .timeout(REQUEST_TIMEOUT)
                .build();
    }
}
