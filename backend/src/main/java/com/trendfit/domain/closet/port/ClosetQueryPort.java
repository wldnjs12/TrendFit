package com.trendfit.domain.closet.port;

import java.util.List;

/**
 * Recommendation이 Closet 컨텍스트의 옷장 전체(ID+태그)를 조회하는 포트.
 * Closet 컨텍스트가 소유·구현하며, Recommendation은 이 인터페이스만 의존한다
 * (domain-design.md §2).
 */
public interface ClosetQueryPort {

    List<ClosetItemView> findAllByUserId(Long userId);
}
