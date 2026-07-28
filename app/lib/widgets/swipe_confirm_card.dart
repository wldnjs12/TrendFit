import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// 옷장 등록 시 핏/재질처럼 AI가 확신하지 못하는 속성을
/// 틴더 스타일 스와이프로 1~2초 만에 보정하는 카드. (PRD 4.2 F2)
///
/// 오른쪽 스와이프(또는 확인 버튼) = 제안된 속성 확정
/// 왼쪽 스와이프(또는 거절 버튼) = 다음 후보 속성으로 재질문
class SwipeConfirmCard extends StatefulWidget {
  const SwipeConfirmCard({
    super.key,
    required this.imageUrl,
    required this.question,
    required this.onConfirm,
    required this.onReject,
  });

  final String imageUrl;
  final String question; // 예: "이 옷 오버핏 맞아요?"
  final VoidCallback onConfirm;
  final VoidCallback onReject;

  @override
  State<SwipeConfirmCard> createState() => _SwipeConfirmCardState();
}

class _SwipeConfirmCardState extends State<SwipeConfirmCard> with SingleTickerProviderStateMixin {
  static const _dismissThreshold = 110.0;
  static const _flyOutDistance = 480.0;

  late final AnimationController _controller;
  Animation<Offset>? _flingAnimation;
  Offset _drag = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppMotion.base)
      ..addListener(() {
        if (_flingAnimation != null) setState(() => _drag = _flingAnimation!.value);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onPanStart(DragStartDetails details) {
    _controller.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() => _drag += details.delta);
  }

  void _onPanEnd(DragEndDetails details) {
    if (_drag.dx.abs() > _dismissThreshold) {
      _flyOut(confirm: _drag.dx > 0);
    } else {
      _springBack();
    }
  }

  void _springBack() {
    _flingAnimation = Tween<Offset>(begin: _drag, end: Offset.zero)
        .animate(CurvedAnimation(parent: _controller, curve: AppMotion.spring));
    _controller.forward(from: 0);
  }

  void _flyOut({required bool confirm}) {
    final target = Offset(confirm ? _flyOutDistance : -_flyOutDistance, _drag.dy);
    _flingAnimation = Tween<Offset>(begin: _drag, end: target)
        .animate(CurvedAnimation(parent: _controller, curve: AppMotion.exit));
    _controller.forward(from: 0).then((_) {
      if (confirm) {
        widget.onConfirm();
      } else {
        widget.onReject();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_drag.dx / _dismissThreshold).clamp(-1.0, 1.0);
    final angle = (_drag.dx / 800).clamp(-0.25, 0.25);

    return GestureDetector(
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: _drag,
        child: Transform.rotate(
          angle: angle,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.white, border: Border.all(color: AppColors.borderSubtle)),
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Stack(
                    children: [
                      ClipRect(
                        child: Image.network(widget.imageUrl, height: 280, width: double.infinity, fit: BoxFit.cover),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: AnimatedOpacity(
                          opacity: (-progress).clamp(0.0, 1.0),
                          duration: AppMotion.fast,
                          child: _stampBadge('SKIP', AppColors.danger),
                        ),
                      ),
                      Positioned(
                        top: 12,
                        right: 12,
                        child: AnimatedOpacity(
                          opacity: progress.clamp(0.0, 1.0),
                          duration: AppMotion.fast,
                          child: _stampBadge('CONFIRM', AppColors.black),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(widget.question, style: AppTextStyles.koreanHeadline.copyWith(fontSize: 18)),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      IconButton(
                        onPressed: () => _flyOut(confirm: false),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.chipBackground,
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.close, color: AppColors.textPrimary),
                      ),
                      IconButton(
                        onPressed: () => _flyOut(confirm: true),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.black,
                          shape: const RoundedRectangleBorder(),
                          padding: const EdgeInsets.all(16),
                        ),
                        icon: const Icon(Icons.check, color: AppColors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _stampBadge(String text, Color color) {
    return Transform.rotate(
      angle: -0.15,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: color, width: 2)),
        child: Text(
          text,
          style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 13, letterSpacing: 1),
        ),
      ),
    );
  }
}
