package com.trendfit.domain.recommendation.dto;

public record PlusOneResponse(
        String itemName,
        String reason,
        String category
) {
}
