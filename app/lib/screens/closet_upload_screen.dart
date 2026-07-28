import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../config/app_session.dart';
import '../config/app_theme.dart';
import '../services/api_service.dart';
import '../widgets/trendfit_top_bar.dart';

/// 옷장 사진 등록. (Figma "옷장 사진 등록")
/// 사진을 골라 미리보기에 모은 뒤 COMPLETE를 누르면 일괄 업로드하고,
/// Vision 태깅만 끝난 미확정 아이템 목록을 반환한다 — 핏/재질 보정은 다음 화면(ClosetConfirmScreen) 몫이다.
class ClosetUploadScreen extends StatefulWidget {
  const ClosetUploadScreen({super.key});

  @override
  State<ClosetUploadScreen> createState() => _ClosetUploadScreenState();
}

class _ClosetUploadScreenState extends State<ClosetUploadScreen> {
  static const _recommendedMinimum = 5;

  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final ImagePicker _picker = ImagePicker();
  final List<XFile> _picked = [];
  bool _uploading = false;

  Future<void> _pickMore() async {
    final images = await _picker.pickMultiImage();
    if (images.isEmpty) return;
    setState(() => _picked.addAll(images));
  }

  Future<void> _complete() async {
    if (_picked.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('먼저 옷 사진을 선택해주세요.')),
      );
      return;
    }

    setState(() => _uploading = true);
    try {
      final uploaded = await _apiService.uploadClosetItems(AppSession.userId!, _picked);
      if (!mounted) return;
      if (uploaded.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('옷을 인식하지 못했어요. 다른 사진으로 다시 시도해주세요.')),
        );
        return;
      }
      Navigator.of(context).pop(uploaded);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_picked.length / _recommendedMinimum).clamp(0.0, 1.0);
    return Scaffold(
      appBar: TrendFitTopBar(onBack: () => Navigator.of(context).pop()),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: Row(
            children: [
              Expanded(child: Text('UPLOAD PROGRESS', style: AppTextStyles.trackedLabel)),
              Text('${(progress * 100).round()}%', style: AppTextStyles.trackedLabel.copyWith(color: AppColors.textPrimary)),
            ],
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('STEP 01', style: AppTextStyles.trackedLabelBig),
              const SizedBox(height: 8),
              Text('나의 클로젯 사진 등록', style: AppTextStyles.displayHeavy.copyWith(fontSize: 24)),
              const SizedBox(height: 8),
              Text(
                '정확한 스타일 분석을 위해 최소 $_recommendedMinimum장의 옷 사진을 등록해주세요.',
                style: AppTextStyles.body,
              ),
              const SizedBox(height: 24),
              InkWell(
                onTap: _pickMore,
                child: DecoratedBox(
                  decoration: BoxDecoration(border: Border.all(color: AppColors.borderLight)),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.textTertiary),
                        SizedBox(height: 12),
                        Text('UPLOAD PHOTOS', style: TextStyle(fontWeight: FontWeight.w600, letterSpacing: 1)),
                        SizedBox(height: 4),
                        Text('Drag & Drop or Click', style: TextStyle(color: AppColors.textTertiary, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _uploading ? null : _complete,
                  child: _uploading
                      ? const SizedBox(
                          height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
                      : const Text('COMPLETE'),
                ),
              ),
              if (_picked.isNotEmpty) ...[
                const SizedBox(height: 24),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 8,
                    mainAxisSpacing: 8,
                    childAspectRatio: 1,
                  ),
                  itemCount: _picked.length,
                  itemBuilder: (context, index) {
                    final file = _picked[index];
                    return ClipRect(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          kIsWeb
                              ? Image.network(file.path, fit: BoxFit.cover)
                              : Image.file(File(file.path), fit: BoxFit.cover),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () => setState(() => _picked.removeAt(index)),
                              child: const CircleAvatar(
                                radius: 12,
                                backgroundColor: Colors.black54,
                                child: Icon(Icons.close, size: 14, color: AppColors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
