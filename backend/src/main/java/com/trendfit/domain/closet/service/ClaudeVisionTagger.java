package com.trendfit.domain.closet.service;

import com.anthropic.client.AnthropicClient;
import com.anthropic.models.messages.Base64ImageSource;
import com.anthropic.models.messages.ContentBlockParam;
import com.anthropic.models.messages.ImageBlockParam;
import com.anthropic.models.messages.MessageCreateParams;
import com.anthropic.models.messages.StructuredMessageCreateParams;
import com.anthropic.models.messages.TextBlockParam;
import com.anthropic.models.messages.ThinkingConfigDisabled;
import com.trendfit.global.config.ClaudeProperties;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.ArrayList;
import java.util.Base64;
import java.util.List;

/**
 * 옷장 등록 시 Claude Vision을 호출해 카테고리/색상/패턴/크롭 좌표를 추출한다.
 * 등록 요청당 1회만 호출하며(이미지 여러 장을 한 번에 묶어서), 이후 반복 상호작용(추천 요청)은
 * 이 결과를 텍스트 태그로 재사용할 뿐 Vision을 다시 호출하지 않는다
 * (CLAUDE.md 원칙 #3, PRD 6.5 비용 최적화).
 */
@Slf4j
@Component
@RequiredArgsConstructor
public class ClaudeVisionTagger {

    private static final long MAX_TOKENS = 4096L;

    private final AnthropicClient anthropicClient;
    private final ClaudeProperties claudeProperties;

    public List<ClothingTagExtraction> tagAll(List<MultipartFile> images) {
        if (images.isEmpty()) {
            return List.of();
        }

        try {
            return callClaude(images).items();
        } catch (Exception e) {
            log.warn("[ClaudeVisionTagger] 태깅 실패: {}", e.getMessage());
            return List.of();
        }
    }

    private ClothingTagExtractionResult callClaude(List<MultipartFile> images) throws IOException {
        List<ContentBlockParam> blocks = new ArrayList<>();
        blocks.add(ContentBlockParam.ofText(TextBlockParam.builder().text(buildPrompt(images.size())).build()));

        for (MultipartFile image : images) {
            byte[] bytes = ImageDownscaler.downscale(image.getBytes());
            Base64ImageSource source = Base64ImageSource.builder()
                    .data(Base64.getEncoder().encodeToString(bytes))
                    .mediaType(detectMediaType(bytes))
                    .build();
            blocks.add(ContentBlockParam.ofImage(ImageBlockParam.builder().source(source).build()));
        }

        StructuredMessageCreateParams<ClothingTagExtractionResult> params = MessageCreateParams.builder()
                .model(claudeProperties.getModel())
                .maxTokens(MAX_TOKENS)
                // claude-sonnet-5는 thinking을 명시하지 않으면 기본값이 off가 아니라 adaptive로 켜진다.
                // 카테고리/색상/패턴 추출은 추론이 필요 없는 단순 작업이라 매 호출 reasoning 토큰만
                // 낭비되며 등록이 느려지는 주요 원인이었다 — 명시적으로 꺼서 지연시간을 줄인다.
                .thinking(ThinkingConfigDisabled.builder().build())
                .outputConfig(ClothingTagExtractionResult.class)
                .addUserMessageOfBlockParams(blocks)
                .build();

        List<ClothingTagExtractionResult> results = anthropicClient.messages().create(params).content().stream()
                .flatMap(block -> block.text().stream())
                .map(typed -> typed.text())
                .toList();

        if (results.isEmpty()) {
            throw new IllegalStateException("Claude 응답에 text 블록이 없음");
        }
        return results.get(0);
    }

    private String buildPrompt(int imageCount) {
        return """
                다음은 사용자가 옷장에 등록하려는 의류 사진 %d장이다. 각 사진에서 다음을 추출하라:
                - category: TOP, BOTTOM, OUTER, DRESS, SHOES, ACCESSORY 중 하나
                - color: 짧은 한국어 색상명 (예: "화이트", "버건디")
                - pattern: 짧은 한국어 패턴명 (예: "무지", "스트라이프"), 판단 어려우면 null
                - cropBox: 옷 부분만 감싸는 사각형을 이미지 전체 크기 대비 0~1 정규화 좌표로
                  {x, y, width, height} 형태로 표현 (x, y는 좌상단 기준)

                이미지는 첨부된 순서대로 [0], [1], ... 이다. 각 항목의 index는 이 순서와
                정확히 일치해야 하며, 모든 이미지에 대해 하나씩 항목을 반환하라.
                """.formatted(imageCount);
    }

    /**
     * 이미지 실제 바이트(매직 넘버)로 포맷을 판별한다. 업로드하는 브라우저/클라이언트가
     * Content-Type 헤더를 붙이지 않거나 잘못 붙이는 경우가 흔해서(예: PNG인데
     * application/octet-stream 또는 image/jpeg로 옴), 선언된 Content-Type을 그대로 믿으면
     * Claude가 "선언된 타입과 실제 이미지가 다르다"며 400을 반환한다 — 그래서 클라이언트가
     * 보낸 값 대신 바이트 시그니처로 직접 판별한다.
     */
    private Base64ImageSource.MediaType detectMediaType(byte[] bytes) {
        if (startsWith(bytes, PNG_SIGNATURE)) {
            return Base64ImageSource.MediaType.IMAGE_PNG;
        }
        if (bytes.length >= 3 && (bytes[0] & 0xFF) == 0x47 && (bytes[1] & 0xFF) == 0x49 && (bytes[2] & 0xFF) == 0x46) {
            return Base64ImageSource.MediaType.IMAGE_GIF;
        }
        if (bytes.length >= 12
                && (bytes[0] & 0xFF) == 0x52 && (bytes[1] & 0xFF) == 0x49 && (bytes[2] & 0xFF) == 0x46 && (bytes[3] & 0xFF) == 0x46
                && (bytes[8] & 0xFF) == 0x57 && (bytes[9] & 0xFF) == 0x45 && (bytes[10] & 0xFF) == 0x42 && (bytes[11] & 0xFF) == 0x50) {
            return Base64ImageSource.MediaType.IMAGE_WEBP;
        }
        // JPEG(0xFFD8)를 포함해 그 외에는 JPEG로 취급한다 — Claude가 지원하는 나머지 포맷 중 가장 흔한 형식.
        return Base64ImageSource.MediaType.IMAGE_JPEG;
    }

    private static final int[] PNG_SIGNATURE = {0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A};

    private boolean startsWith(byte[] bytes, int[] signature) {
        if (bytes.length < signature.length) {
            return false;
        }
        for (int i = 0; i < signature.length; i++) {
            if ((bytes[i] & 0xFF) != signature[i]) {
                return false;
            }
        }
        return true;
    }
}
