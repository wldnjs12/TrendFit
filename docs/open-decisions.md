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
| A1 | **트렌드 수집 소스 최종 목록** | ✅ 결정됨: 보그 코리아·W코리아·하입비스트 코리아 RSS 3종 (2026-07-27) | 실제 수집기(파서) 구현 대상이 정해져야 2주차 배치 개발이 가능함 | Trend |
| A2 | **옷장 최소 등록 벌 수 기준** | ✅ 결정됨: 3벌 이상 + 상의/원피스 1개 이상 & 하의 1개 이상 (2026-07-27) | 추천 기능을 "활성화" 상태로 볼 최소 옷장 규모가 정해져야 온보딩 UX(빈 옷장 안내 문구, 추천 버튼 활성화 조건)를 구현 가능 | Closet, Recommendation |
| A3 | **날씨 API 종류** | ✅ 결정됨: 기상청 단기예보조회(`getVilageFcst`, 공공데이터포털) (2026-07-27) | 연동 방식·요청 파라미터(격자좌표 변환 등)가 API마다 다름 | Recommendation |
| A4 | **이미지 저장소** | ✅ 결정됨: 로컬 개발은 `LocalFileImageStorage`, 배포 전 클라우드(Cloudflare R2 등)로 교체 — `ImageStorage` 인터페이스로 추상화 (2026-07-27) | 배포 환경(Render/Railway)의 파일시스템은 재배포 시 초기화될 수 있어, 스토리지 전환 시점 결정 필요 | Closet, 인프라 |
| A5 | **추천 요청 빈도 제한** | ✅ 결정됨: 하루 10회/사용자 소프트캡 (2026-07-27) | 무료/프리미엄 정책과 직결. Claude API 비용 통제에도 영향 | Recommendation |
| A6 | **구매 연동 제휴처** | 미정 | '+1 아이템' 쇼핑 링크가 실제로 어디를 가리킬지, 제휴 프로그램 가입 필요 여부 | Recommendation |
| A7 | **온보딩 스타일 태그 목록** | ✅ 결정됨: 미니멀·캐주얼·스트릿·러블리·페미닌·시크·빈티지·스포티·클래식·프레피·유니크·오피스룩 12개 (2026-07-27) | 실제 UI 선택지와 추천 프롬프트에 쓰일 태그 어휘집이 확정돼야 함 | User |

---

## B. 엔지니어링 결정 필요

| # | 항목 | 현재 옵션 | 결정이 필요한 이유 | 영향받는 컨텍스트 |
|---|---|---|---|---|
| B1 | **백엔드 배포처** | Render vs Railway vs Fly.io | 무료 티어 한도, MySQL 제공 여부, 콜드스타트 특성이 달라 최종 1곳 확정 필요 | 인프라 |
| B2 | **기존 스캐폴드와의 정합성** | ✅ 결정됨: closet/user/trend/recommendation 4개 컨텍스트를 conventions.md §2의 controller/service/repository/entity/dto 서브패키지 구조로 정리 (2026-07-27) | 실제 구현 착수 전 스캐폴드를 conventions.md §2 구조로 정리해야 함 | 전체 |
| B3 | **User 엔티티 인증 필드 보강** | ✅ 결정됨: `User`에 `authProvider`(enum, 현재 GOOGLE만) / `oauthId` 필드 추가, (authProvider, oauthId) 유니크 제약 추가 (2026-07-27) | conventions.md §4(Google OAuth2 채택)에 맞춰 필드 추가 필요 | User |
| B4 | **Recommendation의 포트 인터페이스 구체 설계** | ✅ 결정됨: 각 컨텍스트 자기 패키지 `domain.<context>.port`에 위치, 소유 Service가 직접 구현 (UserPreferencePort/ClosetQueryPort/TrendQueryPort/ClosetCommandPort, 시그니처는 domain-design.md §2 참고) (2026-07-27) | 4주차 추천 엔진 구현 착수 전 확정 필요 | Recommendation, Closet, Trend, User |

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
- **B3. User 엔티티 인증 필드 보강** — ✅ 결정됨: `authProvider`(enum, GOOGLE) / `oauthId` 필드와
  유니크 제약 추가 (2026-07-27)
- **A7. 온보딩 스타일 태그 목록** — ✅ 결정됨: 미니멀·캐주얼·스트릿·러블리·페미닌·시크·빈티지·스포티·
  클래식·프레피·유니크·오피스룩 12개 (2026-07-27)
- **A1. 트렌드 수집 소스 최종 목록** — ✅ 결정됨: 보그 코리아·W코리아·하입비스트 코리아 RSS 3종
  (2026-07-27)
- **A2. 옷장 최소 등록 벌 수 기준** — ✅ 결정됨: 3벌 이상 + 상의(TOP)/원피스(DRESS) 1개 이상 &
  하의(BOTTOM) 1개 이상 (2026-07-27)
- **A4. 이미지 저장소** — ✅ 결정됨: `ImageStorage` 인터페이스로 추상화, 로컬 개발은
  `LocalFileImageStorage`, 배포 전 Cloudflare R2 등 클라우드 구현체로 교체 (2026-07-27)
- **B4. Recommendation의 포트 인터페이스 구체 설계** — ✅ 결정됨: `domain.<context>.port`에
  위치, 소유 Service가 직접 구현 (2026-07-27)
- **A3. 날씨 API 종류** — ✅ 결정됨: 기상청 단기예보조회(`getVilageFcst`) (2026-07-27)
- **A5. 추천 요청 빈도 제한** — ✅ 결정됨: 하루 10회/사용자 소프트캡 (2026-07-27)