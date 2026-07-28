import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../config/app_config.dart';
import '../models/clothing_item.dart';
import '../services/api_service.dart';
import 'closet_confirm_screen.dart';

/// 옷장 등록/조회 화면 (PRD 4.2 F2, architecture.md §3 "2. 옷장 등록")
/// - 사진 여러 장 업로드 -> Vision 자동 태깅 + 크롭
/// - 애매한 속성(핏/재질)은 ClosetConfirmScreen에서 보정
class ClosetScreen extends StatefulWidget {
  const ClosetScreen({super.key});

  @override
  State<ClosetScreen> createState() => _ClosetScreenState();
}

class _ClosetScreenState extends State<ClosetScreen> {
  final ApiService _apiService = ApiService(baseUrl: AppConfig.apiBaseUrl);
  final ImagePicker _picker = ImagePicker();

  late Future<List<ClothingItem>> _itemsFuture;

  @override
  void initState() {
    super.initState();
    _itemsFuture = _apiService.fetchClosetItems(AppConfig.currentUserId);
  }

  void _reload() {
    setState(() {
      _itemsFuture = _apiService.fetchClosetItems(AppConfig.currentUserId);
    });
  }

  Future<void> _pickAndUpload() async {
    final List<XFile> images = await _picker.pickMultiImage();
    if (images.isEmpty) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final uploaded = await _apiService.uploadClosetItems(AppConfig.currentUserId, images);
      if (!mounted) return;
      Navigator.of(context).pop(); // 로딩 다이얼로그 닫기

      if (uploaded.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('옷을 인식하지 못했어요. 다른 사진으로 다시 시도해주세요.')),
        );
        return;
      }

      final confirmedAll = await Navigator.of(context).push<bool>(
        MaterialPageRoute(builder: (_) => ClosetConfirmScreen(items: uploaded)),
      );
      if (confirmedAll == true) {
        _reload();
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('내 옷장')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _pickAndUpload,
        icon: const Icon(Icons.add_a_photo_outlined),
        label: const Text('사진으로 옷 등록'),
      ),
      body: FutureBuilder<List<ClothingItem>>(
        future: _itemsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('옷장을 불러오지 못했어요.\n${snapshot.error}', textAlign: TextAlign.center));
          }

          final items = snapshot.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('옷장이 비어있어요. 사진을 올려보세요.'));
          }

          return GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.75,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              final imagePath = item.croppedImagePath ?? item.imagePath;
              return ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(_apiService.imageUrl(imagePath), fit: BoxFit.cover),
                    if (!item.confirmed)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text('보정 필요', style: TextStyle(color: Colors.white, fontSize: 10)),
                        ),
                      ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
