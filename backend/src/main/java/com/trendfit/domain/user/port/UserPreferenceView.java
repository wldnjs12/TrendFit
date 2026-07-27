package com.trendfit.domain.user.port;

import java.util.List;

/**
 * Recommendation이 프롬프트 조립 시 읽는 취향 조회 결과. (domain-design.md §2, B4 결정)
 */
public record UserPreferenceView(
        List<String> styleTags,
        String bodyInfo
) {
}
