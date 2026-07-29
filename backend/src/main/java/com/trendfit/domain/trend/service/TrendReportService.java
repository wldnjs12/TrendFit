package com.trendfit.domain.trend.service;

import com.trendfit.domain.trend.dto.TrendArticleResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.Instant;
import java.util.Comparator;
import java.util.List;

/**
 * 홈 화면 "트렌드 리포트" 갤러리용 — RSS 원문 중 이미지가 있는 기사만 골라 최신순으로 내려준다.
 * TrendKeyword(색상/아이템/무드 구조화 키워드) 파이프라인과는 별개다 — 그쪽은 추천 프롬프트
 * 조립용으로 이미지·제목을 보존하지 않기 때문에, 갤러리는 RawTrendArticle을 직접 쓴다.
 *
 * 홈 화면이 열릴 때마다 3개 RSS를 매번 다시 긁으면 느리고 소스에 부담을 주므로, 짧은 TTL로
 * 메모리에 캐시한다 — 배치 스케줄러(TrendCollectionScheduler)처럼 DB에 영속화할 필요는 없는
 * 표시용 데이터라 별도 테이블 없이 이 정도로 충분하다.
 */
@Component
@RequiredArgsConstructor
public class TrendReportService {

    private static final Duration CACHE_TTL = Duration.ofMinutes(30);
    private static final int MAX_ITEMS = 12;

    private final TrendSourceCollector sourceCollector;

    private volatile List<TrendArticleResponse> cache = List.of();
    private volatile Instant cachedAt = Instant.EPOCH;

    public synchronized List<TrendArticleResponse> getReport() {
        if (!cache.isEmpty() && Duration.between(cachedAt, Instant.now()).compareTo(CACHE_TTL) < 0) {
            return cache;
        }

        List<RawTrendArticle> articles = sourceCollector.fetchLatestArticles();
        cache = articles.stream()
                .filter(article -> article.imageUrl() != null)
                .sorted(Comparator.comparing(RawTrendArticle::publishedAt,
                        Comparator.nullsLast(Comparator.reverseOrder())))
                .limit(MAX_ITEMS)
                .map(article -> new TrendArticleResponse(
                        article.sourceName(), article.title(), article.link(), article.imageUrl()))
                .toList();
        cachedAt = Instant.now();
        return cache;
    }
}
