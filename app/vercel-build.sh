#!/usr/bin/env bash
# Vercel 빌드 환경에는 Flutter SDK가 없어서, 빌드 시점에 stable 채널을 얕게 clone해 설치한 뒤
# 웹 빌드를 수행한다. API_BASE_URL은 Vercel 프로젝트의 환경변수(Settings > Environment Variables)로
# 설정해두면 --dart-define으로 그대로 주입된다(app/lib/config/app_config.dart 참고).
set -euo pipefail

if [ ! -d "_flutter" ]; then
  git clone https://github.com/flutter/flutter.git --depth 1 -b stable _flutter
fi
export PATH="$PATH:$(pwd)/_flutter/bin"

flutter --version
flutter pub get
flutter build web --release --dart-define=API_BASE_URL="${API_BASE_URL:-http://localhost:8080}"
