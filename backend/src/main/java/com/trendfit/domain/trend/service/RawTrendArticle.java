package com.trendfit.domain.trend.service;

import java.time.LocalDateTime;

/**
 * RSS 수집기가 반환하는 원문 아티클. (PRD 4.2 F1, 1주차 PoC)
 * Claude 정제(2주차) 이전 단계의 중간 산출물이며, 영속화 대상이 아니다.
 * imageUrl은 홈 화면 "트렌드 리포트" 갤러리용으로 4주차에 추가됐다 — 기사 본문에서 추출한
 * 실제 대표 이미지이며, 못 찾으면 null(갤러리에서는 이런 기사를 제외한다).
 */
public record RawTrendArticle(
        String sourceName,
        String title,
        String link,
        LocalDateTime publishedAt,
        String imageUrl
) {
}
