package com.trendfit.domain.recommendation.controller;

import com.trendfit.domain.recommendation.dto.RecommendationHistoryItemResponse;
import com.trendfit.domain.recommendation.dto.RecommendationRequest;
import com.trendfit.domain.recommendation.dto.RecommendationResponse;
import com.trendfit.domain.recommendation.service.RecommendationService;
import lombok.RequiredArgsConstructor;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.web.bind.annotation.*;

import java.time.DayOfWeek;
import java.time.LocalDate;
import java.time.temporal.TemporalAdjusters;
import java.util.List;

/**
 * 트렌드 번역 추천 엔진 API. (PRD 4.2 F3 — 핵심 기능)
 *
 * 흐름:
 * 1) 오늘 날씨 + 최신 TrendKeyword + UserPreference + 사용자 ClothingItem 전체를
 *    하나의 프롬프트로 조립
 * 2) Claude API 호출 -> {selectedItemIds, stylingNote, plusOne} 구조화 출력
 * 3) ID 를 실제 ClothingItem 이미지로 매핑해 반환
 * 4) '+1 아이템' 구매 콜백 시 자동으로 ClothingItem(Source.AUTO_PURCHASE) 등록
 */
@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    private final RecommendationService recommendationService;

    @PostMapping
    public RecommendationResponse requestRecommendation(@RequestParam("userId") Long userId,
                                                          @RequestBody RecommendationRequest request) {
        return recommendationService.requestRecommendation(
                userId, request.requestText(), request.lat(), request.lon());
    }

    /** 캘린더(위클리 아카이브). weekStart를 안 주면 이번 주 월요일부터 조회한다. */
    @GetMapping("/history")
    public List<RecommendationHistoryItemResponse> getWeeklyHistory(
            @RequestParam("userId") Long userId,
            @RequestParam(value = "weekStart", required = false)
            @DateTimeFormat(iso = DateTimeFormat.ISO.DATE) LocalDate weekStart) {
        LocalDate resolvedWeekStart = weekStart != null
                ? weekStart
                : LocalDate.now().with(TemporalAdjusters.previousOrSame(DayOfWeek.MONDAY));
        return recommendationService.getWeeklyHistory(userId, resolvedWeekStart);
    }

    @PostMapping("/{id}/purchase-callback")
    public void handlePurchaseCallback(@PathVariable Long id) {
        // A6(구매 연동 제휴처)가 아직 미정이라 6주차로 미룬다. ClosetCommandPort는 이미 준비돼 있다.
        throw new UnsupportedOperationException("6주차 구현 예정 (A6 제휴처 확정 후, PRD 4.2 F3)");
    }
}
