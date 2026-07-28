package com.trendfit.domain.recommendation.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.time.ZoneId;

/**
 * 추천 요청/결과 이력. (PRD 6.3)
 * resultItemIds 와 plusOneItem 은 MVP 단계에서는 JSON 문자열로 단순 저장한다.
 * 캘린더(위클리 아카이브) 조회의 기반 데이터로도 쓰인다. 착용 이력 통계는 스트레치.
 *
 * 요청 시점에는 confirmed=false로 우선 저장하고(빈도 제한 집계는 여기 포함), 사용자가
 * 결과 화면에서 "오늘의 코디로 결정하기"를 눌러야 confirmed=true가 되어 캘린더에 노출된다
 * (추천만 받아보고 채택하지 않은 요청까지 캘린더에 쌓이는 것을 막기 위함).
 */
@Entity
@Table(name = "recommendation_logs")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class RecommendationLog {

    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

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

    @Column(nullable = false)
    private boolean confirmed;

    /** 사용자가 직접 등록한 "실제 착용샷". AI가 추천해준 코디 이미지와는 별개다. */
    @Column(length = 500)
    private String wornPhotoPath;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now(KST);
    }

    public RecommendationLog(Long userId, String requestText, String resultItemIdsJson, String plusOneItemJson) {
        this.userId = userId;
        this.requestText = requestText;
        this.resultItemIdsJson = resultItemIdsJson;
        this.plusOneItemJson = plusOneItemJson;
        this.confirmed = false;
    }

    /** 결과 화면에서 사용자가 "오늘의 코디로 결정하기"를 눌렀을 때 호출한다. */
    public void confirm() {
        this.confirmed = true;
    }

    /** 캘린더에서 "오늘 실제로 입은 사진"을 등록/교체할 때 호출한다. */
    public void attachWornPhoto(String wornPhotoPath) {
        this.wornPhotoPath = wornPhotoPath;
    }
}
