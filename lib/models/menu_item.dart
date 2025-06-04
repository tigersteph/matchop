// Au début du fichier
class MenuCategories {
  static const String entree = 'entrée';
  static const String resistance = 'résistance';
  static const String dessert = 'dessert';
  static const String boisson = 'boisson';

  static List<String> get all => [entree, resistance, dessert, boisson];
}

class MenuItem {
  final String id;
  final String name;
  final String description;
  final double price;
  final String category; // 'entree', 'resistance', 'dessert', 'boisson'
  final String imageUrl;

  MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    required this.imageUrl,
  });

  factory MenuItem.fromJson(Map<String, dynamic> json) {
    return MenuItem(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      category: json['category'] as String,
      imageUrl: json['imageUrl'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'category': category,
      'imageUrl': imageUrl,
    };
  }
}
