package com.trendfit.global.storage;

import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.http.MediaTypeFactory;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

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
        return ResponseEntity.ok().contentType(mediaType).body(content);
    }
}
