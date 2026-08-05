package com.trendfit.domain.closet.dto;

import com.trendfit.domain.closet.entity.ClothingItem;
import com.trendfit.global.storage.ImageUrls;

import java.time.LocalDateTime;
import java.util.List;

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
        List<String> tags,
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
                ImageUrls.toUrl(item.getImagePath()),
                ImageUrls.toUrl(item.getCroppedImagePath()),
                item.getTags(),
                item.getSource(),
                item.isConfirmed(),
                item.getCreatedAt()
        );
    }
}
