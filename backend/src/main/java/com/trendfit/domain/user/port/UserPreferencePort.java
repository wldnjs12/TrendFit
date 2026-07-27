package com.trendfit.domain.user.port;

import java.util.Optional;

/**
 * Recommendation이 User 컨텍스트의 취향 프로필을 조회하는 포트.
 * User 컨텍스트가 소유·구현하며, Recommendation은 이 인터페이스만 의존한다
 * (domain-design.md §2 — 다른 컨텍스트의 리포지토리를 직접 주입받지 않는다).
 */
public interface UserPreferencePort {

    Optional<UserPreferenceView> findPreference(Long userId);
}
