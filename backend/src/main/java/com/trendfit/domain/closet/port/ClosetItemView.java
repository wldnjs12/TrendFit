package com.trendfit.domain.closet.port;

/**
 * Recommendation이 프롬프트 조립·ID-이미지 매핑에 쓰는 옷장 아이템 조회 결과.
 * (domain-design.md §2, B4 결정)
 */
public record ClosetItemView(
        Long id,
        String category,
        String color,
        String pattern,
        String fit,
        String material,
        String croppedImagePath
) {

    /** 추천 프롬프트에 주입할 텍스트 직렬화. 예: "[ID:101] TOP/화이트/무지/REGULAR/코튼" */
    public String toPromptTag() {
        return String.format("[ID:%d] %s/%s/%s/%s/%s", id, category, color, pattern, fit, material);
    }
}
