package com.trendfit.global.storage;

import lombok.RequiredArgsConstructor;
import org.springframework.boot.autoconfigure.condition.ConditionalOnProperty;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.nio.file.Files;
import java.nio.file.Path;

/**
 * 로컬 파일시스템 기반 ImageStorage. 개발 환경 전용 — Railway 등에 배포할 때는 재배포 시
 * 파일시스템이 초기화되므로 클라우드 구현체(R2ImageStorage)로 교체해야 한다
 * (open-decisions.md A4, 2026-07-27 결정). trendfit.storage.provider=local(기본값)일 때만 활성화된다.
 */
@Component
@RequiredArgsConstructor
@ConditionalOnProperty(prefix = "trendfit.storage", name = "provider", havingValue = "local", matchIfMissing = true)
public class LocalFileImageStorage implements ImageStorage {

    private final LocalStorageProperties properties;

    @Override
    public String save(byte[] content, String originalFilename) {
        try {
            Path baseDir = baseDir();
            Files.createDirectories(baseDir);

            String storedName = ImageKeys.generate(originalFilename);
            Files.write(baseDir.resolve(storedName), content);
            return storedName;
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    @Override
    public byte[] load(String key) {
        try {
            Path target = resolveWithinBaseDir(key);
            return Files.readAllBytes(target);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private Path resolveWithinBaseDir(String key) {
        Path base = baseDir().normalize();
        Path target = base.resolve(key).normalize();
        if (!target.startsWith(base)) {
            throw new IllegalArgumentException("잘못된 이미지 키: " + key);
        }
        return target;
    }

    private Path baseDir() {
        return Path.of(properties.getBaseDir()).toAbsolutePath();
    }
}
