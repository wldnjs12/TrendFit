package com.trendfit.domain.recommendation.dto;

import java.time.LocalDate;
import java.util.List;

/**
 * 캘린더(위클리 아카이브)에 표시할 하루치 추천 이력 한 건.
 * stylingNote는 RecommendationLog에 별도 저장되지 않으므로, 카드 캡션은 requestText(사용자
 * 요청 원문)로 대신한다.
 */
public record RecommendationHistoryItemResponse(
        Long logId,
        LocalDate date,
        List<RecommendedItemResponse> items,
        String requestText,
        String wornPhotoUrl
) {
}
