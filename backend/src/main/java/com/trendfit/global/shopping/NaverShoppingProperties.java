package com.trendfit.global.shopping;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.naver-shopping.* 값을 바인딩.
 * 네이버 개발자센터(Application 등록 > 검색 API 사용 설정)에서 발급받은 클라이언트 ID/시크릿.
 * (open-decisions.md A6, 2026-07-29 결정)
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.naver-shopping")
public class NaverShoppingProperties {
    private String clientId;
    private String clientSecret;
}
