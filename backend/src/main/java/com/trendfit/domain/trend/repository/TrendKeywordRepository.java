package com.trendfit.domain.trend.repository;

import com.trendfit.domain.trend.entity.TrendKeyword;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.List;

public interface TrendKeywordRepository extends JpaRepository<TrendKeyword, Long> {
    List<TrendKeyword> findTop20ByOrderByCollectedDateDesc();

    List<TrendKeyword> findAllByCollectedDate(LocalDate date);
}
