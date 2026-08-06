package com.trendfit.global.shopping;

/** '+1 아이템' 구매 연동 쇼핑 검색 결과 상품 한 건. (A6, 2026-08-05 — 11번가 오픈API) */
public record ShoppingProductView(
        String title,
        String link,
        String imageUrl,
        String lowPrice,
        String mallName
) {
}
