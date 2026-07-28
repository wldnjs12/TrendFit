package com.trendfit.domain.recommendation.service;

import com.trendfit.domain.closet.port.ClosetItemView;
import com.trendfit.domain.trend.port.TrendKeywordView;

import java.util.List;

/**
 * ClaudeRecommendationEngine에 넘기는 프롬프트 조립 재료 전체.
 * (PRD 4.2 F3 — 날씨 + 트렌드 + 취향 + 체형 + 옷장 + 사용자 요청)
 */
public record RecommendationContext(
        String requestText,
        String weather,
        List<TrendKeywordView> trendKeywords,
        List<String> styleTags,
        String bodyInfo,
        List<ClosetItemView> closetItems
) {
}
