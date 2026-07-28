package com.trendfit.global.storage;

import lombok.Getter;
import lombok.Setter;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.context.annotation.Configuration;

/**
 * application.yml 의 trendfit.storage.r2.* 값을 바인딩.
 * Cloudflare 대시보드 R2 > Manage API Tokens에서 발급받는다(open-decisions.md A4).
 */
@Getter
@Setter
@Configuration
@ConfigurationProperties(prefix = "trendfit.storage.r2")
public class R2Properties {
    /** R2 엔드포인트(https://{accountId}.r2.cloudflarestorage.com) 조립에 쓰는 Cloudflare 계정 ID. */
    private String accountId;
    private String accessKeyId;
    private String secretAccessKey;
    private String bucket;
}
