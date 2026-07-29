import 'dart:html' as html;
import 'dart:typed_data';

/// 웹 경로 — 브라우저 다운로드로 PNG 파일을 저장한다. 사용자는 다운로드된 파일을
/// 인스타그램 스토리 앱에서 직접 업로드하면 된다(직접 API 연동이 아니므로 SNS 이용약관과 무관).
Future<void> saveOrShareImage(Uint8List bytes, String filename) async {
  final blob = html.Blob([bytes], 'image/png');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
}
