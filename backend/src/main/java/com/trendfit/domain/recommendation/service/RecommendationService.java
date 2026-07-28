package com.trendfit.domain.recommendation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.trendfit.domain.closet.port.ClosetItemView;
import com.trendfit.domain.closet.port.ClosetQueryPort;
import com.trendfit.domain.recommendation.dto.PlusOneResponse;
import com.trendfit.domain.recommendation.dto.RecommendationResponse;
import com.trendfit.domain.recommendation.dto.RecommendedItemResponse;
import com.trendfit.domain.recommendation.entity.RecommendationLog;
import com.trendfit.domain.recommendation.repository.RecommendationLogRepository;
import com.trendfit.domain.trend.port.TrendQueryPort;
import com.trendfit.domain.user.port.UserPreferencePort;
import com.trendfit.domain.user.port.UserPreferenceView;
import com.trendfit.global.storage.ImageUrls;
import com.trendfit.global.weather.WeatherClient;
import com.trendfit.global.weather.WeatherSummary;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.io.UncheckedIOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 추천 요청 오케스트레이션: 옷장 활성화·빈도 제한 확인 -> 컨텍스트 조회 -> Claude 호출 ->
 * ID-이미지 매핑 -> RecommendationLog 저장. (PRD 4.2 F3)
 */
@Service
@RequiredArgsConstructor
public class RecommendationService {

    /** open-decisions.md A2(2026-07-27): 최소 3벌 + 상의/원피스 1개 이상 & 하의 1개 이상. */
    private static final int MIN_CLOSET_SIZE = 3;

    /** open-decisions.md A5(2026-07-27): 하루 10회/사용자 소프트캡. */
    private static final int DAILY_REQUEST_LIMIT = 10;

    /** 위치 입력 UI가 아직 없어 기본값으로 쓰는 서울시청 좌표. */
    private static final double DEFAULT_LAT = 37.5665;
    private static final double DEFAULT_LON = 126.9780;

    private final ClosetQueryPort closetQueryPort;
    private final UserPreferencePort userPreferencePort;
    private final TrendQueryPort trendQueryPort;
    private final WeatherClient weatherClient;
    private final ClaudeRecommendationEngine recommendationEngine;
    private final RecommendationLogRepository recommendationLogRepository;
    private final ObjectMapper objectMapper;

    @Transactional
    public RecommendationResponse requestRecommendation(Long userId, String requestText, Double lat, Double lon) {
        enforceRateLimit(userId);

        List<ClosetItemView> closetItems = closetQueryPort.findAllByUserId(userId);
        enforceClosetActivation(closetItems);

        List<String> styleTags = userPreferencePort.findPreference(userId)
                .map(UserPreferenceView::styleTags)
                .orElse(List.of());
        String weather = weatherClient.fetchTodayWeather(
                        lat != null ? lat : DEFAULT_LAT,
                        lon != null ? lon : DEFAULT_LON)
                .map(WeatherSummary::toPromptText)
                .orElse(null);

        RecommendationContext context = new RecommendationContext(
                requestText, weather, trendQueryPort.findLatestKeywords(), styleTags, closetItems);

        RecommendationResult result = recommendationEngine.recommend(context)
                .orElseThrow(() -> new IllegalStateException("추천을 생성하지 못했습니다. 잠시 후 다시 시도해주세요."));

        Map<Long, ClosetItemView> closetById = closetItems.stream()
                .collect(Collectors.toMap(ClosetItemView::id, Function.identity()));
        List<ClosetItemView> selected = result.selectedItemIds().stream()
                .map(closetById::get)
                .filter(Objects::nonNull)
                .toList();

        RecommendationLog log = recommendationLogRepository.save(new RecommendationLog(
                userId,
                requestText,
                writeJson(result.selectedItemIds()),
                result.plusOne() == null ? null : writeJson(result.plusOne())));

        return new RecommendationResponse(
                log.getId(),
                selected.stream()
                        .map(item -> new RecommendedItemResponse(
                                item.id(), item.category(), ImageUrls.toUrl(item.croppedImagePath())))
                        .toList(),
                result.stylingNote(),
                result.plusOne() == null ? null : new PlusOneResponse(
                        result.plusOne().itemName(), result.plusOne().reason(), result.plusOne().category()));
    }

    private void enforceRateLimit(Long userId) {
        LocalDateTime since = LocalDate.now().atStartOfDay();
        long count = recommendationLogRepository.countByUserIdAndCreatedAtAfter(userId, since);
        if (count >= DAILY_REQUEST_LIMIT) {
            throw new IllegalStateException("오늘 추천 요청 횟수(" + DAILY_REQUEST_LIMIT + "회)를 모두 사용했습니다.");
        }
    }

    private void enforceClosetActivation(List<ClosetItemView> items) {
        if (items.size() < MIN_CLOSET_SIZE) {
            throw new IllegalStateException("옷장에 옷을 최소 " + MIN_CLOSET_SIZE + "벌 이상 등록해야 추천을 받을 수 있습니다.");
        }
        boolean hasTopOrDress = items.stream()
                .anyMatch(item -> "TOP".equals(item.category()) || "DRESS".equals(item.category()));
        boolean hasBottom = items.stream().anyMatch(item -> "BOTTOM".equals(item.category()));
        if (!hasTopOrDress || !hasBottom) {
            throw new IllegalStateException("상의(또는 원피스)와 하의를 각 1개 이상 등록해야 추천을 받을 수 있습니다.");
        }
    }

    private String writeJson(Object value) {
        try {
            return objectMapper.writeValueAsString(value);
        } catch (JsonProcessingException e) {
            throw new UncheckedIOException(e);
        }
    }
}
