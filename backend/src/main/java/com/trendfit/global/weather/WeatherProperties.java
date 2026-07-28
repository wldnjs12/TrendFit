package com.trendfit.global.weather;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.weather.* 값을 바인딩.
 * apiKey는 공공데이터포털에서 발급받은 서비스키 중 "인코딩(Encoding)" 버전을 사용해야 한다 —
 * WeatherClient가 쿼리스트링을 직접 조립하므로, 이미 percent-encoded 된 값이어야 이중 인코딩을
 * 피할 수 있다.
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.weather")
public class WeatherProperties {
    private String apiKey;
}
