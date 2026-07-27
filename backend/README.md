# TrendFit Backend (Spring Boot)

## 로컬 실행

```bash
docker compose up -d          # MySQL 컨테이너 실행
export CLAUDE_API_KEY=sk-...  # Claude API 키 (커밋 금지)
export WEATHER_API_KEY=...    # 공공 날씨 API 키
./gradlew bootRun
```

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
