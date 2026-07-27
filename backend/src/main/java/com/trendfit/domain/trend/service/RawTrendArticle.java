package com.trendfit.domain.trend.service;

import java.time.LocalDateTime;

/**
 * RSS 수집기가 반환하는 원문 아티클. (PRD 4.2 F1, 1주차 PoC)
 * Claude 정제(2주차) 이전 단계의 중간 산출물이며, 영속화 대상이 아니다.
 */
public record RawTrendArticle(
        String sourceName,
        String title,
        String link,
        LocalDateTime publishedAt
) {
}
