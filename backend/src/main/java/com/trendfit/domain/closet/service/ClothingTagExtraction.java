package com.trendfit.domain.closet.service;

/**
 * Claude Vision 정제 결과 한 건. index 는 요청에 첨부한 이미지 순번과 일치한다.
 * ClothingItem.Category 이름과 일치하는 문자열을 기대하지만, 파싱 실패 시
 * ClosetService 가 해당 이미지를 건너뛴다.
 */
public record ClothingTagExtraction(
        int index,
        String category,
        String color,
        String pattern,
        CropBox cropBox
) {
}
