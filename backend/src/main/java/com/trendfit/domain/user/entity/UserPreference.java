package com.trendfit.domain.user.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

/**
 * 온보딩 단계에서 생성되는 사용자 취향 프로필.
 * styleTags 는 콤마로 구분된 태그 문자열로 단순화(MVP). 예: "미니멀,뉴트럴톤"
 * 추천 엔진 프롬프트 조립 시 이 값이 취향 컨텍스트로 주입된다. (PRD 4.2 F3 참고)
 */
@Entity
@Table(name = "user_preferences")
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class UserPreference {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false, unique = true)
    private User user;

    @Column(length = 500)
    private String styleTags;

    @Column(length = 500)
    private String bodyInfo; // 선택 입력, MVP에서는 참고용으로만 저장

    public UserPreference(User user, String styleTags, String bodyInfo) {
        this.user = user;
        this.styleTags = styleTags;
        this.bodyInfo = bodyInfo;
    }
}
