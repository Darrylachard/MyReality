import 'package:flutter/material.dart';

class PremiumAvatarMotion extends StatefulWidget {
  final Widget child;

  const PremiumAvatarMotion({super.key, required this.child});

  @override
  State<PremiumAvatarMotion> createState() => _PremiumAvatarMotionState();
}

class _PremiumAvatarMotionState extends State<PremiumAvatarMotion>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (_, child) {
        final t = _controller.value;
        return Transform.translate(
          offset: Offset(0, -2 * t),
          child: Transform.scale(
            scaleY: 1.0 + (0.015 * t),
            scaleX: 1.0,
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
