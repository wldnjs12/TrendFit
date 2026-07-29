package com.trendfit.domain.trend.dto;

/** 홈 화면 "트렌드 리포트" 갤러리에 표시할 기사 한 건. */
public record TrendArticleResponse(
        String sourceName,
        String title,
        String link,
        String imageUrl
) {
}
