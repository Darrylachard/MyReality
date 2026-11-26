import 'dart:async';
import 'portrait_painter.dart';
import 'package:flutter/material.dart';
import 'avatar_model.dart';

enum AvatarReaction {
  neutral,
  showedUp,
  solidProgress,
  targetMet,
  payday,
  purchase,
}

/// Presentation only: motion never writes progress or grants rewards.
class AvatarWidget extends StatefulWidget {
  static const hairColors = <String, Color>{
    'natural': Color(0xff59361e),
    'black': Color(0xff181b20),
    'copper': Color(0xffb66a42),
    'honey': Color(0xffd5b777),
    'silver': Color(0xffb8c5cd),
  };
  final AvatarModel avatar;
  final double size;
  final bool animate;
  final AvatarReaction reaction;
  final int event;
  const AvatarWidget({
    super.key,
    required this.avatar,
    this.size = 260,
    this.animate = false,
    this.reaction = AvatarReaction.neutral,
    this.event = 0,
  });
  @override
  State<AvatarWidget> createState() => _AvatarWidgetState();
}

class _AvatarWidgetState extends State<AvatarWidget>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController motion = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  );
  Timer? idle;
  bool active = true;
  bool reduced = false;
  bool celebrating = false;
  bool initialized = false;
  bool get canMove => !reduced && active && TickerMode.of(context);
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    reduced = MediaQuery.disableAnimationsOf(context);
    _schedule();
    if (!initialized) {
      initialized = true;
      if (widget.event > 0 &&
          widget.reaction != AvatarReaction.neutral &&
          canMove) {
        celebrating = true;
        motion.forward(from: 0);
      }
    }
  }

  void _schedule() {
    idle?.cancel();
    if (!canMove || !widget.animate) {
      motion.stop();
      return;
    }
    idle = Timer.periodic(const Duration(seconds: 6), (_) {
      celebrating = false;
      motion.forward(from: 0);
    });
  }

  @override
  void didUpdateWidget(AvatarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    _schedule();
    if (widget.event != oldWidget.event &&
        widget.reaction != AvatarReaction.neutral &&
        canMove) {
      celebrating = true;
      motion.forward(from: 0);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    active = state == AppLifecycleState.resumed;
    _schedule();
  }

  @override
  void dispose() {
    idle?.cancel();
    motion.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: 'Your character',
    image: true,
    child: SizedBox(
      width: widget.size,
      height: widget.size * 1.2,
      child: AnimatedBuilder(
        animation: motion,
        builder: (context, _) => CustomPaint(
          painter: PortraitPainter(
            widget.avatar,
            reduced ? 0 : motion.value,
            celebrating ? widget.reaction : AvatarReaction.neutral,
          ),
        ),
      ),
    ),
  );
}
