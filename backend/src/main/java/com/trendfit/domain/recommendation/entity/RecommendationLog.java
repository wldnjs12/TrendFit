package com.trendfit.domain.recommendation.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 추천 요청/결과 이력. (PRD 6.3)
 * resultItemIds 와 plusOneItem 은 MVP 단계에서는 JSON 문자열로 단순 저장한다.
 * 추후 캘린더/통계 기능(스트레치)의 기반 데이터가 될 수 있다.
 */
@Entity
@Table(name = "recommendation_logs")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RecommendationLog {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Column(length = 500, nullable = false)
    private String requestText; // 사용자의 자연어 요청 원문

    @Column(length = 1000)
    private String resultItemIdsJson; // 예: {"top":101,"bottom":105,"outer":110}

    @Column(length = 1000)
    private String plusOneItemJson; // 예: {"item":"버건디 니트 베스트","reason":"이번 주 트렌드 반영"}

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public RecommendationLog(Long userId, String requestText, String resultItemIdsJson, String plusOneItemJson) {
        this.userId = userId;
        this.requestText = requestText;
        this.resultItemIdsJson = resultItemIdsJson;
        this.plusOneItemJson = plusOneItemJson;
    }
}
