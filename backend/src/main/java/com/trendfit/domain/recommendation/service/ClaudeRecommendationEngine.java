package com.trendfit.domain.recommendation.service;

import com.anthropic.client.AnthropicClient;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.StructuredMessageCreateParams;
import com.trendfit.domain.closet.port.ClosetItemView;
import com.trendfit.domain.trend.port.TrendKeywordView;
import com.trendfit.global.config.ClaudeProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

import java.util.List;
import java.util.Optional;

/**
 * 프롬프트 조립(Context Injection) + Claude 호출. (PRD 4.2 F3, service-policy.md §4)
 * 벡터DB 기반 RAG는 쓰지 않는다 — 옷장 규모가 MVP 단계에서는 크지 않다는 전제
 * (CLAUDE.md 원칙 #4). 이미지 자체는 프롬프트에 포함하지 않는다 — 등록 시 확정한
 * 카테고리/색상/패턴 텍스트 태그만 재사용한다(비용 최적화, CLAUDE.md 원칙 #3).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ClaudeRecommendationEngine {

    private static final long MAX_TOKENS = 4096L;

    private final AnthropicClient anthropicClient;
    private final ClaudeProperties claudeProperties;

    public Optional<RecommendationResult> recommend(RecommendationContext context) {
        try {
            return Optional.of(callClaude(context));
        } catch (Exception e) {
            log.warn("[ClaudeRecommendationEngine] 추천 생성 실패: {}", e.getMessage());
            return Optional.empty();
        }
    }

    private RecommendationResult callClaude(RecommendationContext context) {
        StructuredMessageCreateParams<RecommendationResult> params = MessageCreateParams.builder()
                .model(claudeProperties.getModel())
                .maxTokens(MAX_TOKENS)
                .outputConfig(RecommendationResult.class)
                .addUserMessage(buildPrompt(context))
                .build();

        List<RecommendationResult> results = anthropicClient.messages().create(params).content().stream()
                .flatMap(block -> block.text().stream())
                .map(typed -> typed.text())
                .toList();

        if (results.isEmpty()) {
            throw new IllegalStateException("Claude 응답에 text 블록이 없음");
        }
        return results.get(0);
    }

    private String buildPrompt(RecommendationContext context) {
        StringBuilder sb = new StringBuilder();
        sb.append("너는 패션 스타일리스트다. 아래 정보를 참고해 사용자에게 오늘의 코디를 추천하라.\n\n");

        sb.append("[오늘 날씨]\n").append(context.weather() != null ? context.weather() : "정보 없음").append("\n\n");

        sb.append("[최신 트렌드 키워드]\n");
        if (context.trendKeywords().isEmpty()) {
            sb.append("없음\n");
        } else {
            for (TrendKeywordView keyword : context.trendKeywords()) {
                sb.append("- 컬러:").append(nullToDash(keyword.colorTag()))
                        .append(" / 아이템:").append(nullToDash(keyword.itemTag()))
                        .append(" / 무드:").append(nullToDash(keyword.moodTag())).append("\n");
            }
        }
        sb.append("\n");

        sb.append("[사용자 취향]\n")
                .append(context.styleTags().isEmpty() ? "없음" : String.join(", ", context.styleTags()))
                .append("\n\n");

        sb.append("[체형 정보]\n")
                .append(context.bodyInfo() != null && !context.bodyInfo().isBlank() ? context.bodyInfo() : "없음")
                .append(" — 체형 정보가 있다면 실루엣/핏이 체형에 어울리는 조합을 우선한다.\n\n");

        sb.append("[보유 옷장]\n");
        for (ClosetItemView item : context.closetItems()) {
            sb.append(item.toPromptTag()).append("\n");
        }
        sb.append("\n");

        sb.append("[사용자 요청]\n").append(context.requestText()).append("\n\n");

        sb.append("""
                위 [보유 옷장] 목록에서만 ID를 골라 오늘 입을 코디를 조합하라(selectedItemIds).
                조합에 대한 한 줄 설명을 stylingNote에 담아라.
                옷장에 없는 아이템으로 트렌드를 보완하면 좋겠다고 판단되면 plusOne으로 제안하고,
                아니면 plusOne은 null로 두어라. plusOne.category는 TOP, BOTTOM, OUTER, DRESS,
                SHOES, ACCESSORY 중 하나로 답하라.
                """);
        return sb.toString();
    }

    private String nullToDash(String value) {
        return value == null ? "-" : value;
    }
}
