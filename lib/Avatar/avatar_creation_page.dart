import '../design/reality_theme.dart';
import 'package:flutter/material.dart';
import 'avatar_model.dart';
import 'avatar_widget.dart';
import 'portrait_painter.dart';

class AvatarCreatorPage extends StatefulWidget {
  const AvatarCreatorPage({super.key, this.initial});
  final AvatarModel? initial;
  @override
  State<AvatarCreatorPage> createState() => _AvatarCreatorPageState();
}

class _AvatarCreatorPageState extends State<AvatarCreatorPage> {
  int category = 0;
  late final AvatarModel avatar = AvatarModel.fromMap(widget.initial?.toMap());
  static const ink = RealityTheme.text;
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
    backgroundColor: RealityTheme.background,
    appBar: AppBar(
      title: Text(
        widget.initial == null ? 'Create your character' : 'Your character',
      ),
      backgroundColor: RealityTheme.background,
    ),
    body: LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 760;
        if (!wide && constraints.maxHeight > 450) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                child: _preview(constraints.maxHeight * .36),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  child: _options(),
                ),
              ),
            ],
          );
        }
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
    width: double.infinity,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(28),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [RealityTheme.elevated, RealityTheme.surface],
      ),
    ),
    child: Stack(
      alignment: Alignment.center,
      children: [
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
      ],
    ),
  );

  Widget _options() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final entry in [
              'Hair',
              'Skin & shape',
              'Clothing',
              'Details',
            ].asMap().entries)
              Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(entry.value),
                  selected: category == entry.key,
                  onSelected: (_) => setState(() => category = entry.key),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      if (category == 0) ...[
        _heading('Hair color', ''),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final h in AvatarWidget.hairColors.entries)
              _swatch(
                hairNames[h.key]!,
                h.value,
                avatar.hairColor == h.key,
                () => setState(() => avatar.hairColor = h.key),
              ),
          ],
        ),
        _heading('Hairstyle', ''),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (final h in const {
              'buzz': 'Buzz cut',
              'short': 'Side swept',
              'curly': 'Curls',
              'dreads': 'Locs',
              'long': 'Long',
              'ponytail': 'Ponytail',
              'no_hair': 'Clean shave',
            }.entries)
              _hairTile(h.key, h.value),
          ],
        ),
      ],
      if (category == 1) ...[
        _heading('Skin tone', ''),
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
        _heading('Silhouette', ''),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final b in const {'M': 'Masculine', 'F': 'Feminine'}.entries)
              ChoiceChip(
                label: Text(b.value),
                selected: avatar.bodyType == b.key,
                onSelected: (_) => setState(() => avatar.bodyType = b.key),
              ),
          ],
        ),
        _heading('Face shape', ''),
        Wrap(
          spacing: 8,
          children: [
            for (final f in ['oval', 'defined'])
              ChoiceChip(
                label: Text(f == 'oval' ? 'Soft oval' : 'Defined jaw'),
                selected: avatar.faceShape == f,
                onSelected: (_) => setState(() => avatar.faceShape = f),
              ),
          ],
        ),
      ],
      if (category == 2) ...[
        _heading('Wardrobe', ''),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final o in const {
              'sweater': 'Sweater',
              'hoodie': 'Hoodie',
              'jacket': 'Jacket',
            }.entries)
              ChoiceChip(
                label: Text(o.value),
                selected: avatar.outfit == o.key,
                onSelected: (_) => setState(() => avatar.outfit = o.key),
              ),
          ],
        ),
        _heading('Fabric color', ''),
        Wrap(
          spacing: 12,
          runSpacing: 10,
          children: [
            for (final c in PortraitPainter.clothes.entries)
              _swatch(
                c.key,
                c.value,
                avatar.outfitColor == c.key,
                () => setState(() => avatar.outfitColor = c.key),
              ),
          ],
        ),
      ],
      if (category == 3) ...[
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Round glasses'),
          value: avatar.glasses == 'round',
          onChanged: (v) =>
              setState(() => avatar.glasses = v ? 'round' : 'none'),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Stubble'),
          value: avatar.facialHair == 'stubble',
          onChanged: (v) =>
              setState(() => avatar.facialHair = v ? 'stubble' : 'none'),
        ),
      ],
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
          style: const TextStyle(fontSize: 12, color: RealityTheme.muted),
        ),
      ],
    ),
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
                              ? RealityTheme.background
                              : RealityTheme.text,
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
      outfit: avatar.outfit,
      outfitColor: avatar.outfitColor,
      glasses: avatar.glasses,
      facialHair: avatar.facialHair,
      faceShape: avatar.faceShape,
    );
    return Semantics(
      button: true,
      selected: selected,
      label: '$label hairstyle',
      child: SizedBox(
        width: 96,
        child: Material(
          color: selected ? RealityTheme.elevated : RealityTheme.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(
              color: selected ? ink : RealityTheme.border,
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
                      minWidth: 200,
                      maxWidth: 200,
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
