package com.trendfit.global.shopping;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import com.fasterxml.jackson.dataformat.xml.XmlMapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlElementWrapper;
import com.fasterxml.jackson.dataformat.xml.annotation.JacksonXmlProperty;
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
 * 11번가 오픈API(ProductSearch) 클라이언트. (open-decisions.md A6)
 * '+1 아이템' 추천명으로 실제 판매 중인 상품 1건(가격/이미지/구매링크)을 찾아온다.
 * 이전 네이버쇼핑 검색 API가 2026-07-31 대체 API 없이 종료되어 이걸로 교체 시도했으나(2026-08-05),
 * 신청해보니 판매자(셀러) 계정에만 공개되는 API라 일반 개발자로는 키 발급이 불가능함을 확인
 * (2026-08-06) — 상품 검색 연동 자체를 보류하기로 하면서 이 클라이언트는 활성화되지 않은 채
 * 남아 있다(`ELEVEN_ST_API_KEY` 미설정 시 항상 빈 값 반환). 이후 셀러 계정을 확보하거나 다른
 * API로 교체하면 이 클래스를 그대로 활성화하거나 참고할 수 있다. 매칭 실패·키 미설정 시에는
 * 빈 값을 돌려주고, 프론트는 상품 링크 없이 아이템명/이유만 보여준다(WeatherClient와 동일 원칙).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ElevenStShoppingClient {

    private static final String ENDPOINT = "https://openapi.11st.co.kr/openapi/OpenApiService.tmall";

    /** 일시적 네트워크/파싱 문제 완화를 위해 실패 시 한 번만 재시도한다 — 자격증명 오류나
     * 정상적인 "검색 결과 0건"은 재시도해도 결과가 바뀌지 않으므로 대상에서 제외한다. */
    private static final int MAX_ATTEMPTS = 2;

    private final ElevenStShoppingProperties properties;
    private final XmlMapper xmlMapper = new XmlMapper();
    private final RestClient restClient = TimeoutRestClientFactory.create(Duration.ofSeconds(3), Duration.ofSeconds(5));

    public Optional<ShoppingProductView> search(String keyword) {
        if (keyword == null || keyword.isBlank() || isBlank(properties.getApiKey())) {
            return Optional.empty();
        }

        Exception lastError = null;
        for (int attempt = 1; attempt <= MAX_ATTEMPTS; attempt++) {
            try {
                return Optional.of(fetch(keyword));
            } catch (NoResultException e) {
                // 정상적으로 매칭 상품이 없는 경우 — 재시도해도 결과가 바뀌지 않고, 실패도 아니다.
                log.debug("[ElevenStShoppingClient] '{}' 검색 결과 없음", keyword);
                return Optional.empty();
            } catch (HttpClientErrorException e) {
                // 4xx는 자격증명/요청 문제라 재시도로 해결되지 않는다 — 별도 로그 레벨로 남겨
                // "정상적으로 결과 없음"과 구분되게 한다.
                log.error("[ElevenStShoppingClient] '{}' 검색 실패 — 자격증명/요청 오류(status={}): {}",
                        keyword, e.getStatusCode(), e.getMessage());
                return Optional.empty();
            } catch (Exception e) {
                lastError = e;
            }
        }
        log.warn("[ElevenStShoppingClient] '{}' 검색 실패({}회 시도): {}", keyword, MAX_ATTEMPTS, lastError.getMessage());
        return Optional.empty();
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private ShoppingProductView fetch(String keyword) throws Exception {
        String url = ENDPOINT + "?key=" + properties.getApiKey()
                + "&apiCode=ProductSearch&keyword=" + URLEncoder.encode(keyword, StandardCharsets.UTF_8);

        String body = restClient.get()
                .uri(URI.create(url))
                .retrieve()
                .body(String.class);

        ProductSearchResponse parsed = xmlMapper.readValue(body, ProductSearchResponse.class);
        List<Product> products = parsed.products() == null ? List.of() : parsed.products();
        return products.stream().findFirst()
                .map(p -> new ShoppingProductView(
                        stripTags(p.productName()), p.detailPageUrl(), p.productImage(), p.salePrice(), p.seller()))
                .orElseThrow(NoResultException::new);
    }

    private String stripTags(String html) {
        return html == null ? null : html.replaceAll("<[^>]+>", "");
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record ProductSearchResponse(
            @JacksonXmlElementWrapper(localName = "Products")
            @JacksonXmlProperty(localName = "Product")
            List<Product> products
    ) {
    }

    @JsonIgnoreProperties(ignoreUnknown = true)
    private record Product(
            @JacksonXmlProperty(localName = "ProductName") String productName,
            @JacksonXmlProperty(localName = "ProductImage") String productImage,
            @JacksonXmlProperty(localName = "DetailPageUrl") String detailPageUrl,
            @JacksonXmlProperty(localName = "SalePrice") String salePrice,
            @JacksonXmlProperty(localName = "Seller") String seller
    ) {
    }

    /** 검색어에 매칭되는 상품이 없는, 정상적인 빈 결과임을 나타낸다(자격증명·네트워크 오류와 구분). */
    private static final class NoResultException extends RuntimeException {
    }
}
