package com.trendfit.domain.closet.service;

import com.trendfit.domain.closet.entity.ClothingItem;
import com.trendfit.domain.closet.port.AutoPurchaseItemCommand;
import com.trendfit.domain.closet.port.ClosetCommandPort;
import com.trendfit.domain.closet.port.ClosetItemView;
import com.trendfit.domain.closet.port.ClosetQueryPort;
import com.trendfit.domain.closet.repository.ClothingItemRepository;
import com.trendfit.global.storage.ImageStorage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.io.UncheckedIOException;
import java.util.ArrayList;
import java.util.List;

/**
 * 옷장 등록/조회/보정. (PRD 4.2 F2)
 * Claude Vision 호출은 등록 시 1회뿐이며, 스와이프 보정(confirm)은 텍스트 값만 다룬다.
 * ClosetQueryPort/ClosetCommandPort를 구현해 Recommendation에 조회·쓰기를 제공한다
 * (domain-design.md §2, B4 결정).
 */
@Slf4j
@Service
@RequiredArgsConstructor
public class ClosetService implements ClosetQueryPort, ClosetCommandPort {

    private final ImageStorage imageStorage;
    private final ClaudeVisionTagger visionTagger;
    private final ClothingItemRepository clothingItemRepository;

    @Transactional
    public List<ClothingItem> registerItems(Long userId, List<MultipartFile> images) {
        List<ClothingTagExtraction> extractions = visionTagger.tagAll(images);

        List<ClothingItem> saved = new ArrayList<>();
        for (ClothingTagExtraction extraction : extractions) {
            if (extraction.index() < 0 || extraction.index() >= images.size()) {
                continue;
            }

            ClothingItem.Category category = parseCategory(extraction.category());
            if (category == null || isBlank(extraction.color())) {
                log.warn("[ClosetService] 카테고리/색상 인식 실패로 이미지 {} 스킵 (category={}, color={})",
                        extraction.index(), extraction.category(), extraction.color());
                continue;
            }

            MultipartFile image = images.get(extraction.index());
            byte[] original = readBytes(image);
            String imagePath = imageStorage.save(original, image.getOriginalFilename());

            byte[] cropped = ImageCropper.crop(original, extraction.cropBox());
            String croppedImagePath = imageStorage.save(cropped, "cropped-" + image.getOriginalFilename());

            ClothingItem item = new ClothingItem(userId, category, extraction.color(), extraction.pattern(),
                    imagePath, croppedImagePath, ClothingItem.Source.DIRECT_UPLOAD);
            saved.add(clothingItemRepository.save(item));
        }
        return saved;
    }

    @Transactional
    public ClothingItem confirmItem(Long id, ClothingItem.Fit fit, String material) {
        ClothingItem item = clothingItemRepository.findById(id)
                .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 옷장 아이템: " + id));
        item.confirmDetails(fit, material);
        return item;
    }

    @Transactional(readOnly = true)
    public List<ClothingItem> getItems(Long userId) {
        return clothingItemRepository.findAllByUserId(userId);
    }

    @Override
    @Transactional(readOnly = true)
    public List<ClosetItemView> findAllByUserId(Long userId) {
        return clothingItemRepository.findAllByUserId(userId).stream()
                .map(item -> new ClosetItemView(
                        item.getId(),
                        item.getCategory().name(),
                        item.getColor(),
                        item.getPattern(),
                        item.getFit() == null ? null : item.getFit().name(),
                        item.getMaterial(),
                        item.getCroppedImagePath()))
                .toList();
    }

    @Override
    @Transactional
    public Long registerAutoPurchasedItem(AutoPurchaseItemCommand command) {
        ClothingItem.Category category = parseCategory(command.category());
        if (category == null) {
            throw new IllegalArgumentException("알 수 없는 카테고리: " + command.category());
        }

        ClothingItem item = new ClothingItem(command.userId(), category, command.color(), command.pattern(),
                command.imagePath(), null, ClothingItem.Source.AUTO_PURCHASE);
        return clothingItemRepository.save(item).getId();
    }

    private ClothingItem.Category parseCategory(String raw) {
        if (raw == null) {
            return null;
        }
        try {
            return ClothingItem.Category.valueOf(raw.trim().toUpperCase());
        } catch (IllegalArgumentException e) {
            return null;
        }
    }

    private boolean isBlank(String value) {
        return value == null || value.isBlank();
    }

    private byte[] readBytes(MultipartFile file) {
        try {
            return file.getBytes();
        } catch (IOException e) {
            throw new UncheckedIOException(e);
        }
    }
}
