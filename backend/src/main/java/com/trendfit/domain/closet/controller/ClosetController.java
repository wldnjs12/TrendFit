package com.trendfit.domain.closet.controller;

import com.trendfit.domain.closet.dto.ClothingItemConfirmRequest;
import com.trendfit.domain.closet.dto.ClothingItemResponse;
import com.trendfit.domain.closet.service.ClosetService;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.util.List;

/**
 * 옷장 등록/조회 API. (PRD 6.4 API 설계 개요, 4.2 F2)
 */
@RestController
@RequestMapping("/api/closet")
@RequiredArgsConstructor
public class ClosetController {

    private final ClosetService closetService;

    @PostMapping("/items")
    public List<ClothingItemResponse> uploadItems(@RequestParam("userId") Long userId,
                                                    @RequestPart("images") List<MultipartFile> images) {
        return closetService.registerItems(userId, images).stream()
                .map(ClothingItemResponse::from)
                .toList();
    }

    @PatchMapping("/items/{id}/confirm")
    public ClothingItemResponse confirmItem(@PathVariable Long id,
                                             @RequestBody ClothingItemConfirmRequest request) {
        return ClothingItemResponse.from(
                closetService.confirmItem(id, request.fit(), request.material()));
    }

    @GetMapping("/items")
    public List<ClothingItemResponse> getItems(@RequestParam("userId") Long userId) {
        return closetService.getItems(userId).stream()
                .map(ClothingItemResponse::from)
                .toList();
    }
}
