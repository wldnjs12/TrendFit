package com.trendfit.global.shopping;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.databind.ObjectMapper;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.client.RestClient;

import java.net.URI;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
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

    private final NaverShoppingProperties properties;
    private final ObjectMapper objectMapper;
    private final RestClient restClient = RestClient.create();

    public Optional<NaverProductView> search(String keyword) {
        if (keyword == null || keyword.isBlank()
                || properties.getClientId() == null || properties.getClientId().isBlank()) {
            return Optional.empty();
        }
        try {
            String url = ENDPOINT + "?display=1&sort=sim&query="
                    + URLEncoder.encode(keyword, StandardCharsets.UTF_8);

            String body = restClient.get()
                    .uri(URI.create(url))
                    .header("X-Naver-Client-Id", properties.getClientId())
                    .header("X-Naver-Client-Secret", properties.getClientSecret())
                    .retrieve()
                    .body(String.class);

            NaverShoppingResponse parsed = objectMapper.readValue(body, NaverShoppingResponse.class);
            return parsed.items().stream().findFirst().map(item -> new NaverProductView(
                    stripTags(item.title()), item.link(), item.image(), item.lprice(), item.mallName()));
        } catch (Exception e) {
            log.warn("[NaverShoppingClient] '{}' 검색 실패: {}", keyword, e.getMessage());
            return Optional.empty();
        }
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
