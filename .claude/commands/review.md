---
description: 커밋 전 셀프 리뷰 — git diff HEAD를 심각도 순으로 지적
---

## Context

- 변경 사항 (HEAD 기준): !`git diff HEAD`
- 현재 상태: !`git status`

## Task

위 diff를 CLAUDE.md 및 docs/conventions.md, docs/domain-design.md의 규칙을 기준으로 리뷰한다.
다음 항목을 심각도 순(높음 → 낮음)으로 지적한다:

1. **버그 가능성** — 로직 오류, null/예외 처리 누락, 동시성 문제 등
2. **CLAUDE.md 컨벤션 위반** — 특히 다음 핵심 원칙:
   - 컨텍스트 간 직접 의존(다른 도메인 엔티티/리포지토리 직접 import)
   - 엔티티를 컨트롤러 응답으로 직접 노출
   - 옷장 등록 시점 외 Claude Vision 재호출
   - docs/open-decisions.md에 있는 미결정 정책의 임의 구현
3. **테스트 누락** — 새 로직/분기에 대응하는 테스트가 있는지
4. **시크릿 노출** — API 키, 토큰, 자격증명 등이 코드나 커밋에 포함되는지

문제가 없는 항목은 언급하지 않는다. 발견 사항이 없으면 "지적 사항 없음"이라고만 답한다.
