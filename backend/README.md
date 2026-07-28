# TrendFit Backend (Spring Boot)

## 로컬 실행

```bash
docker compose up -d           # MySQL 컨테이너 실행
cp .env.example .env           # 최초 1회 — 값 채우기 (커밋 금지, spring-dotenv가 자동 로드)
./gradlew bootRun
```

환경변수는 매번 `export` 할 필요 없이 `backend/.env`에 넣어두면 `spring-dotenv`가 부팅 시
자동으로 읽는다. 채워야 하는 값은 `.env.example` 참고 (DB 계정, `TRENDFIT_ID`/`TRENDFIT_PASSWORD`
— Google OAuth 클라이언트 ID/JWT 서명키, `CLAUDE_API_KEY`, `WEATHER_API_KEY`).

`gradlew` 래퍼가 없다면 IntelliJ로 프로젝트를 열거나, 로컬 Gradle이 있다면 `gradle wrapper`로 생성하세요.

## 패키지 구조

```
com.trendfit
├── domain
│   ├── user            # User, UserPreference — 회원/취향 온보딩
│   ├── closet           # ClothingItem — 옷장 등록, Vision 태깅
│   ├── trend             # TrendKeyword, TrendCollectionScheduler — 트렌드 배치
│   └── recommendation    # RecommendationLog, RecommendationController — 추천 엔진
└── global.config         # ClaudeProperties 등 공통 설정
```

## 구현 상태

이 저장소의 백엔드 코드는 **아키텍처 뼈대**입니다. 엔티티/레포지토리는 정의되어 있으나,
Vision 연동, 프롬프트 조립, 트렌드 수집 로직 등 서비스 레이어는 `TODO` 주석으로 표시된
개발 로드맵(`../docs/PRD.md` 10번 항목)에 따라 순차적으로 구현됩니다.

| 주차 | 구현 대상 |
|---|---|
| 2주차 | `TrendCollectionScheduler` 내부 로직 |
| 3주차 | `ClosetController` / `ClosetService` (Vision 연동) |
| 4주차 | `RecommendationController` / `RecommendationService` (추천 엔진) |
