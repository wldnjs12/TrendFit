package com.trendfit.global.shopping;

/** 네이버쇼핑 검색 결과 상품 한 건. */
public record NaverProductView(
        String title,
        String link,
        String imageUrl,
        String lowPrice,
        String mallName
) {
}
