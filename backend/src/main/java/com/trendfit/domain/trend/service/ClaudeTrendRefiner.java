package com.trendfit.domain.trend.service;

import com.anthropic.client.AnthropicClient;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.StructuredMessageCreateParams;
import com.trendfit.domain.trend.entity.TrendKeyword;
import com.trendfit.global.config.ClaudeProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.time.LocalDate;
import java.util.ArrayList;
import java.util.List;

/**
 * 원문 아티클(RawTrendArticle)을 Claude로 정제해 컬러/아이템/무드 키워드로 구조화한다.
 * (PRD 4.2 F1, 2주차)
 *
 * 하루 배치당 1회, 텍스트 프롬프트만으로 호출한다(비용 최적화 원칙, PRD 6.5) — 이미지 분석은
 * 옷장 등록(Vision) 단계에서만 수행하고 이 경로에는 관여하지 않는다.
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ClaudeTrendRefiner {

    private static final long MAX_TOKENS = 4096L;

    private final AnthropicClient anthropicClient;
    private final ClaudeProperties claudeProperties;

    public List<TrendKeyword> refine(List<RawTrendArticle> articles) {
        if (articles.isEmpty()) {
            return List.of();
        }

        try {
            TrendExtractionResult result = callClaude(articles);
            return toTrendKeywords(articles, result);
        } catch (Exception e) {
            log.warn("[ClaudeTrendRefiner] 정제 실패: {}", e.getMessage());
            return List.of();
        }
    }

    private TrendExtractionResult callClaude(List<RawTrendArticle> articles) {
        StructuredMessageCreateParams<TrendExtractionResult> params = MessageCreateParams.builder()
                .model(claudeProperties.getModel())
                .maxTokens(MAX_TOKENS)
                .outputConfig(TrendExtractionResult.class)
                .addUserMessage(buildPrompt(articles))
                .build();

        List<TrendExtractionResult> results = anthropicClient.messages().create(params).content().stream()
                .flatMap(block -> block.text().stream())
                .map(typed -> typed.text())
                .toList();

        if (results.isEmpty()) {
            throw new IllegalStateException("Claude 응답에 text 블록이 없음");
        }
        return results.get(0);
    }

    private String buildPrompt(List<RawTrendArticle> articles) {
        StringBuilder sb = new StringBuilder();
        sb.append("다음은 오늘 수집한 패션 매체 기사 제목 목록이다. 각 기사에서 패션 트렌드 키워드를 추출하라: ")
                .append("컬러(colorTag), 아이템(itemTag), 무드(moodTag). 각 값은 짧은 한국어 명사로 답하라. ")
                .append("패션/스타일링과 무관한 기사(스니커 콜라보, 스포츠, 게임, IT 기기 등)는 세 필드를 모두 null로 남겨라. ")
                .append("각 항목의 index는 아래 목록의 번호와 정확히 일치해야 한다.\n\n");
        for (int i = 0; i < articles.size(); i++) {
            RawTrendArticle article = articles.get(i);
            sb.append("[").append(i).append("] ").append(article.sourceName())
                    .append(": ").append(article.title()).append("\n");
        }
        return sb.toString();
    }

    private List<TrendKeyword> toTrendKeywords(List<RawTrendArticle> articles, TrendExtractionResult result) {
        LocalDate today = LocalDate.now();
        List<TrendKeyword> keywords = new ArrayList<>();
        for (TrendKeywordExtraction item : result.items()) {
            if (item.index() < 0 || item.index() >= articles.size()) {
                continue;
            }
            if (item.colorTag() == null && item.itemTag() == null && item.moodTag() == null) {
                continue;
            }
            RawTrendArticle article = articles.get(item.index());
            keywords.add(new TrendKeyword(today, item.colorTag(), item.itemTag(), item.moodTag(), article.link()));
        }
        return keywords;
    }
}
