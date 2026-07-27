# CLAUDE.md

이 문서는 AI 에이전트(Claude Code 등)가 TrendFit 저장소에서 작업할 때 참고하는 가이드다.
프로젝트 배경·문제 정의·경쟁 분석 등 기획 전반은 [docs/PRD.md](docs/PRD.md)를 따로 참고한다.
이 문서는 "어떻게 개발하는가"에 집중한다.

---

## 1. 프로젝트 한 줄 정의

최신 패션 트렌드를 자동 수집해, 사용자가 이미 보유한 옷으로 번역해주는 AI 퍼스널 스타일리스트.
핵심 루프: **트렌드 수집(배치) → 옷장 등록(1회성) → 추천 요청(반복)**.

## 2. 기술 스택

| 영역 | 기술 |
|---|---|
| 백엔드 | Java 17, Spring Boot 3, Spring Data JPA |
| 데이터베이스 | MySQL (Docker) |
| 프론트엔드 | Flutter (모바일 + **Flutter Web**) |
| AI 연동 | Claude API (Vision + Text) |
| 외부 API | 공공 날씨 API |
| 배포 | 프론트: **Vercel** (Flutter Web 정적 빌드) / 백엔드: **Render 또는 Railway** |

> Vercel은 Java 백엔드를 실행할 수 없다. 프론트(Flutter Web 빌드 산출물)만 Vercel에 올리고,
> Spring Boot 백엔드는 별도로 Render/Railway에 배포한다. 두 곳 모두 GitHub 연동 시 push 기반 자동 배포를 지원한다.

## 3. 패키지 구조

- **베이스 패키지:** `com.trendfit`
- 1차 분리는 **바운디드 컨텍스트 기준**: `domain.<context>` + `global`(공통)
- com.trendfit
  ├─ TrendfitApplication
  ├─ domain
  │ ├─ user ← 회원, 취향(스타일) 프로필
  │ ├─ closet ← 옷장 등록, Vision 태깅
  │ ├─ trend ← 트렌드 수집·정제 배치
  │ └─ recommendation ← 추천 요청, 프롬프트 조립, Claude 호출
  └─ global ← 공통(설정/보안/예외/AI·외부 API 클라이언트)

| 컨텍스트 | 패키지 | 책임 |
|---|---|---|
| User | `com.trendfit.domain.user` | 회원 인증/가입, 취향(스타일) 프로필 |
| Closet | `com.trendfit.domain.closet` | 의류 등록, Vision 자동 태깅, 크롭, 스와이프 보정 |
| Trend | `com.trendfit.domain.trend` | 외부 트렌드 원문 수집, 구조화 키워드 정제, 배치 스케줄링 |
| Recommendation | `com.trendfit.domain.recommendation` | 추천 요청 처리, 프롬프트 조립, 결과 로그, '+1 아이템' 구매 연동 |
| 공통 | `com.trendfit.global` | 설정, 보안(OAuth2/JWT), 예외, AI/외부 API 클라이언트 |

세부 규칙(계층 구성, 네이밍, DTO/엔티티 규칙 등)은 [docs/conventions.md](docs/conventions.md) 참고.
컨텍스트 간 의존·엔티티 상세는 [docs/domain-design.md](docs/domain-design.md) 참고.

## 4. UI 구조 (프론트엔드)

**하단 네비게이션은 3탭: 홈 · 옷장 · 프로필.**

- **홈 = 오늘의 코디.** 앱을 켜자마자 날씨+트렌드 기반으로 자동 뜬 오늘의 추천이 바로 보이고,
  그 위나 아래에 "흰 치마인데 뭐랑 매치하지?" 같은 걸 물어볼 수 있는 입력창(앵커 아이템 요청)이
  함께 있는 화면이다. "홈"과 "옷추천"을 별도 탭으로 나누지 않고 하나로 합쳐, 켜자마자 오늘 할 일이
  바로 보이는 습관형 앱 패턴(Duolingo, 캘린더 앱 등)을 따른다. 탭이 적을수록 고민 없이 눌린다.
- **옷장**: 보유 의류 조회·등록(사진 업로드 → Vision 태깅 → 크롭 → 스와이프 보정).
- **프로필**: 취향 태그 설정, 계정 관리.

화면별 상세 흐름은 [docs/architecture.md](docs/architecture.md) "사용자 흐름" 참고.

## 5. 개발 시 지켜야 할 핵심 원칙

1. **컨텍스트 간 직접 의존 금지.** 다른 컨텍스트의 엔티티/리포지토리를 직접 import하지 않는다.
   ID 참조 또는 명시적 인터페이스(포트)로만 경계를 넘는다. (docs/domain-design.md §2)
2. **엔티티를 컨트롤러 응답으로 직접 노출하지 않는다.** 항상 DTO로 변환해 반환한다. (docs/conventions.md §5)
3. **이미지 분석은 옷장 등록 시 1회만.** 이후 모든 반복 상호작용(추천 요청)은 텍스트 프롬프트로만
   처리한다 — Claude Vision 재호출 금지. (비용 최적화 원칙, docs/PRD.md §6.5)
4. **추천 엔진은 벡터 검색(RAG)이 아닌 프롬프트 조립(Context Injection) 방식을 쓴다.** 사용자
   옷장 규모가 MVP 단계에서는 크지 않다는 전제. 이 전제가 깨지면(옷장 수백 벌) docs/open-decisions.md에
   재검토 항목으로 등록 후 논의한다.
5. **미결정 정책은 임의로 구현하지 않는다.** [docs/open-decisions.md](docs/open-decisions.md)에
   있는 항목은 팀(작성자) 결정 후 문서 갱신 → 구현 순서를 따른다.
6. **문서와 코드는 함께 갱신한다.** 정책·설계·스택이 바뀌면 관련 `docs/*.md`도 같은 커밋(또는 바로 다음
   커밋)에서 갱신한다.

## 6. 로컬 실행

```bash
# 백엔드
cd backend
docker compose up -d
export CLAUDE_API_KEY=sk-...
./gradlew bootRun

# 프론트 (모바일 개발 중)
cd app
flutter pub get
flutter run

# 프론트 (웹 배포 빌드)
flutter build web
```

## 7. 문서 지도

| 문서 | 내용 |
|---|---|
| [docs/PRD.md](docs/PRD.md) | 배경, 문제 정의, 경쟁 분석, 6주 로드맵 |
| [docs/architecture.md](docs/architecture.md) | 시스템 아키텍처, 사용자 흐름, 배포 구성 |
| [docs/domain-design.md](docs/domain-design.md) | 바운디드 컨텍스트, 컨텍스트 맵, 핵심 엔티티 |
| [docs/conventions.md](docs/conventions.md) | 패키지/계층 구조, 네이밍, DTO/엔티티 작성 규칙 |
| [docs/service-policy.md](docs/service-policy.md) | 회원/옷장/트렌드/추천/구매연동 정책 |
| [docs/open-decisions.md](docs/open-decisions.md) | 아직 결정되지 않은 항목 — 임의 구현 금지 |