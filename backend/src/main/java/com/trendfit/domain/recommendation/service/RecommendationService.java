package com.trendfit.domain.recommendation.service;

import com.fasterxml.jackson.core.JsonProcessingException;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.trendfit.domain.closet.port.ClosetItemView;
import com.trendfit.domain.closet.port.ClosetQueryPort;
import com.trendfit.domain.recommendation.dto.PlusOneResponse;
import com.trendfit.domain.recommendation.dto.RecommendationHistoryItemResponse;
import com.trendfit.domain.recommendation.dto.RecommendationResponse;
import com.trendfit.domain.recommendation.dto.RecommendedItemResponse;
import com.trendfit.domain.recommendation.entity.RecommendationLog;
import com.trendfit.domain.recommendation.repository.RecommendationLogRepository;
import com.trendfit.domain.trend.port.TrendKeywordView;
import com.trendfit.domain.trend.port.TrendQueryPort;
import com.trendfit.domain.user.port.UserPreferencePort;
import com.trendfit.domain.user.port.UserPreferenceView;
import com.trendfit.global.shopping.NaverProductView;
import com.trendfit.global.shopping.NaverShoppingClient;
import com.trendfit.global.storage.ImageStorage;
import com.trendfit.global.storage.ImageUrls;
import com.trendfit.global.weather.WeatherClient;
import com.trendfit.global.weather.WeatherSummary;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.List;
import java.util.Map;
import java.util.Objects;
import java.util.Optional;
import java.util.concurrent.CompletableFuture;
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

    /** 서버 배포 환경의 기본 타임존이 KST가 아닐 수 있어(예: Railway 컨테이너는 UTC), 날짜 경계
     * 계산에 항상 이 존을 명시한다 — 안 그러면 자정 전후 요청이 다른 요일로 잘못 집계된다. */
    private static final ZoneId KST = ZoneId.of("Asia/Seoul");

    private final ClosetQueryPort closetQueryPort;
    private final UserPreferencePort userPreferencePort;
    private final TrendQueryPort trendQueryPort;
    private final WeatherClient weatherClient;
    private final ClaudeRecommendationEngine recommendationEngine;
    private final RecommendationLogRepository recommendationLogRepository;
    private final ObjectMapper objectMapper;
    private final ImageStorage imageStorage;
    private final NaverShoppingClient naverShoppingClient;

    // Claude/날씨/네이버 호출(합쳐서 수초~십수초)이 전부 끝난 뒤에야 마지막에 RecommendationLog
    // 하나를 저장한다. 여기에 @Transactional을 걸면 그 외부 호출 내내 DB 커넥션을 점유하게 되어
    // 동시 요청이 늘면 커넥션 풀이 고갈될 수 있다 — 조회/저장은 각각 Spring Data 메서드 단위
    // 트랜잭션으로 처리되고, 이 메서드 전체를 하나의 원자적 단위로 묶을 필요는 없다.
    public RecommendationResponse requestRecommendation(Long userId, String requestText, Double lat, Double lon) {
        enforceRateLimit(userId);

        List<ClosetItemView> closetItems = closetQueryPort.findAllByUserId(userId);
        enforceClosetActivation(closetItems);

        Optional<UserPreferenceView> preference = userPreferencePort.findPreference(userId);
        List<String> styleTags = preference.map(UserPreferenceView::styleTags).orElse(List.of());
        String bodyInfo = preference.map(UserPreferenceView::bodyInfo).orElse(null);

        // 날씨 조회(외부 HTTP)와 트렌드 키워드 조회는 서로 의존이 없어 병렬로 실행한다.
        CompletableFuture<String> weatherFuture = CompletableFuture.supplyAsync(() ->
                weatherClient.fetchTodayWeather(
                                lat != null ? lat : DEFAULT_LAT,
                                lon != null ? lon : DEFAULT_LON)
                        .map(WeatherSummary::toPromptText)
                        .orElse(null));
        CompletableFuture<List<TrendKeywordView>> trendFuture =
                CompletableFuture.supplyAsync(trendQueryPort::findLatestKeywords);

        RecommendationContext context = new RecommendationContext(
                requestText, weatherFuture.join(), trendFuture.join(), styleTags, bodyInfo, closetItems);

        RecommendationResult result = recommendationEngine.recommend(context)
                .orElseThrow(() -> new IllegalStateException("추천을 생성하지 못했습니다. 잠시 후 다시 시도해주세요."));

        Map<Long, ClosetItemView> closetById = closetItems.stream()
                .collect(Collectors.toMap(ClosetItemView::id, Function.identity()));
        List<ClosetItemView> selected = result.selectedItemIds().stream()
                .map(closetById::get)
                .filter(Objects::nonNull)
                .toList();

        LocalDate forDate = KoreanDatePhraseParser.resolve(requestText, LocalDate.now(KST));

        RecommendationLog log = recommendationLogRepository.save(new RecommendationLog(
                userId,
                requestText,
                forDate,
                writeJson(result.selectedItemIds()),
                result.plusOne() == null ? null : writeJson(result.plusOne())));

        return new RecommendationResponse(
                log.getId(),
                selected.stream()
                        .map(item -> new RecommendedItemResponse(
                                item.id(), item.category(), ImageUrls.toUrl(item.croppedImagePath())))
                        .toList(),
                result.stylingNote(),
                result.plusOne() == null ? null : buildPlusOneResponse(result.plusOne()));
    }

    /** '+1 아이템' 추천명으로 네이버쇼핑에서 실제 구매 가능한 상품을 찾아 함께 내려준다(A6). */
    private PlusOneResponse buildPlusOneResponse(PlusOneSuggestion plusOne) {
        Optional<NaverProductView> product = naverShoppingClient.search(plusOne.itemName());
        return new PlusOneResponse(
                plusOne.itemName(),
                plusOne.reason(),
                plusOne.category(),
                product.map(NaverProductView::link).orElse(null),
                product.map(NaverProductView::imageUrl).orElse(null),
                product.map(NaverProductView::mallName).orElse(null),
                product.map(NaverProductView::lowPrice).orElse(null));
    }

    /** 캘린더(위클리 아카이브) — weekStart(월요일)부터 7일치 추천 이력을 날짜순으로 반환한다. */
    @Transactional(readOnly = true)
    public List<RecommendationHistoryItemResponse> getWeeklyHistory(Long userId, LocalDate weekStart) {
        LocalDate end = weekStart.plusDays(7);

        List<RecommendationLog> logs = recommendationLogRepository
                .findByUserIdAndConfirmedTrueAndForDateBetweenOrderByForDateAsc(userId, weekStart, end);
        if (logs.isEmpty()) {
            return List.of();
        }

        Map<Long, ClosetItemView> closetById = closetQueryPort.findAllByUserId(userId).stream()
                .collect(Collectors.toMap(ClosetItemView::id, Function.identity()));

        return logs.stream()
                .map(log -> new RecommendationHistoryItemResponse(
                        log.getId(),
                        log.getForDate(),
                        readItemIds(log.getResultItemIdsJson()).stream()
                                .map(closetById::get)
                                .filter(Objects::nonNull)
                                .map(item -> new RecommendedItemResponse(
                                        item.id(), item.category(), ImageUrls.toUrl(item.croppedImagePath())))
                                .toList(),
                        log.getRequestText(),
                        ImageUrls.toUrl(log.getWornPhotoPath())))
                .toList();
    }

    /**
     * 캘린더에서 기록 없는 날을 눌러 착용샷만 바로 등록하는 경로 — AI 추천 없이 즉시 확정된
     * 이력을 만든다(route 2). "오늘의 코디로 결정하기"로 저장되는 route 1과 달리 승인 절차가
     * 없다 — 사용자가 직접 날짜를 골라 사진을 올리는 행위 자체가 확정 의사이기 때문이다.
     */
    @Transactional
    public RecommendationHistoryItemResponse createWornPhotoEntry(Long userId, LocalDate forDate, MultipartFile image) {
        try {
            String key = imageStorage.save(image.getBytes(), image.getOriginalFilename());
            RecommendationLog log = recommendationLogRepository.save(
                    RecommendationLog.forWornPhotoOnly(userId, forDate, key));
            return new RecommendationHistoryItemResponse(
                    log.getId(), log.getForDate(), List.of(), null, ImageUrls.toUrl(key));
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    /** 결과 화면에서 "오늘의 코디로 결정하기"를 눌렀을 때 호출 — 이때부터 캘린더에 노출된다. */
    @Transactional
    public void confirmRecommendation(Long userId, Long logId) {
        RecommendationLog log = recommendationLogRepository.findById(logId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 추천 이력: " + logId));
        if (!log.getUserId().equals(userId)) {
            throw new IllegalArgumentException("본인의 추천 이력만 확정할 수 있습니다.");
        }
        log.confirm();
    }

    /**
     * 캘린더에서 사용자가 "오늘 실제로 이렇게 입었어요" 사진을 등록/교체한다. AI가 추천한 코디
     * 이미지와는 별개로 저장되며, 옷장 등록 때처럼 Vision 분석은 하지 않고 그대로 저장만 한다
     * (CLAUDE.md §5 — Vision 재호출 금지 원칙과 별개로, 이 사진은 애초에 분석 대상이 아니다).
     */
    @Transactional
    public String uploadWornPhoto(Long userId, Long logId, MultipartFile image) {
        RecommendationLog log = recommendationLogRepository.findById(logId)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 추천 이력: " + logId));
        if (!log.getUserId().equals(userId)) {
            throw new IllegalArgumentException("본인의 추천 이력에만 착용샷을 등록할 수 있습니다.");
        }
        try {
            String key = imageStorage.save(image.getBytes(), image.getOriginalFilename());
            log.attachWornPhoto(key);
            return ImageUrls.toUrl(key);
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }

    private List<Long> readItemIds(String json) {
        if (json == null || json.isBlank()) {
            return List.of();
        }
        try {
            return objectMapper.readValue(json, new TypeReference<List<Long>>() {});
        } catch (JsonProcessingException e) {
            throw new UncheckedIOException(e);
        }
    }

    private void enforceRateLimit(Long userId) {
        LocalDateTime since = LocalDate.now(KST).atStartOfDay();
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
