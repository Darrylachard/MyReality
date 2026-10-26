import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../Avatar/avatar_model.dart';
import '../Avatar/avatar_widget.dart';

class LifeScene extends StatelessWidget {
  final AvatarModel avatar;
  final Set<String> owned;
  final AvatarReaction reaction;
  final int event;
  final String caption;
  final bool customized;
  final VoidCallback? onEdit;
  const LifeScene({
    super.key,
    required this.avatar,
    required this.owned,
    required this.onEdit,
    this.reaction = AvatarReaction.neutral,
    this.event = 0,
    this.caption = 'Small steps. A life taking shape.',
    this.customized = false,
  });
  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 8, 0),
          child: Row(
            children: [
              const Expanded(
                child: Text(
                  'YOUR SPACE',
                  style: TextStyle(
                    fontSize: 11,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: onEdit,
                icon: const Icon(Icons.tune, size: 16),
                label: Text(customized ? 'Edit avatar' : 'Create avatar'),
              ),
            ],
          ),
        ),
        AspectRatio(
          aspectRatio: 1.4,
          child: LayoutBuilder(
            builder: (context, bounds) => Stack(
              children: [
                Positioned.fill(
                  child: Semantics(
                    label:
                        'Your room${owned.contains('plant') ? ', desk plant' : ''}${owned.contains('workspace') ? ', upgraded workspace' : ''}${owned.contains('reward') ? ', final workspace reward' : ''}',
                    image: true,
                    child: CustomPaint(painter: RoomPainter(owned)),
                  ),
                ),
                Positioned(
                  left: bounds.maxWidth * .13,
                  bottom: bounds.maxHeight * .075,
                  child: AvatarWidget(
                    avatar: avatar,
                    size: bounds.maxWidth * .42,
                    animate: true,
                    reaction: reaction,
                    event: event,
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 18),
          child: Text(
            caption,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Original warm-room illustration. Ownership changes the actual furniture.
class RoomPainter extends CustomPainter {
  final Set<String> owned;
  RoomPainter(this.owned);
  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(size.width / 400, size.height / 286);
    const ink = Color(0xff334b46);
    void box(double x, double y, double w, double h, double r, Color c) =>
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(x, y, w, h),
            Radius.circular(r),
          ),
          Paint()..color = c,
        );
    void oval(double x, double y, double w, double h, Color c) =>
        canvas.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = c);
    void line(
      double x,
      double y,
      double xx,
      double yy,
      Color c,
      double width,
    ) => canvas.drawLine(
      Offset(x, y),
      Offset(xx, yy),
      Paint()
        ..color = c
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round,
    );
    void poly(List<Offset> points, Color c) {
      final p = Path()..addPolygon(points, true);
      canvas.drawPath(p, Paint()..color = c);
    }

    canvas.drawRect(
      const Rect.fromLTWH(0, 0, 400, 286),
      Paint()
        ..shader = const LinearGradient(
          colors: [Color(0xffeee2d0), Color(0xffd8c8b4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(const Rect.fromLTWH(0, 0, 400, 286)),
    );
    poly([
      const Offset(0, 205),
      const Offset(400, 205),
      const Offset(400, 286),
      const Offset(0, 286),
    ], const Color(0xffc9ad8b));
    line(0, 205, 400, 205, const Color(0xffbca387), 5);
    for (var i = 0; i < 7; i++) {
      line(i * 80 - 60, 286, i * 60.0, 208, const Color(0xffbda180), 1);
    }
    line(0, 248, 400, 248, const Color(0xffbda180), 1);
    // Window with layered distant city and broad sill.
    box(25, 17, 123, 141, 5, const Color(0xffb6a68e));
    box(30, 21, 113, 131, 2, const Color(0xffd5e4df));
    oval(102, 33, 22, 22, const Color(0xfffaf0c8));
    for (var i = 0; i < 6; i++) {
      box(
        32 + i * 19.0,
        90 + (i % 3) * 10,
        17,
        60 - (i % 3) * 10,
        0,
        const Color(0xffb9cec6),
      );
    }
    line(85, 24, 85, 150, const Color(0xfff9f2e6), 5);
    line(32, 85, 141, 85, const Color(0xfff9f2e6), 4);
    box(20, 151, 133, 8, 3, const Color(0xfff6ecdc));
    poly([
      const Offset(32, 159),
      const Offset(141, 159),
      const Offset(246, 240),
      const Offset(87, 240),
    ], const Color(0x22fff8dc));
    box(13, 13, 14, 139, 4, const Color(0xffc1b298));
    box(146, 13, 14, 139, 4, const Color(0xffc1b298));
    // Framed abstract print, a small shelf, and books.
    box(292, 22, 62, 74, 2, const Color(0xffa47d58));
    box(297, 27, 52, 64, 0, const Color(0xfff7eddc));
    oval(306, 36, 32, 32, const Color(0xffca9b70));
    poly([
      const Offset(301, 83),
      const Offset(318, 53),
      const Offset(345, 83),
    ], const Color(0xff6b8572));
    box(202, 77, 66, 5, 1, const Color(0xffa8825e));
    box(207, 50, 7, 27, 1, const Color(0xffb87656));
    box(216, 54, 9, 23, 1, const Color(0xff637e73));
    box(228, 46, 6, 31, 1, const Color(0xffd0af74));
    // Woven rug grounds character and furniture.
    oval(45, 217, 318, 54, const Color(0xffb7ae91));
    oval(51, 221, 306, 45, const Color(0xffdcd1b4));
    // Workspace silhouette changes with the earned upgrade.
    final upgrade = owned.contains('workspace');
    final desk = upgrade ? const Color(0xff846246) : const Color(0xffae8962);
    oval(230, 224, 134, 20, const Color(0x18332f2b));
    line(231, 163, 227, 233, ink, 5);
    line(367, 163, 373, 233, ink, 5);
    box(219, 153, 161, 12, 3, desk);
    if (upgrade) {
      box(338, 168, 34, 39, 3, const Color(0xff9b7652));
      line(348, 180, 362, 180, const Color(0xffe0c19b), 2);
      line(348, 196, 362, 196, const Color(0xffe0c19b), 2);
      box(278, 175, 43, 39, 9, const Color(0xff52776c));
      box(271, 210, 58, 9, 4, ink);
      line(300, 218, 300, 237, ink, 4);
      line(281, 239, 318, 239, ink, 3);
      line(355, 151, 355, 118, ink, 3);
      line(355, 118, 340, 110, ink, 3);
      poly([
        const Offset(327, 116),
        const Offset(342, 102),
        const Offset(349, 118),
      ], const Color(0xffd9b46b));
    }
    // Starter laptop or earned large display.
    if (owned.contains('reward')) {
      box(257, 99, 69, 45, 4, ink);
      box(261, 103, 61, 35, 1, const Color(0xffa6c5b3));
      line(291, 144, 291, 152, ink, 4);
      box(275, 151, 32, 3, 1, ink);
      box(264, 157, 56, 4, 1, const Color(0xffe5dccb));
    } else {
      poly([
        const Offset(268, 151),
        const Offset(261, 120),
        const Offset(306, 120),
        const Offset(313, 151),
      ], ink);
      poly([
        const Offset(271, 146),
        const Offset(266, 124),
        const Offset(302, 124),
        const Offset(307, 146),
      ], const Color(0xffa6bfb0));
      box(266, 150, 58, 3, 1, const Color(0xff526762));
    }
    box(327, 140, 10, 12, 2, const Color(0xffd5b28a));
    if (owned.contains('plant')) {
      line(243, 143, 242, 116, const Color(0xff456c4c), 2);
      for (var i = 0; i < 3; i++) {
        oval(230, 114 + i * 7.0, 13, 7, const Color(0xff688a59));
        oval(242, 111 + i * 8.0, 13, 7, const Color(0xff4e7650));
      }
      poly([
        const Offset(233, 138),
        const Offset(251, 138),
        const Offset(248, 152),
        const Offset(236, 152),
      ], const Color(0xffb66f50));
    }
  }

  @override
  bool shouldRepaint(covariant RoomPainter oldDelegate) =>
      !setEquals(owned, oldDelegate.owned);
}
