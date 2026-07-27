package com.trendfit.global.storage;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.UUID;

/**
 * 로컬 파일시스템 기반 ImageStorage. 개발 환경 전용 — Render/Railway 등에 배포할 때는
 * 재배포 시 파일시스템이 초기화될 수 있으므로 클라우드 구현체로 교체해야 한다
 * (open-decisions.md A4, 2026-07-27 결정).
 */
@Component
@RequiredArgsConstructor
public class LocalFileImageStorage implements ImageStorage {

    private final LocalStorageProperties properties;

    @Override
    public String save(byte[] content, String originalFilename) {
        try {
            Path baseDir = Path.of(properties.getBaseDir());
            Files.createDirectories(baseDir);

            String storedName = UUID.randomUUID() + "-" + sanitize(originalFilename);
            Path target = baseDir.resolve(storedName);
            Files.write(target, content);
            return target.toString();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private String sanitize(String filename) {
        if (filename == null || filename.isBlank()) {
            return "image";
        }
        return filename.replaceAll("[^a-zA-Z0-9._-]", "_");
    }
}
