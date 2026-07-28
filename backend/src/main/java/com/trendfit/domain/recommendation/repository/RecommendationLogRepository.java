package com.trendfit.domain.recommendation.repository;

import com.trendfit.domain.recommendation.entity.RecommendationLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.List;

public interface RecommendationLogRepository extends JpaRepository<RecommendationLog, Long> {
    List<RecommendationLog> findAllByUserIdOrderByCreatedAtDesc(Long userId);

    /** 하루 요청 빈도 제한(A5, 2026-07-27 결정) 확인용. */
    long countByUserIdAndCreatedAtAfter(Long userId, LocalDateTime since);
}
