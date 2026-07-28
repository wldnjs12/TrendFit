package com.trendfit.global.storage;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import software.amazon.awssdk.auth.credentials.AwsBasicCredentials;
import software.amazon.awssdk.auth.credentials.StaticCredentialsProvider;
import software.amazon.awssdk.regions.Region;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.S3Configuration;

import java.net.URI;

/**
 * Cloudflare R2(S3 호환 API) 클라이언트 빈. trendfit.storage.provider=r2일 때만 만든다 —
 * 로컬 개발(provider=local)에서는 R2 자격증명이 비어 있을 수 있어 무조건 만들면 부팅이 실패한다.
 */
@Configuration
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "trendfit.storage", name = "provider", havingValue = "r2")
public class R2ClientConfig {

    private final R2Properties r2Properties;

    @Bean
    public S3Client r2Client() {
        return S3Client.builder()
                .endpointOverride(URI.create("https://" + r2Properties.getAccountId() + ".r2.cloudflarestorage.com"))
                // R2는 리전 개념이 없다 — SDK가 문자열을 요구해서 관례적으로 "auto"를 쓴다.
                .region(Region.of("auto"))
                .serviceConfiguration(S3Configuration.builder().pathStyleAccessEnabled(true).build())
                .credentialsProvider(StaticCredentialsProvider.create(
                        AwsBasicCredentials.create(r2Properties.getAccessKeyId(), r2Properties.getSecretAccessKey())))
                .build();
    }
}
