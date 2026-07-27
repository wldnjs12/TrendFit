---
description: git status·diff를 읽어 Conventional Commits 형식으로 커밋 생성
allowed-tools: Bash(git:*)
---

## Context

- 현재 상태: !`git status`
- 스테이징된 변경: !`git diff --cached`
- 스테이징 안 된 변경: !`git diff`
- 최근 커밋 스타일 참고: !`git log --oneline -10`

## Task

위 컨텍스트를 바탕으로 변경 사항을 분석하고, Conventional Commits 형식
(`feat:`, `fix:`, `docs:`, `refactor:`, `chore:`, `test:` 등)에 맞는
커밋 메시지를 작성한다.

1. 아직 스테이징되지 않은 관련 파일이 있으면 `git add`로 스테이징한다.
   (시크릿·환경 파일 등은 제외)
2. 변경의 "왜"에 집중한 1~2문장짜리 커밋 메시지를 작성한다.
3. `git commit`으로 커밋을 생성한다.
4. 커밋 후 `git status`로 결과를 확인한다.

사용자가 명시적으로 요청하지 않는 한 `--no-verify`, `--amend`, force push 등은 사용하지 않는다.
