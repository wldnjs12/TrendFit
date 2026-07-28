package com.trendfit.domain.recommendation.service;

/**
 * Claude가 제안하는 '+1 아이템'. 옷장에 없어 트렌드를 보완할 아이템이 있을 때만 채워진다.
 */
public record PlusOneSuggestion(
        String itemName,
        String reason,
        String category
) {
}
