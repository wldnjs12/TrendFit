package com.trendfit.domain.closet.dto;

import com.trendfit.domain.closet.entity.ClothingItem;

import java.time.LocalDateTime;

/**
 * 옷장 조회 응답 DTO. 엔티티(ClothingItem)를 컨트롤러 밖으로 직접 노출하지 않기 위해 사용한다.
 */
public record ClothingItemResponse(
        Long id,
        ClothingItem.Category category,
        String color,
        String pattern,
        ClothingItem.Fit fit,
        String material,
        String imagePath,
        String croppedImagePath,
        ClothingItem.Source source,
        boolean confirmed,
        LocalDateTime createdAt
) {

    public static ClothingItemResponse from(ClothingItem item) {
        return new ClothingItemResponse(
                item.getId(),
                item.getCategory(),
                item.getColor(),
                item.getPattern(),
                item.getFit(),
                item.getMaterial(),
                item.getImagePath(),
                item.getCroppedImagePath(),
                item.getSource(),
                item.isConfirmed(),
                item.getCreatedAt()
        );
    }
}
