package com.trendfit.global.security;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.security.google.* 값을 바인딩.
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.security.google")
public class GoogleAuthProperties {
    private String clientId;
}
