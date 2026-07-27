package com.trendfit.domain.trend.service;

/**
 * Claude 정제 결과 한 건. index 는 요청에 포함한 원문 아티클 목록의 순번과 일치한다.
 * 패션/트렌드와 무관한 기사는 세 필드 모두 null 로 채워진다.
 */
public record TrendKeywordExtraction(
        int index,
        String colorTag,
        String itemTag,
        String moodTag
) {
}
