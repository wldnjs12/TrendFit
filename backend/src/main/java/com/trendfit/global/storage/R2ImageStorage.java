package com.trendfit.global.storage;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;
import software.amazon.awssdk.core.ResponseBytes;
import software.amazon.awssdk.core.sync.RequestBody;
import software.amazon.awssdk.core.sync.ResponseTransformer;
import software.amazon.awssdk.services.s3.S3Client;
import software.amazon.awssdk.services.s3.model.GetObjectRequest;
import software.amazon.awssdk.services.s3.model.GetObjectResponse;
import software.amazon.awssdk.services.s3.model.PutObjectRequest;

/**
 * Cloudflare R2 기반 ImageStorage. 배포 환경(Railway)은 재배포마다 파일시스템이 초기화되므로
 * 여기로 옮긴다(open-decisions.md A4, 2026-07-27 결정). trendfit.storage.provider=r2일 때
 * LocalFileImageStorage 대신 활성화된다.
 *
 * 저장 키를 그대로 R2 오브젝트 키로 쓰고, 조회는 항상 우리 서버(ImageController)를 거친다 —
 * 버킷을 퍼블릭으로 열거나 커스텀 도메인을 붙이지 않아도 되어, 기존 클라이언트 코드
 * (ImageUrls.toUrl() -> "/api/images/{key}")를 그대로 재사용할 수 있다.
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "trendfit.storage", name = "provider", havingValue = "r2")
public class R2ImageStorage implements ImageStorage {

    private final S3Client r2Client;
    private final R2Properties r2Properties;

    @Override
    public String save(byte[] content, String originalFilename) {
        String key = ImageKeys.generate(originalFilename);
        r2Client.putObject(
                PutObjectRequest.builder().bucket(r2Properties.getBucket()).key(key).build(),
                RequestBody.fromBytes(content));
        return key;
    }

    @Override
    public byte[] load(String key) {
        ResponseBytes<GetObjectResponse> response = r2Client.getObject(
                GetObjectRequest.builder().bucket(r2Properties.getBucket()).key(key).build(),
                ResponseTransformer.toBytes());
        return response.asByteArray();
    }
}
