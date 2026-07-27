package com.trendfit.domain.trend.service;

import com.trendfit.domain.trend.port.TrendKeywordView;
import com.trendfit.domain.trend.port.TrendQueryPort;
import com.trendfit.domain.trend.repository.TrendKeywordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

/**
 * TrendQueryPort 구현체. Recommendation에 최신 트렌드 키워드를 제공한다
 * (domain-design.md §2, B4 결정). 배치 적재(ClaudeTrendRefiner/TrendCollectionScheduler)와
 * 조회 책임을 분리한다.
 */
@Service
@RequiredArgsConstructor
public class TrendQueryService implements TrendQueryPort {

    private final TrendKeywordRepository trendKeywordRepository;

    @Override
    @Transactional(readOnly = true)
    public List<TrendKeywordView> findLatestKeywords() {
        return trendKeywordRepository.findTop20ByOrderByCollectedDateDesc().stream()
                .map(keyword -> new TrendKeywordView(
                        keyword.getColorTag(),
                        keyword.getItemTag(),
                        keyword.getMoodTag()))
                .toList();
    }
}
