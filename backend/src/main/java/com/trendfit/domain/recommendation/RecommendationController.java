package com.trendfit.domain.recommendation;

import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 트렌드 번역 추천 엔진 API. (PRD 4.2 F3 — 핵심 기능)
 *
 * 흐름:
 * 1) 오늘 날씨 + 최신 TrendKeyword + UserPreference + 사용자 ClothingItem 전체를
 *    하나의 프롬프트로 조립
 * 2) Claude API 호출 -> {top:ID, bottom:ID, plus_one:{...}} 형태 JSON 응답
 * 3) ID 를 실제 ClothingItem 이미지로 매핑해 반환
 * 4) '+1 아이템' 구매 콜백 시 자동으로 ClothingItem(Source.AUTO_PURCHASE) 등록
 *
 * TODO(4주차): RecommendationService 구현 후 연결.
 */
@RestController
@RequestMapping("/api/recommendations")
@RequiredArgsConstructor
public class RecommendationController {

    // private final RecommendationService recommendationService; // TODO: 4주차 구현

    @PostMapping
    public void requestRecommendation(@RequestParam("userId") Long userId,
                                       @RequestBody String requestText) {
        // TODO: 프롬프트 조립 -> Claude 호출 -> 결과 파싱 -> RecommendationLog 저장 -> 응답
        throw new UnsupportedOperationException("4주차 구현 예정 (PRD 4.2 F3)");
    }

    @PostMapping("/{id}/purchase-callback")
    public void handlePurchaseCallback(@PathVariable Long id) {
        // TODO: '+1 아이템' 구매 확정 -> ClothingItem 자동 등록 (Source.AUTO_PURCHASE)
        throw new UnsupportedOperationException("4주차 구현 예정 (PRD 4.2 F3)");
    }
}
