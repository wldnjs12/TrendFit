package com.trendfit.domain.trend.service;

import com.rometools.rome.feed.synd.SyndEntry;
import com.rometools.rome.feed.synd.SyndFeed;
import com.rometools.rome.io.FeedException;
import com.rometools.rome.io.SyndFeedInput;
import com.rometools.rome.io.XmlReader;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.io.IOException;
import java.io.InputStream;
import java.net.URL;
import java.net.URLConnection;
import java.time.Duration;
import java.time.LocalDateTime;
import java.time.ZoneId;
import java.util.ArrayList;
import java.util.Date;
import java.util.List;

/**
 * 확정된 RSS 소스(service-policy.md §3, open-decisions.md A1)에서 원문 아티클을 수집한다.
 * (PRD 4.2 F1, 1주차 PoC)
 *
 * 이 단계에서는 원문 수집까지만 수행한다. Claude 정제(컬러/아이템/무드 키워드 구조화)는
 * 2주차에 ClaudeTrendRefiner 로 별도 구현한다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class TrendSourceCollector {

    private static final int TIMEOUT_MILLIS = (int) Duration.ofSeconds(5).toMillis();

    private final TrendSourceProperties trendSourceProperties;

    public List<RawTrendArticle> fetchLatestArticles() {
        List<RawTrendArticle> articles = new ArrayList<>();
        for (String feedUrl : trendSourceProperties.getSources()) {
            try {
                articles.addAll(fetchFeed(feedUrl));
            } catch (IOException | FeedException e) {
                log.warn("[TrendSourceCollector] {} 수집 실패: {}", feedUrl, e.getMessage());
            }
        }
        return articles;
    }

    /**
     * Rome의 XmlReader(URL)/XmlReader(URLConnection) 생성자는 2.1.0에서 deprecated 되어,
     * 커넥션(타임아웃 포함)은 직접 열고 InputStream만 XmlReader에 넘긴다.
     */
    private List<RawTrendArticle> fetchFeed(String feedUrl) throws IOException, FeedException {
        URLConnection connection = new URL(feedUrl).openConnection();
        connection.setConnectTimeout(TIMEOUT_MILLIS);
        connection.setReadTimeout(TIMEOUT_MILLIS);

        SyndFeedInput input = new SyndFeedInput();
        try (InputStream stream = connection.getInputStream();
             XmlReader reader = new XmlReader(stream)) {
            SyndFeed feed = input.build(reader);
            String sourceName = feed.getTitle();

            List<RawTrendArticle> result = new ArrayList<>();
            for (SyndEntry entry : feed.getEntries()) {
                result.add(new RawTrendArticle(
                        sourceName,
                        entry.getTitle(),
                        entry.getLink(),
                        toLocalDateTime(entry.getPublishedDate())
                ));
            }
            return result;
        }
    }

    private LocalDateTime toLocalDateTime(Date date) {
        return date == null ? null : date.toInstant().atZone(ZoneId.systemDefault()).toLocalDateTime();
    }
}
