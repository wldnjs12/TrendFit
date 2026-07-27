package com.trendfit.global.storage;

/**
 * 이미지 저장소 추상화. 로컬 개발은 {@code LocalFileImageStorage}를 쓰고, 배포 전
 * 클라우드 구현체(예: Cloudflare R2)로 교체한다 — 호출 측 코드는 이 인터페이스만 안다.
 * (service-policy.md §2, open-decisions.md A4, 2026-07-27 결정)
 */
public interface ImageStorage {

    /**
     * @param content         저장할 이미지 바이트
     * @param originalFilename 원본 파일명(확장자·이름 힌트로만 사용, 그대로 저장되지 않음)
     * @return 나중에 조회에 사용할 저장 경로/키
     */
    String save(byte[] content, String originalFilename);
}
