class AvatarModel {
  String bodyType; // "M" or "F"
  String skinTone; // "light" "tan" "brown" "dark"

  // hair
  String hairStyle; // Stable style IDs; existing saves remain compatible.
  String hairColor;
  String outfit;
  String outfitColor;
  String glasses;
  String facialHair;
  String faceShape;

  AvatarModel({
    this.bodyType = "M",
    this.skinTone = "light",
    this.hairStyle = "dreads",
    this.hairColor = 'natural',
    this.outfit = 'sweater',
    this.outfitColor = 'sage',
    this.glasses = 'none',
    this.facialHair = 'none',
    this.faceShape = 'oval',
  });

  factory AvatarModel.fromMap(Map<String, dynamic>? map) => AvatarModel(
    bodyType: map?['body'] ?? 'M',
    skinTone: map?['skin'] ?? 'light',
    hairStyle: map?['hair'] ?? 'dreads',
    hairColor: map?['hairColor'] ?? 'natural',
    outfit: map?['outfit'] ?? 'sweater',
    outfitColor: map?['outfitColor'] ?? 'sage',
    glasses: map?['glasses'] ?? 'none',
    facialHair: map?['facialHair'] ?? 'none',
    faceShape: map?['faceShape'] ?? 'oval',
  );

  Map<String, dynamic> toMap() => {
    'body': bodyType,
    'skin': skinTone,
    'hair': hairStyle,
    'hairColor': hairColor,
    'outfit': outfit,
    'outfitColor': outfitColor,
    'glasses': glasses,
    'facialHair': facialHair,
    'faceShape': faceShape,
  };

  String get bodyAsset => bodyType == "F"
      ? "assets/avatar/body/base_f.png"
      : "assets/avatar/body/base_m.png";

  String get skinAsset {
    // your naming uses skin_lightF.png for female, skin_light.png for male
    final suffix = bodyType == "F" ? "F" : "";
    return "assets/avatar/skin/skin_$skinTone$suffix.png";
  }

  String get hairAsset => "assets/avatar/hair/$hairStyle.png";
}
