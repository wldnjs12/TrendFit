# TrendFit App (Flutter)

`lib/` 폴더에는 화면·모델·서비스 구조만 미리 잡아두었습니다. `ios/`, `android/` 등 플랫폼 폴더는
Flutter SDK가 있어야 생성할 수 있어 저장소에는 포함하지 않았습니다.

## 최초 실행

```bash
cd app
flutter create . --project-name trendfit   # 플랫폼 폴더(ios/android/web 등) 생성
flutter pub get
flutter run
```

## 폴더 구조

- `lib/screens/` — 온보딩 · 옷장 · 추천 화면
- `lib/models/` — 백엔드 엔티티에 대응하는 클라이언트 모델
- `lib/services/` — 백엔드 REST API 호출
- `lib/widgets/` — 스와이프 보정 카드 등 재사용 위젯

자세한 화면별 흐름은 [../docs/PRD.md](../docs/PRD.md)의 "5. 사용자 흐름"을 참고하세요.
