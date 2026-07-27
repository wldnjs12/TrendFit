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
import java.net.URL;
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

    private List<RawTrendArticle> fetchFeed(String feedUrl) throws IOException, FeedException {
        SyndFeedInput input = new SyndFeedInput();
        try (XmlReader reader = new XmlReader(new URL(feedUrl))) {
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
