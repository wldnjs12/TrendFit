package com.trendfit.domain.trend.port;

/**
 * Recommendation이 프롬프트 조립 시 읽는 최신 트렌드 키워드. (domain-design.md §2, B4 결정)
 */
public record TrendKeywordView(
        String colorTag,
        String itemTag,
        String moodTag
) {
}
