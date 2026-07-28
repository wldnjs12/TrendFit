package com.trendfit.domain.recommendation.dto;

/**
 * 추천 요청. (a) 일반 요청("오늘 뭐 입지?") (b) 앵커 아이템 요청("이거 입고 싶은데 뭐랑 매치?")
 * 모두 requestText 자연어로 받는다 — 서버 로직상 구분하지 않고 Claude가 해석한다.
 * lat/lon이 없으면 서울시청 좌표를 기본값으로 쓴다(위치 입력 UI는 아직 없음).
 */
public record RecommendationRequest(
        String requestText,
        Double lat,
        Double lon
) {
}
