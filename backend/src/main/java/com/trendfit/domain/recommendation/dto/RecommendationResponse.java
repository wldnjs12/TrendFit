package com.trendfit.domain.recommendation.dto;

import java.util.List;

public record RecommendationResponse(
        Long logId,
        List<RecommendedItemResponse> items,
        String stylingNote,
        PlusOneResponse plusOne
) {
}
