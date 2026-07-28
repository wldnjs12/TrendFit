package com.trendfit.global.storage;

/**
 * ImageStorage 저장 키를 클라이언트가 실제로 fetch할 수 있는 상대 URL로 변환한다.
 * DTO 조립 시점(Closet/Recommendation)에서 사용한다 — 저장소 내부 키(파일 경로 등)를
 * 그대로 클라이언트에 내려보내지 않기 위함이다.
 */
public final class ImageUrls {

    private ImageUrls() {
    }

    public static String toUrl(String storageKey) {
        return storageKey == null ? null : "/api/images/" + storageKey;
    }
}
