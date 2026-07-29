/// 합성한 위클리 리포트 PNG 바이트를 사용자 기기에 저장(또는 공유)한다.
/// 웹은 브라우저 다운로드로, 그 외 플랫폼은 OS 공유 시트(share_plus)로 처리한다 —
/// 실제 구현은 dart.library.html 여부에 따라 컴파일 타임에 갈린다.
library;

export 'image_saver_stub.dart' if (dart.library.html) 'image_saver_web.dart';
