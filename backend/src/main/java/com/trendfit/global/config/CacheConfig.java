package com.trendfit.global.config;

import org.springframework.cache.annotation.EnableCaching;
import org.springframework.context.annotation.Configuration;

/**
 * 트렌드 키워드(배치로만 갱신)·날씨(좌표+날짜 단위로 사실상 불변) 캐싱을 켠다.
 * MVP 트래픽 규모라 Redis 등 외부 캐시 인프라 없이 기본 인메모리
 * (ConcurrentMapCacheManager)로 충분하다.
 */
@Configuration
@EnableCaching
public class CacheConfig {
}
