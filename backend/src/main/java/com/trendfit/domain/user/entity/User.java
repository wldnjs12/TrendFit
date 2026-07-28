package com.trendfit.domain.user.entity;

import jakarta.persistence.*;
import lombok.AccessLevel;
import lombok.Getter;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

/**
 * 회원 기본 정보.
 * PRD 6.3 데이터 모델 - User 참고.
 */
@Entity
@Table(name = "users", uniqueConstraints = @UniqueConstraint(columnNames = {"auth_provider", "oauth_id"}))
@Getter
@NoArgsConstructor(access = AccessLevel.PROTECTED)
public class User {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @Column(nullable = false, unique = true)
    private String email;

    @Column(nullable = false)
    private String nickname;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private AuthProvider authProvider;

    @Column(nullable = false)
    private String oauthId;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private Role role;

    /** 발급된 리프레시 토큰(원문). 로그아웃 시 null로 비운다. (conventions.md §4) */
    @Column(length = 512)
    private String refreshToken;

    @Column(nullable = false, updatable = false)
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() {
        this.createdAt = LocalDateTime.now();
    }

    public User(String email, String nickname, AuthProvider authProvider, String oauthId) {
        this.email = email;
        this.nickname = nickname;
        this.authProvider = authProvider;
        this.oauthId = oauthId;
        this.role = Role.USER;
    }

    /** 로그인 시마다 최신 리프레시 토큰으로 교체한다. 로그아웃 시 null을 전달해 무효화한다. */
    public void updateRefreshToken(String refreshToken) {
        this.refreshToken = refreshToken;
    }

    public enum AuthProvider { GOOGLE }

    /** 권한. (conventions.md §4 — USER/ADMIN, Spring Security 키는 ROLE_ 접두사) */
    public enum Role {
        USER, ADMIN;

        public String key() {
            return "ROLE_" + name();
        }
    }
}
