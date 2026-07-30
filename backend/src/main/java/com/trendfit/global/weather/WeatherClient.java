package com.trendfit.global.weather;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.trendfit.global.config.TimeoutRestClientFactory;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.URI;
import java.time.Duration;
import java.time.LocalDate;
import java.time.ZoneId;
import java.time.ZonedDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;
import java.util.Optional;

/**
 * 기상청 단기예보조회(getVilageFcst) 클라이언트. (service-policy.md §4, open-decisions.md A3,
 * 2026-07-27 결정)
 *
 * 매 요청마다 최신 02시 발표(base_time=0200) 자료를 조회한다 — 단기예보는 3일치를 한 번에
 * 내려주므로 하루 8회(02,05,08,11,14,17,20,23시) 중 아무 발표나 있으면 오늘 날씨를 구할 수 있고,
 * 02시 발표만 써도 충분하다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class WeatherClient {

    private static final String ENDPOINT = "https://apis.data.go.kr/1360000/VilageFcstInfoService_2.0/getVilageFcst";
    private static final ZoneId KST = ZoneId.of("Asia/Seoul");
    private static final DateTimeFormatter DATE_FORMAT = DateTimeFormatter.ofPattern("yyyyMMdd");

    private final WeatherProperties weatherProperties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient = TimeoutRestClientFactory.create(Duration.ofSeconds(3), Duration.ofSeconds(5));

    public Optional<WeatherSummary> fetchTodayWeather(double lat, double lon) {
        try {
            GridCoordinate grid = GridConverter.toGrid(lat, lon);
            String baseDate = resolveBaseDate().format(DATE_FORMAT);
            String today = LocalDate.now(KST).format(DATE_FORMAT);

            String responseBody = restClient.get()
                    .uri(URI.create(buildUrl(baseDate, grid)))
                    .retrieve()
                    .body(String.class);

            VilageFcstApiResponse parsed = objectMapper.readValue(responseBody, VilageFcstApiResponse.class);
            List<ForecastItem> items = parsed.response().body().items().item();

            return Optional.of(summarize(items, today));
        } catch (Exception e) {
            log.warn("[WeatherClient] 날씨 조회 실패: {}", e.getMessage());
            return Optional.empty();
        }
    }

    private String buildUrl(String baseDate, GridCoordinate grid) {
        return ENDPOINT
                + "?serviceKey=" + weatherProperties.getApiKey()
                + "&pageNo=1&numOfRows=1000&dataType=JSON"
                + "&base_date=" + baseDate
                + "&base_time=0200"
                + "&nx=" + grid.nx()
                + "&ny=" + grid.ny();
    }

    private LocalDate resolveBaseDate() {
        ZonedDateTime now = ZonedDateTime.now(KST);
        return now.getHour() <= 2 ? now.toLocalDate().minusDays(1) : now.toLocalDate();
    }

    private WeatherSummary summarize(List<ForecastItem> items, String today) {
        String minTemp = firstValue(items, "TMN", today);
        String maxTemp = firstValue(items, "TMX", today);
        String pty = firstValue(items, "PTY", today);
        String pop = firstValue(items, "POP", today);
        String condition = (pty != null && !"0".equals(pty))
                ? toPtyText(pty)
                : toSkyText(firstValue(items, "SKY", today));

        return new WeatherSummary(minTemp, maxTemp, condition, pop);
    }

    private String firstValue(List<ForecastItem> items, String category, String date) {
        return items.stream()
                .filter(item -> category.equals(item.category()) && date.equals(item.fcstDate()))
                .map(ForecastItem::fcstValue)
                .findFirst()
                .orElse(null);
    }

    private String toSkyText(String code) {
        if (code == null) {
            return null;
        }
        return switch (code) {
            case "1" -> "맑음";
            case "3" -> "구름많음";
            case "4" -> "흐림";
            default -> "알수없음";
        };
    }

    private String toPtyText(String code) {
        return switch (code) {
            case "1" -> "비";
            case "2" -> "비/눈";
            case "3" -> "눈";
            case "4" -> "소나기";
            default -> "강수";
        };
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record VilageFcstApiResponse(ResponseEnvelope response) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record ResponseEnvelope(ResponseBody body) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record ResponseBody(Items items) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Items(List<ForecastItem> item) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record ForecastItem(String category, String fcstDate, String fcstTime, String fcstValue) {
    }
}
