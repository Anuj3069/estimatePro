class CardModel {
  final String title;
  final String subtitle;
  final String color;
  final String icon;

  CardModel({
    required this.title,
    required this.subtitle,
    required this.color,
    required this.icon,
  });

  factory CardModel.fromJson(Map<String, dynamic> json) {
    return CardModel(
      title: json['title'] as String,
      subtitle: json['subtitle'] as String,
      color: json['color'] as String,
      icon: json['icon'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'title': title,
        'subtitle': subtitle,
        'color': color,
        'icon': icon,
      };
}
