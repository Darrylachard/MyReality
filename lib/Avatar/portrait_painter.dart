import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'avatar_model.dart';
import 'avatar_widget.dart';

/// Layered original fashion illustration. Coordinates use a 200 x 240 artboard.
class PortraitPainter extends CustomPainter {
  final AvatarModel avatar;
  final double time;
  final AvatarReaction reaction;
  PortraitPainter(this.avatar, this.time, this.reaction);
  static const clothes = <String, Color>{
    'sage': Color(0xff779c94),
    'navy': Color(0xff3f567b),
    'clay': Color(0xffb87d69),
    'cream': Color(0xffddd5c4),
  };
  @override
  void paint(Canvas c, Size size) {
    c.scale(size.width / 200, size.height / 240);
    final skin =
        const {
          'light': Color(0xffedc3a5),
          'tan': Color(0xffc8916b),
          'brown': Color(0xff9b654b),
          'dark': Color(0xff633f32),
        }[avatar.skinTone] ??
        const Color(0xffc8916b);
    final shadow = Color.lerp(skin, const Color(0xff321d22), .26)!;
    final light = Color.lerp(skin, const Color(0xffffe8d7), .18)!;
    final hair =
        AvatarWidget.hairColors[avatar.hairColor] ??
        AvatarWidget.hairColors['natural']!;
    final cloth = clothes[avatar.outfitColor] ?? clothes['sage']!;
    final seam = Color.lerp(cloth, const Color(0xff111e32), .28)!;
    const ink = Color(0xff253044);
    void oval(double x, double y, double w, double h, Color color) =>
        c.drawOval(Rect.fromLTWH(x, y, w, h), Paint()..color = color);
    void fill(Path p, Color color, {Color? highlight}) => c.drawPath(
      p,
      Paint()
        ..shader = LinearGradient(
          colors: [highlight ?? color, color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ).createShader(p.getBounds()),
    );
    void line(Path p, Color color, double width) => c.drawPath(
      p,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    Path curve(
      double x,
      double y,
      double a,
      double b,
      double d,
      double e,
      double f,
      double g,
    ) => Path()
      ..moveTo(x, y)
      ..cubicTo(a, b, d, e, f, g);
    oval(59, 228, 85, 7, const Color(0x33000000));
    c.save();
    final wave = math.sin(time * math.pi);
    c.translate(0, -wave * (reaction == AvatarReaction.neutral ? .7 : 2));
    // Tailored tapered trousers, seams, and low-profile sneakers.
    fill(
      Path()
        ..moveTo(78, 137)
        ..lineTo(123, 137)
        ..lineTo(129, 219)
        ..lineTo(111, 219)
        ..lineTo(100, 165)
        ..lineTo(89, 219)
        ..lineTo(72, 219)
        ..close(),
      ink,
      highlight: const Color(0xff45556c),
    );
    line(
      curve(100, 147, 100, 162, 98, 172, 95, 184),
      const Color(0xff1c2637),
      1.2,
    );
    for (final x in [73.0, 112.0]) {
      fill(
        Path()
          ..moveTo(x, 215)
          ..lineTo(x + 15, 215)
          ..quadraticBezierTo(x + 17, 221, x + 23, 223)
          ..lineTo(x + 24, 228)
          ..lineTo(x - 4, 228)
          ..quadraticBezierTo(x - 5, 222, x, 215)
          ..close(),
        const Color(0xffd6d9d7),
        highlight: const Color(0xfff3eee5),
      );
      line(
        Path()
          ..moveTo(x - 2, 227)
          ..lineTo(x + 22, 227),
        const Color(0xff83909e),
        1,
      );
      line(
        Path()
          ..moveTo(x + 5, 219)
          ..lineTo(x + 13, 220),
        const Color(0xff778390),
        1,
      );
    }
    final narrow = avatar.bodyType == 'F' ? 5.0 : 0.0;
    // Sleeves are contoured rather than thick stick limbs.
    for (final left in [true, false]) {
      c.save();
      if (!left) {
        c.translate(200, 0);
        c.scale(-1, 1);
      }
      fill(
        Path()
          ..moveTo(78 + narrow, 75)
          ..cubicTo(66, 74, 63, 83, 61, 94)
          ..lineTo(53, 143)
          ..quadraticBezierTo(56, 149, 64, 147)
          ..lineTo(77, 102)
          ..close(),
        seam,
        highlight: cloth,
      );
      fill(
        Path()
          ..moveTo(54, 142)
          ..lineTo(63, 144)
          ..lineTo(62, 157)
          ..quadraticBezierTo(59, 165, 55, 161)
          ..lineTo(51, 155)
          ..close(),
        shadow,
        highlight: skin,
      );
      line(curve(57, 149, 56, 153, 57, 155, 58, 157), shadow, .8);
      c.restore();
    }
    final torso = Path()
      ..moveTo(78 + narrow, 74)
      ..quadraticBezierTo(100, 68, 122 - narrow, 74)
      ..lineTo(127, 98)
      ..lineTo(121, 124)
      ..lineTo(126, 145)
      ..quadraticBezierTo(101, 150, 74, 145)
      ..lineTo(79, 122)
      ..lineTo(73, 99)
      ..close();
    fill(torso, cloth, highlight: Color.lerp(cloth, Colors.white, .18));
    line(curve(78, 141, 90, 144, 111, 144, 123, 141), seam, 1.4);
    line(
      curve(82, 103, 87, 116, 82, 122, 84, 130),
      seam.withValues(alpha: .45),
      1,
    );
    fill(
      Path()
        ..moveTo(92, 58)
        ..lineTo(108, 58)
        ..lineTo(110, 76)
        ..quadraticBezierTo(100, 87, 90, 76)
        ..close(),
      shadow,
      highlight: skin,
    );
    if (avatar.outfit == 'jacket') {
      fill(
        Path()
          ..moveTo(83, 73)
          ..lineTo(93, 77)
          ..lineTo(98, 147)
          ..lineTo(74, 145)
          ..lineTo(79, 109)
          ..close(),
        seam,
      );
      fill(
        Path()
          ..moveTo(117, 73)
          ..lineTo(107, 77)
          ..lineTo(102, 147)
          ..lineTo(126, 145)
          ..lineTo(121, 109)
          ..close(),
        seam,
      );
      line(
        Path()
          ..moveTo(87, 75)
          ..lineTo(80, 88)
          ..lineTo(92, 94)
          ..lineTo(97, 119),
        Color.lerp(cloth, Colors.white, .3)!,
        1.3,
      );
      line(
        Path()
          ..moveTo(113, 75)
          ..lineTo(120, 88)
          ..lineTo(108, 94)
          ..lineTo(103, 119),
        Color.lerp(cloth, Colors.white, .3)!,
        1.3,
      );
    } else {
      line(curve(89, 76, 94, 85, 106, 85, 111, 76), seam, 3);
      if (avatar.outfit == 'hoodie') {
        line(curve(84, 73, 76, 92, 123, 92, 116, 73), seam, 3);
        line(
          Path()
            ..moveTo(94, 85)
            ..lineTo(93, 102),
          const Color(0xffe4dfcf),
          1,
        );
        line(
          Path()
            ..moveTo(106, 85)
            ..lineTo(107, 102),
          const Color(0xffe4dfcf),
          1,
        );
        line(
          Path()
            ..moveTo(89, 120)
            ..lineTo(83, 134)
            ..quadraticBezierTo(100, 139, 117, 134)
            ..lineTo(111, 120),
          seam,
          1.5,
        );
      }
    }
    // Back hair is a separate layer behind the face.
    if (['long', 'ponytail', 'dreads'].contains(avatar.hairStyle)) {
      fill(
        Path()
          ..moveTo(82, 21)
          ..cubicTo(69, 39, 78, 65, 70, 88)
          ..quadraticBezierTo(87, 94, 92, 72)
          ..lineTo(110, 72)
          ..quadraticBezierTo(120, 96, 132, 84)
          ..cubicTo(120, 61, 131, 24, 112, 19)
          ..close(),
        hair,
      );
    }
    oval(80, 36, 8, 14, shadow);
    oval(112, 36, 8, 14, shadow);
    final square = avatar.faceShape == 'defined';
    final face = Path()
      ..moveTo(84, 29)
      ..cubicTo(84, 9, 115, 9, 116, 29)
      ..lineTo(114, 49)
      ..quadraticBezierTo(112, square ? 61 : 57, 100, 65)
      ..quadraticBezierTo(88, square ? 61 : 57, 86, 49)
      ..close();
    fill(face, skin, highlight: light);
    line(curve(102, 36, 101, 42, 100, 44, 104, 45), shadow, .85);
    line(curve(97, 47, 100, 49, 103, 49, 105, 47), shadow, .65);
    // Almond eyes with lids, iris, pupil and catchlight.
    final blink = time > .43 && time < .51;
    for (final x in [91.0, 109.0]) {
      final eye = Path()
        ..moveTo(x - 4, 37)
        ..quadraticBezierTo(x, 33.5, x + 4, 37)
        ..quadraticBezierTo(x, 40, x - 4, 37)
        ..close();
      if (!blink) {
        fill(eye, const Color(0xfff2e9df));
        oval(x - 1.8, 35.5, 3.6, 3.6, const Color(0xff5d6150));
        oval(x - .8, 36.1, 1.8, 2.4, const Color(0xff242c30));
        oval(x - .6, 35.8, .8, .8, Colors.white);
      }
      line(
        curve(x - 4, 37, x - 1, 34.8, x + 1, 34.8, x + 4, 37),
        const Color(0xff463b38),
        .9,
      );
      line(curve(x - 4, 31.8, x - 1, 30.5, x + 2, 30.7, x + 4, 32), hair, 1.6);
    }
    if (avatar.facialHair == 'stubble') {
      fill(
        Path()
          ..moveTo(86, 45)
          ..quadraticBezierTo(88, 59, 100, 64)
          ..quadraticBezierTo(112, 59, 114, 45)
          ..lineTo(110, 51)
          ..quadraticBezierTo(100, 58, 90, 51)
          ..close(),
        hair.withValues(alpha: .36),
      );
    }
    line(
      curve(95, 53, 99, 54.5, 102, 54.5, 106, 52.5),
      Color.lerp(shadow, const Color(0xff965c59), .4)!,
      1,
    );
    line(curve(97, 56, 99, 57, 102, 57, 104, 55.5), light, .7);
    // Modular hairstyles: each has its own outline and strand treatment.
    if (avatar.hairStyle != 'no_hair') {
      final style = avatar.hairStyle;
      final cap = Path()
        ..moveTo(83, 38)
        ..cubicTo(74, 12, 93, 7, 103, 11)
        ..cubicTo(119, 8, 124, 22, 116, 38)
        ..lineTo(112, 25)
        ..quadraticBezierTo(96, 30, 87, 24)
        ..close();
      if (style == 'buzz') {
        fill(
          Path()
            ..moveTo(83, 33)
            ..cubicTo(78, 9, 120, 6, 117, 33)
            ..lineTo(113, 24)
            ..quadraticBezierTo(100, 19, 87, 25)
            ..close(),
          hair,
        );
      } else {
        fill(cap, hair, highlight: Color.lerp(hair, Colors.white, .1));
        if (style == 'curly') {
          for (var i = 0; i < 13; i++) {
            final a = i * math.pi / 12;
            oval(
              78 + i * 2.6,
              17 - math.sin(a) * 10,
              9,
              11,
              Color.lerp(hair, Colors.white, i % 3 * .04)!,
            );
          }
        } else if (style == 'dreads') {
          for (var i = 0; i < 7; i++) {
            line(
              curve(
                82 + i * 5,
                19,
                78 + i * 5,
                29,
                83 + i * 5,
                35,
                80 + i * 5,
                39 + (i % 3) * 3,
              ),
              Color.lerp(hair, Colors.white, i.isEven ? .09 : 0)!,
              4.4,
            );
          }
        } else {
          for (var i = 0; i < 7; i++) {
            line(
              curve(85 + i * 3.8, 17, 96, 12, 114, 19, 114 - i * 2.2, 29),
              Color.lerp(hair, Colors.white, .16)!,
              .8,
            );
          }
        }
      }
      if (style == 'ponytail') oval(106, 4, 15, 16, hair);
    }
    if (avatar.glasses == 'round') {
      for (final x in [91.0, 109.0]) {
        c.drawOval(
          Rect.fromCenter(center: Offset(x, 37), width: 14, height: 11),
          Paint()
            ..color = ink
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.2,
        );
      }
      line(curve(98, 37, 99, 36, 101, 36, 102, 37), ink, 1);
    }
    c.restore();
  }

  @override
  bool shouldRepaint(covariant PortraitPainter oldDelegate) => true;
}
