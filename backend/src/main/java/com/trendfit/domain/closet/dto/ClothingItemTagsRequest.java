package com.trendfit.domain.closet.dto;

import java.util.List;

/**
 * 옷장 아이템에 자유 텍스트 해시태그를 저장할 때 보내는 요청.
 */
public record ClothingItemTagsRequest(
        List<String> tags
) {
}
