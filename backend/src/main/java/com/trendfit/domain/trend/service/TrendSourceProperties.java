package com.trendfit.domain.trend.service;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

import java.util.List;

/**
 * application.yml 의 trendfit.trend-batch.sources 값을 바인딩.
 * 확정된 수집 소스 목록은 service-policy.md §3 참고 (open-decisions.md A1, 2026-07-27 결정).
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.trend-batch")
public class TrendSourceProperties {
    private List<String> sources;
}
