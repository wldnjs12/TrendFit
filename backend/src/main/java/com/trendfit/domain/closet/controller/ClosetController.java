package com.trendfit.domain.closet.controller;

import com.trendfit.domain.closet.dto.ClothingItemResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.web.bind.annotation.*;

import java.util.List;

/**
 * 옷장 등록/조회 API. (PRD 6.4 API 설계 개요)
 *
 * TODO(3주차): 이미지 업로드 → Claude Vision 호출 → 크롭 처리까지 이어지는
 * ClosetService 를 구현하고 이 컨트롤러에 연결한다. 현재는 뼈대만 정의되어 있다.
 */
@RestController
@RequestMapping("/api/closet")
@RequiredArgsConstructor
public class ClosetController {

    // private final ClosetService closetService; // TODO: 3주차에 구현

    @PostMapping("/items")
    public void uploadItems(@RequestParam("userId") Long userId /*, @RequestPart List<MultipartFile> images */) {
        // TODO: Claude Vision 호출 -> 카테고리/색상/패턴/크롭 좌표 추출 -> ClothingItem 저장(unconfirmed)
        throw new UnsupportedOperationException("3주차 구현 예정 (PRD 4.2 F2)");
    }

    @PatchMapping("/items/{id}/confirm")
    public void confirmItem(@PathVariable Long id /*, @RequestBody ConfirmRequest request */) {
        // TODO: 스와이프 UI 결과(fit, material)를 ClothingItem.confirmDetails() 에 반영
        throw new UnsupportedOperationException("3주차 구현 예정 (PRD 4.2 F2)");
    }

    @GetMapping("/items")
    public List<ClothingItemResponse> getItems(@RequestParam("userId") Long userId) {
        // TODO: ClothingItemRepository.findAllByUserId(userId) 조회 후 ClothingItemResponse.from()으로 변환
        throw new UnsupportedOperationException("3주차 구현 예정");
    }
}
