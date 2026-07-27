package com.trendfit.global.storage;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.storage.local.* 값을 바인딩.
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.storage.local")
public class LocalStorageProperties {
    private String baseDir = "./storage/images";
}
