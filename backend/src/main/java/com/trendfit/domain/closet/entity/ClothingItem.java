package com.trendfit.domain.closet.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;

/**
 * 옷장의 핵심 엔티티. (PRD 6.3, 4.2 F2 참고)
 *
 * - category/color/pattern 은 Claude Vision 1차 분석으로 채워진다.
 * - fit/material 은 신뢰도가 낮아 스와이프 UI로 사용자가 보정(confirm)한다.
 * - 추천 엔진(F3)은 이 엔티티들을 "[ID] 카테고리/색상/핏/재질" 형태의 텍스트로 직렬화해
 *   프롬프트에 주입한다. 이미지 자체는 프롬프트에 포함되지 않는다(비용 최적화, PRD 6.5).
 */
@Entity
@Table(name = "clothing_items", indexes = @Index(name = "idx_clothing_items_user_id", columnList = "user_id"))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class ClothingItem {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(name = "user_id", nullable = false)
    private Long userId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Category category;

    @Column(nullable = false)
    private String color;

    private String pattern;

    @Enumerated(EnumType.STRING)
    private Fit fit;

    private String material;

    @Column(nullable = false)
    private String imagePath;

    private String croppedImagePath;

    /** 사용자가 자유롭게 붙이는 해시태그 메모(예: "데이트", "여름"). 추천 프롬프트에
     * 착용 목적/시기 힌트로 그대로 실린다(toPromptTag 참고). */
    @ElementCollection(fetch = FetchType.EAGER)
    @CollectionTable(name = "clothing_item_tags", joinColumns = @JoinColumn(name = "clothing_item_id"))
    @Column(name = "tag")
    private List<String> tags = new ArrayList<>();

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Source source; // DIRECT_UPLOAD(직접 등록) / AUTO_PURCHASE(‘+1 아이템’ 구매 자동 등록)

    /** 스와이프 보정이 아직 끝나지 않은 애매한 속성이 있는지 여부 (fit/material 등) */
    @Column(nullable = false)
    private boolean confirmed;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public ClothingItem(Long userId, Category category, String color, String pattern,
                         String imagePath, String croppedImagePath, Source source) {
        this.userId = userId;
        this.category = category;
        this.color = color;
        this.pattern = pattern;
        this.imagePath = imagePath;
        this.croppedImagePath = croppedImagePath;
        this.source = source;
        this.confirmed = false;
    }

    /** 스와이프 UI에서 핏/재질을 확정할 때 호출 (PRD 4.2 F2) */
    public void confirmDetails(Fit fit, String material) {
        this.fit = fit;
        this.material = material;
        this.confirmed = true;
    }

    /** 옷장 화면에서 아이템에 자유 텍스트 해시태그를 달거나 뗄 때 호출한다. */
    public void updateTags(List<String> tags) {
        this.tags = new ArrayList<>(tags);
    }

    /** 추천 엔진 프롬프트에 주입할 텍스트 직렬화. 예: "[ID:101] 상의/화이트/셔츠/레귤러핏/코튼 #데이트" */
    public String toPromptTag() {
        String base = String.format("[ID:%d] %s/%s/%s/%s/%s",
                id, category, color, pattern, fit, material);
        return tags.isEmpty() ? base : base + " " + String.join(" ", tags.stream().map(t -> "#" + t).toList());
    }

    public enum Category { TOP, BOTTOM, OUTER, DRESS, SHOES, ACCESSORY }

    public enum Fit { SLIM, REGULAR, OVERSIZED, UNKNOWN }

    public enum Source { DIRECT_UPLOAD, AUTO_PURCHASE }
}
