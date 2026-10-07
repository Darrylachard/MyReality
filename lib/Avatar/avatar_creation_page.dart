import 'package:flutter/material.dart';
import 'avatar_model.dart';
import 'avatar_widget.dart';

class AvatarCreatorPage extends StatefulWidget {
  const AvatarCreatorPage({super.key, this.initial});
  final AvatarModel? initial;
  @override
  State<AvatarCreatorPage> createState() => _AvatarCreatorPageState();
}

class _AvatarCreatorPageState extends State<AvatarCreatorPage> {
  late final AvatarModel avatar = AvatarModel(
    bodyType: widget.initial?.bodyType ?? 'M',
    skinTone: widget.initial?.skinTone ?? 'light',
    hairStyle: widget.initial?.hairStyle ?? 'dreads',
    hairColor: widget.initial?.hairColor ?? 'natural',
  );
  static const ink = Color(0xff183b33);
  static const skins = <String, (String, Color)>{
    'light': ('Light', Color(0xffefd4c2)),
    'tan': ('Tan', Color(0xffc69b72)),
    'brown': ('Brown', Color(0xff966543)),
    'dark': ('Deep', Color(0xff593b2d)),
  };
  static const hairNames = {
    'natural': 'Brown',
    'black': 'Midnight',
    'copper': 'Copper',
    'honey': 'Honey',
    'silver': 'Silver',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xfff4f5f0),
    appBar: AppBar(
      title: Text(
        widget.initial == null ? 'Create your character' : 'Your character',
      ),
      backgroundColor: const Color(0xfff4f5f0),
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: _preview(400)),
                        const SizedBox(width: 28),
                        Expanded(child: _options()),
                      ],
                    )
                  : Column(
                      children: [
                        _preview(290),
                        const SizedBox(height: 24),
                        _options(),
                      ],
                    ),
            ),
          ),
        );
      },
    ),
    bottomNavigationBar: SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
        child: FilledButton.icon(
          style: FilledButton.styleFrom(
            backgroundColor: ink,
            minimumSize: const Size.fromHeight(52),
          ),
          onPressed: () => Navigator.pop(context, avatar),
          icon: const Icon(Icons.check),
          label: const Text('Save appearance'),
        ),
      ),
    ),
  );

  Widget _preview(double height) => Container(
    height: height,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Color(0xffdce9df), Color(0xfff2e7d6)],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
        Positioned(
          top: 18,
          left: 20,
          child: Text(
            'THIS IS YOUR STORY',
            style: TextStyle(
              color: ink.withValues(alpha: .65),
              fontWeight: FontWeight.w700,
              fontSize: 11,
              letterSpacing: 2,
            ),
          ),
        ),
        Positioned(
          bottom: 30,
          child: Container(
            width: 100,
            height: 14,
            decoration: BoxDecoration(
              color: ink.withValues(alpha: .12),
              borderRadius: BorderRadius.circular(100),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 20, bottom: 24),
          child: AvatarWidget(avatar: avatar, size: height / 1.35),
        ),
        const Positioned(
          bottom: 10,
          child: Text(
            'Built by the choices you make.',
            style: TextStyle(color: ink, fontSize: 12),
          ),
        ),
      ],
    ),
  );

  Widget _options() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        'Make it feel like you.',
        style: TextStyle(
          fontSize: 27,
          color: ink,
          fontWeight: FontWeight.w800,
          letterSpacing: -.6,
        ),
      ),
      const SizedBox(height: 8),
      const Text(
        'Your appearance is yours to change. Your progress stays with you.',
        style: TextStyle(color: Color(0xff64766d), height: 1.5),
      ),
      _heading('Body', 'Choose your base'),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          _choice(
            'Masculine',
            Icons.person_outline,
            avatar.bodyType == 'M',
            () => setState(() => avatar.bodyType = 'M'),
          ),
          _choice(
            'Feminine',
            Icons.person_outline,
            avatar.bodyType == 'F',
            () => setState(() => avatar.bodyType = 'F'),
          ),
        ],
      ),
      _heading('Skin tone', 'Four original palettes'),
      Wrap(
        spacing: 12,
        runSpacing: 10,
        children: [
          for (final s in skins.entries)
            _swatch(
              s.value.$1,
              s.value.$2,
              avatar.skinTone == s.key,
              () => setState(() => avatar.skinTone = s.key),
            ),
        ],
      ),
      _heading('Hair', 'Choose your silhouette'),
      Wrap(
        spacing: 12,
        runSpacing: 12,
        children: [
          _hairTile('dreads', 'Locs'),
          _hairTile('no_hair', 'Clean shave'),
        ],
      ),
      _heading(
        'Hair color',
        avatar.hairStyle == 'no_hair'
            ? 'Choose Locs to show your color'
            : 'Keep the texture. Change the tone.',
      ),
      Opacity(
        opacity: avatar.hairStyle == 'no_hair' ? .45 : 1,
        child: Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final h in AvatarWidget.hairColors.entries)
              _swatch(
                hairNames[h.key]!,
                h.value,
                avatar.hairColor == h.key,
                avatar.hairStyle == 'no_hair'
                    ? null
                    : () => setState(() => avatar.hairColor = h.key),
              ),
          ],
        ),
      ),
      const SizedBox(height: 12),
    ],
  );

  Widget _heading(String title, String subtitle) => Padding(
    padding: const EdgeInsets.only(top: 26, bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 17,
            color: ink,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          subtitle,
          style: const TextStyle(fontSize: 12, color: Color(0xff64766d)),
        ),
      ],
    ),
  );

  Widget _choice(
    String title,
    IconData icon,
    bool selected,
    VoidCallback onTap,
  ) => ChoiceChip(
    label: Text(title),
    avatar: Icon(icon, size: 20),
    selected: selected,
    onSelected: (_) => onTap(),
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
  );

  Widget _swatch(
    String label,
    Color color,
    bool selected,
    VoidCallback? onTap,
  ) => Semantics(
    label: label,
    button: true,
    selected: selected,
    enabled: onTap != null,
    child: SizedBox(
      width: 56,
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                width: 52,
                height: 52,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: selected ? ink : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                  child: selected
                      ? Icon(
                          Icons.check,
                          size: 19,
                          color: color.computeLuminance() > .45
                              ? ink
                              : Colors.white,
                        )
                      : null,
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: ink,
              fontWeight: selected ? FontWeight.w700 : FontWeight.normal,
            ),
          ),
        ],
      ),
    ),
  );

  Widget _hairTile(String style, String label) {
    final selected = avatar.hairStyle == style;
    final preview = AvatarModel(
      bodyType: avatar.bodyType,
      skinTone: avatar.skinTone,
      hairStyle: style,
      hairColor: avatar.hairColor,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '$label hairstyle',
      child: SizedBox(
        width: 132,
        child: Material(
          color: selected ? const Color(0xffdce9df) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? ink : const Color(0xffdde3da),
              width: selected ? 2 : 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => setState(() => avatar.hairStyle = style),
            child: Column(
              children: [
                SizedBox(
                  height: 94,
                  child: ClipRect(
                    child: OverflowBox(
                      alignment: Alignment.topCenter,
                      maxHeight: 260,
                      child: AvatarWidget(avatar: preview, size: 200),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 8, 12),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (selected) ...[
                        const Icon(Icons.check_circle, size: 15, color: ink),
                        const SizedBox(width: 5),
                      ],
                      Flexible(
                        child: Text(
                          label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: ink,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
