package com.trendfit.global.storage;

import lombok.RequiredArgsConstructor;
import org.springframework.http.CacheControl;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.time.Duration;

/**
 * ImageStorage에 저장된 이미지를 서빙한다. ImageUrls.toUrl()이 만든 경로와 짝을 이룬다.
 */
@RestController
@RequestMapping("/api/images")
@RequiredArgsConstructor
public class ImageController {

    private final ImageStorage imageStorage;

    @GetMapping("/{key}")
    public ResponseEntity<byte[]> getImage(@PathVariable String key) {
        byte[] content = imageStorage.load(key);
        MediaType mediaType = MediaTypeFactory.getMediaType(key).orElse(MediaType.APPLICATION_OCTET_STREAM);
        // key는 ImageKeys.generate()가 UUID로 만들어 절대 재사용/덮어쓰기되지 않는 불변
        // 리소스다 — 영구 캐시가 안전하다. 화면 전환마다 같은 옷 사진을 재다운로드하던 걸 막는다.
        return ResponseEntity.ok()
                .contentType(mediaType)
                .cacheControl(CacheControl.maxAge(Duration.ofDays(365)).cachePublic().immutable())
                .body(content);
    }
}
