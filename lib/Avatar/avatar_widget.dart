import 'dart:async';
import 'dart:math' as math;
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
  }

  void _schedule() {
    idle?.cancel();
    if (reduced || !active || !widget.animate || !TickerMode.of(context)) {
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
        !reduced &&
        active) {
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
          painter: _CharacterPainter(
            widget.avatar,
            reduced ? 0 : motion.value,
            celebrating ? widget.reaction : AvatarReaction.neutral,
          ),
        ),
      ),
    ),
  );
}

/// Original vector artwork in a fixed 200 x 240 coordinate space.
class _CharacterPainter extends CustomPainter {
  final AvatarModel avatar;
  final double time;
  final AvatarReaction reaction;
  _CharacterPainter(this.avatar, this.time, this.reaction);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 200, size.height / 240);
    final skin =
        const {
          'light': Color(0xffeac0a2),
          'tan': Color(0xffce9776),
          'brown': Color(0xff9c6448),
          'dark': Color(0xff694333),
        }[avatar.skinTone] ??
        const Color(0xffce9776);
    final shade = Color.lerp(skin, const Color(0xff422c2b), .2)!;
    final hair =
        AvatarWidget.hairColors[avatar.hairColor] ??
        AvatarWidget.hairColors['natural']!;
    final wave = math.sin(time * math.pi);
    final strong =
        reaction == AvatarReaction.targetMet ||
        reaction == AvatarReaction.payday;
    final joyful = reaction != AvatarReaction.neutral;
    final lift = joyful ? wave * (strong ? 7 : 2) : wave * 1.2;
    void oval(double x, double y, double w, double h, Color c) =>
        canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = c);
    void box(double x, double y, double w, double h, double r, Color c) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(r),
          ),
          Paint()..color = c,
        );
    void stroke(List<Offset> points, Color c, double width) {
      final path = Path()..moveTo(points.first.dx, points.first.dy);
      for (final p in points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = c
          ..strokeWidth = width
          ..strokeCap = StrokeCap.round
          ..strokeJoin = StrokeJoin.round
          ..style = PaintingStyle.stroke,
      );
    }

    oval(53, 222, 96, 12, const Color(0x223b332d));
    canvas.save();
    canvas.translate(0, -lift);
    // Tapered trousers and two separately articulated feet.
    stroke(
      [const Offset(85, 143), const Offset(82, 181), const Offset(78, 216)],
      const Color(0xff354554),
      22,
    );
    stroke(
      [const Offset(111, 143), const Offset(115, 181), const Offset(120, 216)],
      const Color(0xff2c3a49),
      22,
    );
    stroke(
      [const Offset(89, 166), const Offset(87, 199)],
      const Color(0xff4a5964),
      2,
    );
    box(62, 214, 29, 15, 6, const Color(0xfff5eee1));
    box(109, 214, 30, 15, 6, const Color(0xfff5eee1));
    stroke(
      [const Offset(64, 226), const Offset(90, 226)],
      const Color(0xffb5b0a5),
      3,
    );
    stroke(
      [const Offset(110, 226), const Offset(137, 226)],
      const Color(0xffb5b0a5),
      3,
    );
    // Relaxed sweatshirt, with a narrower shoulder option.
    final inset = avatar.bodyType == 'F' ? 4.0 : 0.0;
    final sleeve = const Color(0xff638877);
    stroke(
      [
        Offset(73 + inset, 88),
        const Offset(64, 110),
        Offset(61, 139 - wave * 3),
      ],
      sleeve,
      19,
    );
    oval(54, 135 - wave * 3, 14, 18, skin);
    final handY = strong
        ? 133 - wave * 64
        : joyful
        ? 139 - wave * 20
        : 139.0;
    stroke(
      [
        Offset(125 - inset, 88),
        Offset(137, 111 - wave * (strong ? 16 : 0)),
        Offset(140, handY),
      ],
      sleeve,
      19,
    );
    oval(134, handY - 5, 14, 18, skin);
    final torso = Path()
      ..moveTo(74 + inset, 81)
      ..quadraticBezierTo(99, 74, 125 - inset, 81)
      ..lineTo(130, 149)
      ..quadraticBezierTo(100, 159, 69, 149)
      ..close();
    canvas.drawPath(torso, Paint()..color = const Color(0xff779b86));
    box(70, 142, 59, 10, 4, const Color(0xff5f806d));
    final pocket = Path()
      ..moveTo(85, 119)
      ..lineTo(113, 119)
      ..lineTo(119, 137)
      ..lineTo(80, 137)
      ..close();
    canvas.drawPath(pocket, Paint()..color = const Color(0xff6c8e7b));
    stroke(
      [const Offset(83, 122), const Offset(79, 132)],
      const Color(0xff557764),
      1.5,
    );
    stroke(
      [const Offset(114, 122), const Offset(119, 132)],
      const Color(0xff557764),
      1.5,
    );
    box(91, 67, 18, 20, 6, shade);
    final hood = Path()
      ..moveTo(79, 80)
      ..quadraticBezierTo(100, 101, 121, 80);
    canvas.drawPath(
      hood,
      Paint()
        ..color = const Color(0xff4f7361)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5,
    );
    stroke(
      [const Offset(90, 89), const Offset(89, 106)],
      const Color(0xffe7e0cd),
      1.8,
    );
    stroke(
      [const Offset(109, 89), const Offset(110, 105)],
      const Color(0xffe7e0cd),
      1.8,
    );
    // Face: adult proportions, ears, nose, eyebrows and brief blink.
    oval(72, 45, 12, 18, shade);
    oval(117, 45, 12, 18, shade);
    final face = Path()
      ..moveTo(78, 36)
      ..cubicTo(77, 12, 122, 12, 123, 37)
      ..lineTo(120, 62)
      ..quadraticBezierTo(117, 77, 100, 79)
      ..quadraticBezierTo(82, 75, 79, 62)
      ..close();
    canvas.drawPath(face, Paint()..color = skin);
    stroke(
      [const Offset(100, 49), const Offset(98, 59), const Offset(102, 60)],
      shade,
      1.4,
    );
    final blink = time > .43 && time < .51;
    for (final x in [89.0, 111.0]) {
      if (blink) {
        stroke(
          [Offset(x - 2, 50), Offset(x + 2, 50)],
          const Color(0xff302c2c),
          1.5,
        );
      } else {
        oval(x - 1.6, 47.5, 3.2, 4.4, const Color(0xff302c2c));
      }
      stroke([Offset(x - 4, 43), Offset(x + 3, 42)], hair, 2);
    }
    final mouth = Path()
      ..moveTo(94, 66)
      ..quadraticBezierTo(100, joyful ? 72 : 69, 107, 65.5);
    canvas.drawPath(
      mouth,
      Paint()
        ..color = const Color(0xff754b42)
        ..strokeWidth = 1.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke,
    );
    if (avatar.hairStyle != 'no_hair') {
      final cap = Path()
        ..moveTo(76, 46)
        ..cubicTo(66, 5, 123, 3, 126, 32)
        ..lineTo(122, 47)
        ..lineTo(116, 30)
        ..quadraticBezierTo(96, 39, 81, 32)
        ..close();
      canvas.drawPath(cap, Paint()..color = hair);
      for (var i = 0; i < 8; i++) {
        final x = 77 + i * 6.0;
        final lock = Path()
          ..moveTo(x, 24)
          ..quadraticBezierTo(x - 7, 32, x - 3, 39 + (i % 3) * 4);
        canvas.drawPath(
          lock,
          Paint()
            ..color = Color.lerp(hair, Colors.white, i.isEven ? .07 : 0)!
            ..style = PaintingStyle.stroke
            ..strokeCap = StrokeCap.round
            ..strokeWidth = 6,
        );
      }
    }
    if (joyful && time > 0 && time < 1) {
      final c = const Color(0xffc39443).withValues(alpha: wave);
      for (final p in [
        const Offset(53, 48),
        const Offset(145, 37),
        const Offset(151, 74),
      ]) {
        stroke([p.translate(-3, 0), p.translate(3, 0)], c, 1.7);
        stroke([p.translate(0, -3), p.translate(0, 3)], c, 1.7);
      }
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _CharacterPainter oldDelegate) => true;
}
