package com.trendfit.domain.closet.repository;

import com.trendfit.domain.closet.entity.ClothingItem;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;

public interface ClothingItemRepository extends JpaRepository<ClothingItem, Long> {
    List<ClothingItem> findAllByUserId(Long userId);
}
