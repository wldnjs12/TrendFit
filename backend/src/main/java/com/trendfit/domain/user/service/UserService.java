package com.trendfit.domain.user.service;

import com.trendfit.domain.user.entity.User;
import com.trendfit.domain.user.entity.UserPreference;
import com.trendfit.domain.user.port.UserPreferencePort;
import com.trendfit.domain.user.port.UserPreferenceView;
import com.trendfit.domain.user.repository.UserPreferenceRepository;
import com.trendfit.domain.user.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Arrays;
import java.util.List;
import java.util.Optional;

/**
 * 온보딩 취향 프로필 등록/조회. (PRD 4.2, service-policy.md §1)
 * UserPreferencePort를 구현해 Recommendation에 취향 조회를 제공한다(domain-design.md §2, B4 결정).
 */
@Service
@RequiredArgsConstructor
public class UserService implements UserPreferencePort {

    private final UserRepository userRepository;
    private final UserPreferenceRepository userPreferenceRepository;

    @Transactional
    public UserPreference upsertPreference(Long userId, List<String> styleTags, String bodyInfo) {
        validateStyleTags(styleTags);
        String joinedTags = String.join(",", styleTags);

        return userPreferenceRepository.findByUserId(userId)
                .map(existing -> {
                    existing.updatePreference(joinedTags, bodyInfo);
                    return existing;
                })
                .orElseGet(() -> {
                    User user = userRepository.findById(userId)
                            .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자: " + userId));
                    return userPreferenceRepository.save(new UserPreference(user, joinedTags, bodyInfo));
                });
    }

    @Transactional(readOnly = true)
    public UserPreference getPreference(Long userId) {
        return userPreferenceRepository.findByUserId(userId)
                .orElseThrow(() -> new IllegalArgumentException("온보딩이 완료되지 않은 사용자: " + userId));
    }

    @Transactional(readOnly = true)
    public User getMe(Long userId) {
        return userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));
    }

    /**
     * 회원 탈퇴. User 컨텍스트 소유 데이터(User, UserPreference)만 정리한다 — 옷장/추천 이력은
     * 다른 컨텍스트 소유 데이터라 ID 참조만 남기고 직접 삭제하지 않는다(conventions.md §3,
     * 컨텍스트 간 직접 의존 금지).
     */
    @Transactional
    public void deleteAccount(Long userId) {
        User user = userRepository.findById(userId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 사용자입니다."));
        userPreferenceRepository.findByUserId(userId).ifPresent(userPreferenceRepository::delete);
        userRepository.delete(user);
    }

    @Override
    @Transactional(readOnly = true)
    public Optional<UserPreferenceView> findPreference(Long userId) {
        return userPreferenceRepository.findByUserId(userId)
                .map(preference -> new UserPreferenceView(
                        parseStyleTags(preference.getStyleTags()),
                        preference.getBodyInfo()));
    }

    private List<String> parseStyleTags(String raw) {
        if (raw == null || raw.isBlank()) {
            return List.of();
        }
        return Arrays.asList(raw.split(","));
    }

    private void validateStyleTags(List<String> styleTags) {
        if (styleTags == null || styleTags.isEmpty()) {
            throw new IllegalArgumentException("스타일 취향은 최소 1개 이상 선택해야 합니다.");
        }
        for (String tag : styleTags) {
            UserPreference.StyleTag.fromLabel(tag);
        }
    }
}
