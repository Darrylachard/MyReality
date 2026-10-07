import 'package:flutter/material.dart';
import 'avatar_model.dart';

class AvatarWidget extends StatelessWidget {
  static const hairColors = <String, Color>{
    'natural': Color(0xff59361e),
    'black': Color(0xff181b20),
    'copper': Color(0xffb66a42),
    'honey': Color(0xffd5b777),
    'silver': Color(0xffb8c5cd),
  };
  final AvatarModel avatar;
  final double size;

  const AvatarWidget({super.key, required this.avatar, this.size = 260});

  @override
  Widget build(BuildContext context) {
    final double height = size * 1.2;

    return SizedBox(
      width: size,
      height: height,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // BODY (smooth switch on skin change)
          SizedBox(
            width: size,
            height: height,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              switchInCurve: Curves.easeOut,
              switchOutCurve: Curves.easeIn,
              child: Image.asset(
                avatar.skinAsset,
                key: ValueKey(avatar.skinAsset),
                fit: BoxFit.contain,
              ),
            ),
          ),

          // HAIR (smooth switch + slight vertical tweak)
          Transform.translate(
            offset: Offset(0, -size * 0.04),
            child: SizedBox(
              width: size,
              height: height,
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                switchInCurve: Curves.easeOut,
                switchOutCurve: Curves.easeIn,
                child: ColorFiltered(
                  key: ValueKey('${avatar.hairAsset}:${avatar.hairColor}'),
                  colorFilter: ColorFilter.mode(
                    (hairColors[avatar.hairColor] ?? hairColors['natural']!)
                        .withValues(
                          alpha: avatar.hairColor == 'natural' ? 0 : .78,
                        ),
                    BlendMode.srcATop,
                  ),
                  child: Image.asset(avatar.hairAsset, fit: BoxFit.contain),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
