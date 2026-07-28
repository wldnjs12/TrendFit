# 도메인 설계 (Domain Design)

바운디드 컨텍스트의 경계, 컨텍스트별 책임, 핵심 엔티티를 정의한다. 정책의 "무엇"은
[service-policy.md](service-policy.md)에, 여기서는 "어떻게 나누고 무엇을 소유하는가"를 다룬다.

---

## 1. 바운디드 컨텍스트 개요

| 컨텍스트 | 패키지(`com.trendfit.domain.*`) | 한 줄 책임 |
|---|---|---|
| **User** | `user` | 회원 인증/가입, 취향(스타일) 프로필 관리 |
| **Closet** | `closet` | 의류 등록·조회, Vision 자동 태깅, 크롭, 스와이프 보정 |
| **Trend** | `trend` | 외부 트렌드 원문 수집, 구조화 키워드 정제, 배치 스케줄링 |
| **Recommendation** | `recommendation` | 추천 요청 처리, 프롬프트 조립, Claude 호출, 결과 로그, '+1 아이템' 구매 연동 |
| (공통) | `global` *(domain 아님)* | 공통 설정·보안·예외·AI/외부 API 클라이언트 |

## 2. 컨텍스트 맵 / 의존 규칙

- 컨텍스트 간 **직접 의존(엔티티/리포지토리 직접 참조)을 지양**한다.
- 경계를 넘는 참조는 **ID 기반**(예: `userId: Long` 보관) 또는 **명시적 인터페이스**(포트)를 통한다.
- 모든 컨텍스트는 `global`(공통)에만 의존할 수 있다.
- **Recommendation은 다른 세 컨텍스트의 데이터를 모두 읽어야 하는 유일한 "조립자" 컨텍스트다.**
  User/Closet/Trend 각각이 노출하는 조회용 포트 인터페이스(예: `ClosetQueryPort`, `TrendQueryPort`,
  `UserPreferencePort`)를 통해서만 데이터를 읽는다. 각 컨텍스트의 Repository를 직접 주입받지 않는다.
  ┌──────────────────────────────────────────┐
  │                  global                   │  ← 공통(설정/보안/AI 클라이언트)
  └──────────────────────────────────────────┘
  ▲          ▲          ▲          ▲
  ┌──┴──┐    ┌──┴────┐  ┌──┴─────┐  ┌──┴────────────┐
  │User │    │Closet │  │Trend   │  │Recommendation │
  └─────┘    └───────┘  └────────┘  └───────────────┘
  ▲            ▲          ▲              │
  └────────────┴──────────┴──── (Query Port 경유) ─┘
  대표적인 컨텍스트 간 관계(모두 **ID/인터페이스** 경유, 직접 참조 아님):

| 출발 | 도착 | 관계 | 경유 방식 |
|---|---|---|---|
| Recommendation | User | 취향 프로필 조회 | `UserPreferencePort` |
| Recommendation | Closet | 옷장 전체(ID+태그) 조회 | `ClosetQueryPort` |
| Recommendation | Trend | 최신 트렌드 키워드 조회 | `TrendQueryPort` |
| Recommendation | Closet | '+1 아이템' 구매 확정 시 자동 등록(쓰기) | `ClosetCommandPort` |

> ✅ 결정됨(B4, 2026-07-27): 포트 인터페이스는 **각 컨텍스트 자기 패키지 하위 `domain.<context>.port`**에
> 둔다(별도 contracts 패키지 대신). 소유 컨텍스트의 Service가 포트를 직접 `implements` 한다
> (별도 어댑터 클래스 없이). 확정된 시그니처:
>
> | 포트 | 위치 | 메서드 | 구현체 |
> |---|---|---|---|
> | `UserPreferencePort` | `domain.user.port` | `Optional<UserPreferenceView> findPreference(Long userId)` | `UserService` |
> | `ClosetQueryPort` | `domain.closet.port` | `List<ClosetItemView> findAllByUserId(Long userId)` | `ClosetService` |
> | `TrendQueryPort` | `domain.trend.port` | `List<TrendKeywordView> findLatestKeywords()` | `TrendQueryService` |
> | `ClosetCommandPort` | `domain.closet.port` | `Long registerAutoPurchasedItem(AutoPurchaseItemCommand command)` | `ClosetService` |
>
> `ClosetItemView`는 `toPromptTag()`를 제공해 `"[ID:%d] 카테고리/색상/패턴/핏/재질"` 형태로
> 직렬화한다(ClothingItem.toPromptTag()와 동일 포맷). `ClosetCommandPort`는 4주차 추천 엔진
> 자체에는 쓰이지 않고, 6주차 '+1 아이템' 구매 콜백 연동 시점에 실제로 호출된다.

## 3. 컨텍스트별 책임 & 핵심 엔티티

각 컨텍스트의 "핵심 엔티티"는 설계 기준이며, 필드는 정책 확정 후 구체화한다. 🔸 표시는
[open-decisions.md](open-decisions.md)에 묶인 미결정 사항이다.

### 3.1 User — 회원 / 취향

**책임:** 로그인/가입(인증 방식은 §4 참고), 온보딩 시 취향(스타일) 프로필 생성·조회.

| 엔티티 | 책임 | 핵심 속성(설계 기준) |
|---|---|---|
| `User` | 서비스 사용자 | id, email, nickname, authProvider(GOOGLE), oauthId, role(USER/ADMIN), refreshToken, createdAt |
| `UserPreference` | 온보딩에서 생성되는 취향 프로필 | id, userId, styleTags(콤마 구분 또는 다대다), 🔸 bodyInfo(선택) |

### 3.2 Closet — 옷장

**책임:** 의류 사진 등록, Vision 자동 태깅, 크롭 처리, 스와이프 보정, 조회.

| 엔티티 | 책임 | 핵심 속성(설계 기준) |
|---|---|---|
| `ClothingItem` | 옷장의 핵심 엔티티 | id, userId, category, color, pattern, fit, material, imagePath, croppedImagePath, source(직접등록/자동등록), confirmed, createdAt |

- 추천 엔진은 이 엔티티들을 `"[ID] 카테고리/색상/핏/재질"` 형태의 텍스트로 직렬화해 프롬프트에 주입한다.
  이미지 자체는 프롬프트에 포함하지 않는다(비용 최적화).
- 이미지 저장소는 `ImageStorage` 인터페이스로 추상화한다: 로컬 개발은 `LocalFileImageStorage`,
  배포 전 클라우드 구현체(Cloudflare R2 등)로 교체한다(service-policy.md §2, 2026-07-27 결정).

### 3.3 Trend — 트렌드 수집

**책임:** 공개 패션 매체 원문 수집(매일 배치), Claude를 통한 구조화 키워드 정제·저장.

| 엔티티 | 책임 | 핵심 속성(설계 기준) |
|---|---|---|
| `TrendKeyword` | 배치가 매일 적재하는 트렌드 데이터 | id, collectedDate, colorTag, itemTag, moodTag, sourceUrl |

- 🔸 최종 수집 소스 목록(구체적으로 몇 개/어느 매체) 미정 → [open-decisions.md](open-decisions.md)

### 3.4 Recommendation — 추천 엔진

**책임:** 자연어 추천 요청 처리(일반 요청/앵커 아이템 요청), 프롬프트 조립, Claude 호출, 결과 로그,
'+1 아이템' 구매 콜백 처리.

| 엔티티 | 책임 | 핵심 속성(설계 기준) |
|---|---|---|
| `RecommendationLog` | 추천 요청/결과 이력 | id, userId, requestText, resultItemIdsJson, plusOneItemJson, createdAt |

- 🔸 하루 추천 요청 횟수 제한 여부 미정 → [open-decisions.md](open-decisions.md)

---

## 4. 설계 원칙 요약

1. 컨텍스트는 **자기 데이터만 소유**한다(엔티티는 한 컨텍스트에만 속한다).
2. 다른 컨텍스트 데이터가 필요하면 **ID로 참조**하거나 **인터페이스(포트)로 질의**한다.
3. 엔티티는 외부(컨트롤러 응답)로 직접 노출하지 않고 **DTO로 변환**한다([conventions.md](conventions.md)).
4. 위 엔티티 속성은 **설계 기준**이며, 🔸 미결정 항목이 확정되면 구체화한다.