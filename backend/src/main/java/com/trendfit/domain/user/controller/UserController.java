package com.trendfit.domain.user.controller;

import com.trendfit.domain.user.dto.OnboardingRequest;
import com.trendfit.domain.user.dto.UserPreferenceResponse;
import com.trendfit.domain.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

/**
 * 온보딩(취향 선택) API. (PRD 4.2, architecture.md §3 "1. 온보딩")
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
}
