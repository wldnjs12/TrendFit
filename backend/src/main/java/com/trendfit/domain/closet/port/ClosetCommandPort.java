package com.trendfit.domain.closet.port;

/**
 * Recommendation이 '+1 아이템' 구매 확정 시 Closet에 쓰기(등록)를 요청하는 포트.
 * Closet 컨텍스트가 소유·구현한다 (domain-design.md §2).
 */
public interface ClosetCommandPort {

    /** @return 생성된 ClothingItem의 ID */
    Long registerAutoPurchasedItem(AutoPurchaseItemCommand command);
}
