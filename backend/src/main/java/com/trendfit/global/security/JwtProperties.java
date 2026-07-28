package com.trendfit.global.security;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.security.jwt.* 값을 바인딩.
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.security.jwt")
public class JwtProperties {
    private String secret;
    private long accessTokenValidityMs;
    private long refreshTokenValidityMs;
}
