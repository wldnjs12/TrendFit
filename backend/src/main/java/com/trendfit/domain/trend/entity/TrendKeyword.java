package com.trendfit.domain.trend.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDate;

/**
 * 0단계 트렌드 배치 파이프라인이 매일 적재하는 트렌드 데이터. (PRD 4.2 F1, 6.3)
 * 공개 패션 매체 원문을 Claude 로 정제해 컬러/아이템/무드 키워드로 구조화한 결과.
 */
@Entity
@Table(name = "trend_keywords")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class TrendKeyword {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false)
    private LocalDate collectedDate;

    private String colorTag;   // 예: "버건디"
    private String itemTag;    // 예: "니트베스트"
    private String moodTag;    // 예: "프레피"

    @Column(length = 1000)
    private String sourceUrl;

    public TrendKeyword(LocalDate collectedDate, String colorTag, String itemTag, String moodTag, String sourceUrl) {
        this.collectedDate = collectedDate;
        this.colorTag = colorTag;
        this.itemTag = itemTag;
        this.moodTag = moodTag;
        this.sourceUrl = sourceUrl;
    }
}
