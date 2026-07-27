package com.trendfit.domain.user.dto;

import java.util.List;

/**
 * 온보딩 취향 선택 요청. (service-policy.md §1 — 스타일 취향 최소 1개 이상 필수,
 * 체형 정보는 선택)
 */
public record OnboardingRequest(
        List<String> styleTags,
        String bodyInfo
) {
}
