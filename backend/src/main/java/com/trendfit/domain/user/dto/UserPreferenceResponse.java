package com.trendfit.domain.user.dto;

import com.trendfit.domain.user.entity.UserPreference;

import java.util.Arrays;
import java.util.List;

/**
 * 취향 프로필 조회/등록 응답 DTO. 엔티티(UserPreference)를 컨트롤러 밖으로 직접
 * 노출하지 않기 위해 사용한다.
 */
public record UserPreferenceResponse(
        Long id,
        Long userId,
        List<String> styleTags,
        String bodyInfo
) {

    public static UserPreferenceResponse from(UserPreference preference) {
        String raw = preference.getStyleTags();
        List<String> tags = (raw == null || raw.isBlank())
                ? List.of()
                : Arrays.asList(raw.split(","));

        return new UserPreferenceResponse(
                preference.getId(),
                preference.getUser().getId(),
                tags,
                preference.getBodyInfo()
        );
    }
}
