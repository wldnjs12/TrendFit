# 미결정 항목 (Open Decisions)

아직 **결정되지 않은 항목**을 모은다.
**여기 있는 항목은 임의로 값을 정하지 않는다.** 관련 기능을 구현하기 전에 결정하고,
확정되면 본 문서와 관련 문서를 갱신한다.

- A. 서비스/정책 미결정 항목 — 기획 단계에서 보류된 항목
- B. 엔지니어링 결정 필요 — 구현 착수 전 확정해야 하는 기술적 선택

---

## A. 서비스 / 정책 미결정 항목

| # | 항목 | 현재 옵션 | 결정이 필요한 이유 | 영향받는 컨텍스트 |
|---|---|---|---|---|
| A1 | **트렌드 수집 소스 최종 목록** | 예시로 "무신사 매거진, 29CM, 패션 매체 RSS" 언급된 상태, 구체 목록 미확정 | 실제 수집기(파서) 구현 대상이 정해져야 2주차 배치 개발이 가능함 | Trend |
| A2 | **옷장 최소 등록 벌 수 기준** | 미정 (예: 3벌? 5벌?) | 추천 기능을 "활성화" 상태로 볼 최소 옷장 규모가 정해져야 온보딩 UX(빈 옷장 안내 문구, 추천 버튼 활성화 조건)를 구현 가능 | Closet, Recommendation |
| A3 | **날씨 API 종류** | "공공 날씨 API"로만 명시, 구체 API(기상청 단기예보 등) 미정 | 연동 방식·요청 파라미터(격자좌표 변환 등)가 API마다 다름 | Recommendation |
| A4 | **이미지 저장소** | 로컬 파일시스템(MVP 가정) vs 클라우드 스토리지 | 배포 환경(Render/Railway)의 파일시스템은 재배포 시 초기화될 수 있어, 스토리지 전환 시점 결정 필요 | Closet, 인프라 |
| A5 | **추천 요청 빈도 제한** | 미정 | 무료/프리미엄 정책과 직결. Claude API 비용 통제에도 영향 | Recommendation |
| A6 | **구매 연동 제휴처** | 미정 | '+1 아이템' 쇼핑 링크가 실제로 어디를 가리킬지, 제휴 프로그램 가입 필요 여부 | Recommendation |
| A7 | **온보딩 스타일 태그 목록** | 미정 (예: 미니멀/스트릿/러블리 등 예시만 존재) | 실제 UI 선택지와 추천 프롬프트에 쓰일 태그 어휘집이 확정돼야 함 | User |

---

## B. 엔지니어링 결정 필요

| # | 항목 | 현재 옵션 | 결정이 필요한 이유 | 영향받는 컨텍스트 |
|---|---|---|---|---|
| B1 | **백엔드 배포처** | Render vs Railway vs Fly.io | 무료 티어 한도, MySQL 제공 여부, 콜드스타트 특성이 달라 최종 1곳 확정 필요 | 인프라 |
| B2 | **기존 스캐폴드와의 정합성** | ✅ 결정됨: closet/user/trend/recommendation 4개 컨텍스트를 conventions.md §2의 controller/service/repository/entity/dto 서브패키지 구조로 정리 (2026-07-27) | 실제 구현 착수 전 스캐폴드를 conventions.md §2 구조로 정리해야 함 | 전체 |
| B3 | **User 엔티티 인증 필드 보강** | 최초 스캐폴드의 `User`는 email/nickname만 보유, OAuth 관련 필드(`authProvider`, `oauthId`) 없음 | conventions.md §4(Google OAuth2 채택)에 맞춰 필드 추가 필요 | User |
| B4 | **Recommendation의 포트 인터페이스 구체 설계** | `ClosetQueryPort` 등 포트 명칭·위치는 예시로만 제시, 실제 메서드 시그니처 미정 | 4주차 추천 엔진 구현 착수 전 확정 필요 | Recommendation, Closet, Trend, User |

> B 섹션은 코드 변경을 수반하므로, 각 항목을 해결하며 이 문서의 해당 행을 "✅ 결정됨"으로 갱신한다.

---

## 결정 기록 방법

항목이 확정되면:
1. 본 문서에서 해당 행을 **"✅ 결정됨: <내용> (YYYY-MM-DD)"** 로 갱신.
2. 영향받는 문서([service-policy.md](service-policy.md) / [domain-design.md](domain-design.md) /
   [architecture.md](architecture.md) / [conventions.md](conventions.md))를 함께 수정.
3. 그 다음에 구현을 진행한다.

## 결정 완료

- **B2. 기존 스캐폴드와의 정합성** — ✅ 결정됨: closet/user/trend/recommendation 4개 컨텍스트를
  conventions.md §2의 controller/service/repository/entity/dto 서브패키지 구조로 정리 (2026-07-27)