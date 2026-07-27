package com.trendfit.domain.trend.port;

import java.util.List;

/**
 * Recommendation이 Trend 컨텍스트의 최신 트렌드 키워드를 조회하는 포트.
 * Trend 컨텍스트가 소유·구현하며, Recommendation은 이 인터페이스만 의존한다
 * (domain-design.md §2).
 */
public interface TrendQueryPort {

    List<TrendKeywordView> findLatestKeywords();
}
