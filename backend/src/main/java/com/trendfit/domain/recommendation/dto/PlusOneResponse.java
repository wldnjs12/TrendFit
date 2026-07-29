package com.trendfit.domain.recommendation.dto;

/**
 * productUrl/productImageUrl/price는 네이버쇼핑 검색 API(A6, 2026-07-29 결정)로 조회한 실제
 * 구매 가능 상품 정보다. 매칭되는 상품을 찾지 못하면 모두 null이며, 프론트는 이 경우 링크 없이
 * itemName/reason만 보여준다.
 */
public record PlusOneResponse(
        String itemName,
        String reason,
        String category,
        String productUrl,
        String productImageUrl,
        String mallName,
        String price
) {
}
