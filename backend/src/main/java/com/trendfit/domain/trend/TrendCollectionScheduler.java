package com.trendfit.domain.trend;

import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Component;

/**
 * 트렌드 수집·정제 배치. (PRD 4.2 F1, 6.5)
 *
 * 매일 새벽(기본 cron: application.yml 의 trendfit.trend-batch.cron) 실행되어
 * 1) 공개 패션 매체 원문을 수집하고
 * 2) Claude API 로 컬러/아이템/무드 키워드로 구조화한 뒤
 * 3) TrendKeywordRepository 에 저장한다.
 *
 * TODO(2주차): 실제 소스 수집기(RSS/HTML 파서)와 Claude 정제 호출을 구현한다.
 * 지금은 스케줄러 골격과 호출 지점만 정의되어 있다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TrendCollectionScheduler {

    private final TrendKeywordRepository trendKeywordRepository;
    // private final TrendSourceCollector sourceCollector;   // TODO: 2주차 구현
    // private final ClaudeTrendRefiner trendRefiner;        // TODO: 2주차 구현

    @Scheduled(cron = "${trendfit.trend-batch.cron}")
    public void collectDailyTrends() {
        log.info("[TrendCollectionScheduler] 트렌드 배치 시작");
        // TODO:
        // 1. sourceCollector.fetchLatestArticles() 로 공개 소스 원문 수집
        // 2. trendRefiner.refine(원문) 으로 Claude 호출 -> 컬러/아이템/무드 키워드 JSON 파싱
        // 3. trendKeywordRepository.save(...) 로 적재
        log.info("[TrendCollectionScheduler] 트렌드 배치 종료 (구현 예정)");
    }
}
