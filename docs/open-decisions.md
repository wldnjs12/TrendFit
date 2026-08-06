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
| A4 | **이미지 저장소** | ✅ 결정됨: 로컬 개발은 `LocalFileImageStorage`, 배포는 `R2ImageStorage`(Cloudflare R2) — `ImageStorage` 인터페이스로 추상화, `trendfit.storage.provider`(local/r2)로 전환 (2026-07-27 결정, 2026-07-29 R2 구현 완료) | 배포 환경(Railway)의 파일시스템은 재배포 시 초기화될 수 있어, 스토리지 전환 시점 결정 필요 | Closet, 인프라 |
| A5 | **추천 요청 빈도 제한** | ✅ 결정됨: 하루 10회/사용자 소프트캡 (2026-07-27) | 무료/프리미엄 정책과 직결. Claude API 비용 통제에도 영향 | Recommendation |
| A6 | **구매 연동 제휴처** | ✅ 결정됨(보류): 실시간 상품 검색 연동을 당분간 하지 않는다 (2026-08-06). 네이버쇼핑 검색 API(2026-07-29 채택 → 2026-07-31 대체 API 없이 종료) 다음으로 11번가 오픈API `ProductSearch`(2026-08-05)를 시도했으나, 신청해보니 판매자(셀러) 계정에만 공개되는 API라 일반 개발자 신청으로는 접근 불가함을 확인. `global.shopping.ElevenStShoppingClient` 구현은 코드에 남겨두되(키 없으면 조용히 no-op — 이후 셀러 계정 확보나 다른 API로 활성화 가능하도록), 지금은 '+1 아이템'을 상품 카드(이미지/가격/구매링크) 없이 아이템명/이유 텍스트만 보여주는 상태로 유지한다. 대체 제휴처는 필요해지면 다시 논의 | Recommendation |
| A7 | **온보딩 스타일 태그 목록** | ✅ 결정됨: 미니멀·캐주얼·스트릿·러블리·페미닌·시크·빈티지·스포티·클래식·프레피·유니크·오피스룩 12개 (2026-07-27) | 실제 UI 선택지와 추천 프롬프트에 쓰일 태그 어휘집이 확정돼야 함 | User |

---

## B. 엔지니어링 결정 필요

| # | 항목 | 현재 옵션 | 결정이 필요한 이유 | 영향받는 컨텍스트 |
|---|---|---|---|---|
| B1 | **백엔드 배포처** | ✅ 결정됨: Railway (2026-07-29) — 같은 프로젝트에서 MySQL 플러그인을 바로 붙일 수 있어 별도 DB 호스팅이 필요 없음 | 무료 티어 한도, MySQL 제공 여부, 콜드스타트 특성이 달라 최종 1곳 확정 필요 | 인프라 |
| B2 | **기존 스캐폴드와의 정합성** | ✅ 결정됨: closet/user/trend/recommendation 4개 컨텍스트를 conventions.md §2의 controller/service/repository/entity/dto 서브패키지 구조로 정리 (2026-07-27) | 실제 구현 착수 전 스캐폴드를 conventions.md §2 구조로 정리해야 함 | 전체 |
| B3 | **User 엔티티 인증 필드 보강** | ✅ 결정됨: `User`에 `authProvider`(enum, 현재 GOOGLE만) / `oauthId` 필드 추가, (authProvider, oauthId) 유니크 제약 추가. Google OAuth2 로그인 + JWT 세션 구현(2026-07-28)에 맞춰 `role`(enum USER/ADMIN) / `refreshToken` 필드도 추가 | conventions.md §4(Google OAuth2 채택)에 맞춰 필드 추가 필요 | User |
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

- **B1. 백엔드 배포처** — ✅ 결정됨: Railway (2026-07-29). backend/Dockerfile로 빌드,
  MySQL은 Railway 플러그인 사용. 프론트는 Vercel(app/vercel.json, app/vercel-build.sh로
  빌드 시점에 Flutter SDK 설치 후 `flutter build web`).
- **B2. 기존 스캐폴드와의 정합성** — ✅ 결정됨: closet/user/trend/recommendation 4개 컨텍스트를
  conventions.md §2의 controller/service/repository/entity/dto 서브패키지 구조로 정리 (2026-07-27)
- **B3. User 엔티티 인증 필드 보강** — ✅ 결정됨: `authProvider`(enum, GOOGLE) / `oauthId` 필드와
  유니크 제약 추가 (2026-07-27). Google OAuth2 로그인 + JWT 세션 구현과 함께 `role`(USER/ADMIN),
  `refreshToken` 필드 추가 (2026-07-28)
- **A7. 온보딩 스타일 태그 목록** — ✅ 결정됨: 미니멀·캐주얼·스트릿·러블리·페미닌·시크·빈티지·스포티·
  클래식·프레피·유니크·오피스룩 12개 (2026-07-27)
- **A1. 트렌드 수집 소스 최종 목록** — ✅ 결정됨: 보그 코리아·W코리아·하입비스트 코리아 RSS 3종
  (2026-07-27)
- **A2. 옷장 최소 등록 벌 수 기준** — ✅ 결정됨: 3벌 이상 + 상의(TOP)/원피스(DRESS) 1개 이상 &
  하의(BOTTOM) 1개 이상 (2026-07-27)
- **A4. 이미지 저장소** — ✅ 결정됨: `ImageStorage` 인터페이스로 추상화, 로컬 개발은
  `LocalFileImageStorage`(2026-07-27). 배포용 `R2ImageStorage`(Cloudflare R2, S3 호환 API)
  구현 완료, `trendfit.storage.provider=r2` + `.env`의 `R2_*` 값으로 전환 (2026-07-29)
- **B4. Recommendation의 포트 인터페이스 구체 설계** — ✅ 결정됨: `domain.<context>.port`에
  위치, 소유 Service가 직접 구현 (2026-07-27)
- **A3. 날씨 API 종류** — ✅ 결정됨: 기상청 단기예보조회(`getVilageFcst`) (2026-07-27)
- **A5. 추천 요청 빈도 제한** — ✅ 결정됨: 하루 10회/사용자 소프트캡 (2026-07-27)
- **A6. 구매 연동 제휴처** — ✅ 보류로 최종 결정(2026-08-06). 2026-07-29에 네이버쇼핑
  검색 API(`global.shopping.NaverShoppingClient`)로 결정하고 구현까지 완료했으나(쿠팡
  파트너스·무신사 대비 무료·즉시 발급이 채택 이유였음), 네이버가 2026-07-31부로 해당
  API(쇼핑·책·전문자료 검색)를 대체 API 없이 완전 종료했다(NAVER API HUB 이관 대상에서도
  제외됨 — 네이버 개발자센터 공지 확인). 이후 11번가 오픈API `ProductSearch`로 재선정해
  `global.shopping.ElevenStShoppingClient`로 교체 구현(2026-08-05, 인증은 client-id/secret
  쌍에서 키 1개로 단순화, 응답 포맷 JSON→XML이라 `jackson-dataformat-xml` 추가)했으나, 실제
  신청해보니 **판매자(셀러) 계정에만 공개되는 API**로 확인되어 일반 개발자로는 발급받을 수
  없었다(2026-08-06). 클라이언트 코드는 남겨두되(키 없으면 no-op) 지금은 '+1 아이템'을
  상품 카드 없이 텍스트(아이템명/이유)로만 노출하는 상태를 그대로 유지하기로 결정. 대체
  제휴처는 필요해지면 다시 논의.