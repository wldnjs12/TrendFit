package com.trendfit.domain.user.controller;

import com.trendfit.domain.user.dto.OnboardingRequest;
import com.trendfit.domain.user.dto.UserMeResponse;
import com.trendfit.domain.user.dto.UserPreferenceResponse;
import com.trendfit.domain.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;

/**
 * 온보딩(취향 선택) + 회원관리(본인 계정 조회/탈퇴) API.
 * (PRD 4.2, architecture.md §3 "1. 온보딩", conventions.md §4 회원관리)
 */
@RestController
@RequestMapping("/api/users")
@RequiredArgsConstructor
public class UserController {

    private final UserService userService;

    @PostMapping("/onboarding")
    public UserPreferenceResponse onboard(@RequestParam("userId") Long userId,
                                           @RequestBody OnboardingRequest request) {
        return UserPreferenceResponse.from(
                userService.upsertPreference(userId, request.styleTags(), request.bodyInfo()));
    }

    @GetMapping("/onboarding")
    public UserPreferenceResponse getOnboarding(@RequestParam("userId") Long userId) {
        return UserPreferenceResponse.from(userService.getPreference(userId));
    }

    /** JWT로 인증된 본인 계정 정보 조회. */
    @GetMapping("/me")
    public UserMeResponse me(@AuthenticationPrincipal Long userId) {
        return UserMeResponse.from(userService.getMe(userId));
    }

    /** 회원 탈퇴. */
    @DeleteMapping("/me")
    public void deleteMe(@AuthenticationPrincipal Long userId) {
        userService.deleteAccount(userId);
    }
}
