package com.trendfit.domain.recommendation.service;

import java.util.List;

/**
 * ClaudeRecommendationEngine이 한 번의 호출로 받는 구조화 출력(output_config.format) 전체.
 */
public record RecommendationResult(
        List<Long> selectedItemIds,
        String stylingNote,
        PlusOneSuggestion plusOne
) {
}
