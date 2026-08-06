package com.trendfit.global.shopping;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.eleven-st.* 값을 바인딩.
 * 11번가 오픈API센터(openapi.11st.co.kr)에서 발급받은 32자리 키 하나만 필요하다 —
 * 이전 네이버쇼핑 API의 client-id/secret 쌍보다 단순하다. (open-decisions.md A6, 2026-08-05 재결정)
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.eleven-st")
public class ElevenStShoppingProperties {
    private String apiKey;
}
