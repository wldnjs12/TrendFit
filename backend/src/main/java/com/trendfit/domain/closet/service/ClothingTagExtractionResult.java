package com.trendfit.domain.closet.service;

import java.util.List;

/**
 * ClaudeVisionTagger 가 한 번의 배치 호출(등록 요청 1건 = 이미지 여러 장)로 받는
 * 구조화 출력(output_config.format) 전체.
 */
public record ClothingTagExtractionResult(
        List<ClothingTagExtraction> items
) {
}
