import 'package:flutter/material.dart';
import '../config/app_theme.dart';

/// Material 버튼 자체에는 눌렀을 때 축소되는 촉각적 피드백이 없어, 주요 CTA를 감싸서
/// 눌림/뗌에 따라 살짝 scale되는 시각 피드백을 더한다. Listener는 제스처를 소비하지 않으므로
/// 안에 있는 버튼의 onPressed/ripple은 그대로 동작한다.
class PressableScale extends StatefulWidget {
  const PressableScale({super.key, required this.child});

  final Widget child;

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> {
  bool _pressed = false;

  void _setPressed(bool value) {
    if (_pressed != value) setState(() => _pressed = value);
  }

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (_) => _setPressed(true),
      onPointerUp: (_) => _setPressed(false),
      onPointerCancel: (_) => _setPressed(false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: AppMotion.enter,
        child: widget.child,
      ),
    );
  }
}
