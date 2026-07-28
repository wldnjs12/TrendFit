package com.trendfit.domain.recommendation.dto;

/** 서버가 ID를 실제 이미지로 매핑한 결과 한 건(service-policy.md §4 — 결과는 사진으로 표시). */
public record RecommendedItemResponse(
        Long id,
        String category,
        String croppedImagePath
) {
}
