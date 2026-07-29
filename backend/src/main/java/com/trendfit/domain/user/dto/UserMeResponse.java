package com.trendfit.domain.user.dto;

import com.trendfit.domain.user.entity.User;
import com.trendfit.global.storage.ImageUrls;

import java.time.LocalDateTime;

/** 회원관리(프로필) 화면에서 쓰는 본인 계정 정보. 엔티티를 직접 노출하지 않기 위한 DTO. */
public record UserMeResponse(
        Long id,
        String email,
        String nickname,
        String profileImageUrl,
        LocalDateTime createdAt
) {
    public static UserMeResponse from(User user) {
        return new UserMeResponse(
                user.getId(),
                user.getEmail(),
                user.getNickname(),
                ImageUrls.toUrl(user.getProfileImagePath()),
                user.getCreatedAt());
    }
}
