class AvatarModel {
  String bodyType; // "M" or "F"
  String skinTone; // "light" "tan" "brown" "dark"

  // hair
  String hairStyle; // "dreads" for now
  String hairColor;

  AvatarModel({
    this.bodyType = "M",
    this.skinTone = "light",
    this.hairStyle = "dreads",
    this.hairColor = 'natural',
  });

  factory AvatarModel.fromMap(Map<String, dynamic>? map) => AvatarModel(
    bodyType: map?['body'] ?? 'M',
    skinTone: map?['skin'] ?? 'light',
    hairStyle: map?['hair'] ?? 'dreads',
    hairColor: map?['hairColor'] ?? 'natural',
  );

  Map<String, dynamic> toMap() => {
    'body': bodyType,
    'skin': skinTone,
    'hair': hairStyle,
    'hairColor': hairColor,
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
