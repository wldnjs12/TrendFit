package com.trendfit.domain.closet.dto;

import com.trendfit.domain.closet.entity.ClothingItem;

/**
 * 스와이프 UI에서 핏/재질을 확정할 때 보내는 요청. (PRD 4.2 F2)
 */
public record ClothingItemConfirmRequest(
        ClothingItem.Fit fit,
        String material
) {
}
