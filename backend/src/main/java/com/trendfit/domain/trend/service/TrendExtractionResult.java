package com.trendfit.domain.trend.service;

import java.util.List;

/**
 * ClaudeTrendRefiner 가 한 번의 배치 호출로 받는 구조화 출력(output_config.format) 전체.
 */
public record TrendExtractionResult(
        List<TrendKeywordExtraction> items
) {
}
