import 'dart:typed_data';
import 'package:share_plus/share_plus.dart';

/// 모바일(iOS/Android) 경로 — OS 공유 시트를 띄워 사용자가 인스타그램 스토리 등으로 바로 보내거나
/// 저장할 수 있게 한다.
Future<void> saveOrShareImage(Uint8List bytes, String filename) async {
  final file = XFile.fromData(bytes, name: filename, mimeType: 'image/png');
  await SharePlus.instance.share(ShareParams(files: [file], text: 'TrendFit 위클리 리포트'));
}
