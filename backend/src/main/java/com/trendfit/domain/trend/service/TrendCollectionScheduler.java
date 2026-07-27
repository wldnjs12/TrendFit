package com.trendfit.domain.trend.service;

import com.trendfit.domain.trend.repository.TrendKeywordRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

import java.util.List;

/**
 * 트렌드 수집·정제 배치. (PRD 4.2 F1, 6.5)
 *
 * 매일 새벽(기본 cron: application.yml 의 trendfit.trend-batch.cron) 실행되어
 * 1) 공개 패션 매체 원문을 수집하고
 * 2) Claude API 로 컬러/아이템/무드 키워드로 구조화한 뒤
 * 3) TrendKeywordRepository 에 저장한다.
 *
 * 1주차 PoC: 1) 원문 수집(TrendSourceCollector)까지만 구현되어 있다.
 * TODO(2주차): Claude 정제 호출(ClaudeTrendRefiner)과 TrendKeywordRepository 적재를 구현한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TrendCollectionScheduler {

    private final TrendSourceCollector sourceCollector;
    private final TrendKeywordRepository trendKeywordRepository;
    // private final ClaudeTrendRefiner trendRefiner;        // TODO: 2주차 구현

    @Scheduled(cron = "${trendfit.trend-batch.cron}")
    public void collectDailyTrends() {
        log.info("[TrendCollectionScheduler] 트렌드 배치 시작");

        List<RawTrendArticle> articles = sourceCollector.fetchLatestArticles();
        log.info("[TrendCollectionScheduler] 원문 {}건 수집 완료", articles.size());
        articles.forEach(article -> log.debug("[TrendCollectionScheduler] [{}] {} ({})",
                article.sourceName(), article.title(), article.link()));

        // TODO(2주차):
        // 1. trendRefiner.refine(articles) 로 Claude 호출 -> 컬러/아이템/무드 키워드 JSON 파싱
        // 2. trendKeywordRepository.save(...) 로 적재
        log.info("[TrendCollectionScheduler] 트렌드 배치 종료 (정제·적재 단계는 2주차 구현 예정)");
    }
}
