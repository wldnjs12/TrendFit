# 코딩 컨벤션 & 규칙 (Conventions)

패키지 구조, 계층 구성, 컨텍스트 간 의존, 인증/권한, DTO/엔티티 규칙을 정의한다.

---

## 1. 패키지 구조

- **베이스 패키지:** `com.trendfit`
- 1차 분리는 **바운디드 컨텍스트 기준**: `domain.<context>` + `global`(공통).
  com.trendfit
  ├─ TrendfitApplication
  ├─ domain
  │ ├─ user
  │ ├─ closet
  │ ├─ trend
  │ └─ recommendation
  └─ global ← 공통(설정/보안/예외/AI·외부 API 클라이언트)
  | 컨텍스트 | 패키지 |
  |---|---|
  | User | `com.trendfit.domain.user` |
  | Closet | `com.trendfit.domain.closet` |
  | Trend | `com.trendfit.domain.trend` |
  | Recommendation | `com.trendfit.domain.recommendation` |
  | 공통 | `com.trendfit.global` |

---

## 2. 계층 구성 (컨텍스트 내부)

각 컨텍스트 내부는 **계층형**으로 구성한다.

| 계층 | 패키지 | 책임 |
|---|---|---|
| Controller | `controller` | HTTP 요청/응답, 입력 검증, DTO 입출력 |
| Service | `service` | 비즈니스 로직, 트랜잭션 경계, 프롬프트 조립(Recommendation) |
| Repository | `repository` | 영속성(Spring Data JPA) |
| Entity | `entity` | JPA 엔티티(도메인 모델) |
| DTO | `dto` | 요청/응답 객체 |

com.trendfit.domain.closet
├─ controller
│ └─ ClosetController
├─ service
│ └─ ClosetService
├─ repository
│ └─ ClothingItemRepository
├─ entity
│ └─ ClothingItem
└─ dto
├─ ClothingItemRegisterRequest
└─ ClothingItemResponse
> 이 구조는 지금부터 채택하는 컨벤션이다. 최초 스캐폴드(초기 커밋)가 이 구조와 다르면,
> 실제 기능 구현을 시작하기 전에 이 컨벤션에 맞춰 먼저 정리한다.

---

## 3. 컨텍스트 간 의존 규칙

- 컨텍스트 간 **직접 의존을 지양**한다. (다른 컨텍스트의 엔티티/리포지토리를 직접 import 하지 않는다.)
- 경계를 넘는 참조는 다음 중 하나로만 한다:
    - **ID 기반 참조** — 다른 컨텍스트의 식별자(`Long userId` 등)만 보관.
    - **명시적 인터페이스(포트)** — 제공 측이 노출한 포트를 통해 질의/호출.
- 모든 컨텍스트는 `global`(공통)에만 의존할 수 있다.
- 컨텍스트 맵은 [domain-design.md](domain-design.md) 참조.

---

## 4. 인증 / 권한

- 인증은 **Google OAuth2 로그인** + **JWT 기반** API 인증(액세스 토큰 발급 + 리프레시 재발급)을 채택한다.
    - 자체 비밀번호 로그인은 도입하지 않는다(해싱/재설정 플로우 비용 대비 이점이 낮다고 판단).
- 권한은 `enum Role { USER, ADMIN }` 으로 표현한다.
    - 각 값은 Spring Security 키를 보유: `USER → ROLE_USER`, `ADMIN → ROLE_ADMIN`.
- 관리자/보호 기능(예: 트렌드 배치 수동 트리거)은 **`@PreAuthorize`**로 통제한다.

---

## 5. DTO / 엔티티 규칙

- **DTO와 엔티티를 분리**한다.
- **엔티티를 컨트롤러 응답으로 직접 노출하지 않는다.** 항상 DTO로 변환하여 반환한다.
- 요청 바디도 엔티티가 아닌 요청 DTO로 받는다.

---

## 6. 엔티티 작성 규칙

- 기본 생성자는 **`protected`** (`@NoArgsConstructor(access = PROTECTED)`).
- 생성은 **정적 팩토리 메서드** 또는 **일반 생성자**를 사용하고, 필드가 많아지면 빌더(`private`)로 전환한다.
- `@Getter`만 노출하고 무분별한 `@Setter`는 지양한다. 상태 변경은 의도가 드러나는 메서드로 한다
  (예: `ClothingItem.confirmDetails(fit, material)`).
- enum 매핑은 **`@Enumerated(EnumType.STRING)`**.
- 테이블명은 명시한다(예: `@Table(name = "clothing_items")`).
- `createdAt`은 `@PrePersist`에서 채운다.

---

## 7. 네이밍 규칙

| 대상 | 규칙 | 예 |
|---|---|---|
| 패키지 | 소문자, 컨텍스트 단수형 | `closet`, `trend` |
| 클래스 | PascalCase | `RecommendationLog`, `ClosetController` |
| 엔티티 | 도메인 명사 | `User`, `ClothingItem`, `TrendKeyword` |
| 컨트롤러 | `*Controller` | `ClosetController` |
| 서비스 | `*Service` | `RecommendationService` |
| 리포지토리 | `*Repository` | `ClothingItemRepository` |
| DTO | 용도 접미사 | `*Request`, `*Response` |
| 포트(인터페이스) | `*Port` | `ClosetQueryPort`, `ClosetCommandPort` |

---

## 8. 문서/코드 동기화

- 정책·설계·스택이 바뀌면 **코드와 함께 관련 `docs/` 문서를 갱신**한다.
- 미결정 항목([open-decisions.md](open-decisions.md))은 **임의로 구현하지 않는다.** 확정 시
  문서에 먼저 반영 후 구현한다.