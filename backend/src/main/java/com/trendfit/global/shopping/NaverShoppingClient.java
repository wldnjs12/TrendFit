package com.trendfit.global.shopping;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.trendfit.global.config.TimeoutRestClientFactory;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.HttpClientErrorException;
import org.springframework.web.client.RestClient;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.List;
import java.util.Optional;

/**
 * 네이버쇼핑 검색 API 클라이언트. (open-decisions.md A6, 2026-07-29 결정)
 * '+1 아이템' 추천명으로 실제 판매 중인 상품 1건(가격/이미지/구매링크)을 찾아온다.
 * 매칭 실패·키 미설정 시에는 빈 값을 돌려주고, 프론트는 상품 링크 없이 아이템명/이유만 보여준다
 * (WeatherClient와 동일하게 외부 연동 실패가 추천 자체를 막지 않도록 한다).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class NaverShoppingClient {

    private static final String ENDPOINT = "https://openapi.naver.com/v1/search/shop.json";

    /** 응답이 중간에 잘려 들어와 파싱이 깨지는 간헐적 네트워크 문제(운영 로그로 확인됨)를
     * 완화하기 위해 실패 시 한 번만 재시도한다 — 매번 재현되는 데이터 문제가 아니라
     * 일시적 truncation이라 재시도만으로 대부분 해결된다. 단, 자격증명 오류나 정상적인
     * "검색 결과 0건"은 재시도해도 결과가 달라지지 않으므로 재시도 대상에서 제외한다. */
    private static final int MAX_ATTEMPTS = 2;

    private final NaverShoppingProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient = TimeoutRestClientFactory.create(Duration.ofSeconds(3), Duration.ofSeconds(5));

    public Optional<NaverProductView> search(String keyword) {
        if (keyword == null || keyword.isBlank() || isBlank(properties.getClientId()) || isBlank(properties.getClientSecret())) {
            return Optional.empty();
        }

        Exception lastError = null;
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                return Optional.of(fetch(keyword));
            } catch (NoResultException e) {
                // 정상적으로 매칭 상품이 없는 경우 — 재시도해도 결과가 바뀌지 않고, 실패도 아니다.
                log.debug("[NaverShoppingClient] '{}' 검색 결과 없음", keyword);
                return Optional.empty();
            } catch (HttpClientErrorException e) {
                // 401/403 등은 자격증명·설정 문제라 재시도로 해결되지 않는다 — 별도 로그 레벨로
                // 남겨 "정상적으로 결과 없음"과 구분되게 한다.
                log.error("[NaverShoppingClient] '{}' 검색 실패 — 자격증명/요청 오류(status={}): {}",
                        keyword, e.getStatusCode(), e.getMessage());
                return Optional.empty();
            } catch (Exception e) {
                lastError = e;
            }
        }
        log.warn("[NaverShoppingClient] '{}' 검색 실패({}회 시도): {}", keyword, MAX_ATTEMPTS, lastError.getMessage());
        return Optional.empty();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private NaverProductView fetch(String keyword) throws Exception {
        String url = ENDPOINT + "?display=1&sort=sim&query="
                + URLEncoder.encode(keyword, StandardCharsets.UTF_8);

        String body = restClient.get()
                .uri(URI.create(url))
                .header("X-Naver-Client-Id", properties.getClientId())
                .header("X-Naver-Client-Secret", properties.getClientSecret())
                .retrieve()
                .body(String.class);

        NaverShoppingResponse parsed = objectMapper.readValue(body, NaverShoppingResponse.class);
        return parsed.items().stream().findFirst()
                .map(item -> new NaverProductView(
                        stripTags(item.title()), item.link(), item.image(), item.lprice(), item.mallName()))
                .orElseThrow(NoResultException::new);
    }

    /** 검색어에 매칭되는 상품이 없는, 정상적인 빈 결과임을 나타낸다(자격증명·네트워크 오류와 구분). */
    private static final class NoResultException extends RuntimeException {
    }

    private String stripTags(String html) {
        return html == null ? null : html.replaceAll("<[^>]+>", "");
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record NaverShoppingResponse(List<NaverShoppingItem> items) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record NaverShoppingItem(String title, String link, String image, String lprice, String mallName) {
    }
}
