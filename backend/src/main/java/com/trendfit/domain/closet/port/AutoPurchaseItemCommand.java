package com.trendfit.domain.closet.port;

/**
 * '+1 아이템' 구매 확정 콜백 수신 시 Recommendation이 Closet에 전달하는 자동 등록 명령.
 * Vision을 재호출하지 않는다 — 추천 응답에서 이미 태그를 알고 있기 때문이다
 * (service-policy.md §5, PRD 4.2 F3). 실제 구매 콜백 연동(제휴처 확정, A6)은 6주차 범위.
 */
public record AutoPurchaseItemCommand(
        Long userId,
        String category,
        String color,
        String pattern,
        String imagePath
) {
}
