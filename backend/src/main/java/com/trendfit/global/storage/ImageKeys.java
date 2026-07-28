package com.trendfit.global.storage;

import java.util.UUID;

/** ImageStorage 구현체들이 공유하는 저장 키 생성 규칙. */
final class ImageKeys {

    private ImageKeys() {
    }

    static String generate(String originalFilename) {
        return UUID.randomUUID() + "-" + sanitize(originalFilename);
    }

    private static String sanitize(String filename) {
        if (filename == null || filename.isBlank()) {
            return "image";
        }
        return filename.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
