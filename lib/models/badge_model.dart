import 'dart:ui';

class Badge {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final int colorHex;

  Badge({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.colorHex,
  });

  factory Badge.fromMap(Map<String, dynamic> data, String id) {
    return Badge(
      id: id,
      name: data['name'],
      description: data['description'],
      emoji: data['emoji'],
      colorHex: data['colorHex'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "name": name,
      "description": description,
      "emoji": emoji,
      "colorHex": colorHex,
    };
  }

  Color get color => Color(colorHex);
}
