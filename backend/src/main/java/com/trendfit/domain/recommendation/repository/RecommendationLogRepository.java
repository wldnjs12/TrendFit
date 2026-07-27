package com.trendfit.domain.recommendation.repository;

import com.trendfit.domain.recommendation.entity.RecommendationLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface RecommendationLogRepository extends JpaRepository<RecommendationLog, Long> {
    List<RecommendationLog> findAllByUserIdOrderByCreatedAtDesc(Long userId);
}
