import 'package:resto/services/api_service.dart';
import 'menu_item.dart';

class Menu {
  final List<MenuCategory> categories;
  static final ApiService _apiService = ApiService();

  Menu({required this.categories});

  static Future<Menu> fetchMenu(String restaurantId) async {
    try {
      return await _apiService.fetchMenu(restaurantId);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> save(String restaurantId) async {
    await _apiService.updateMenu(restaurantId, this);
  }

  List<MenuItem> getItemsByCategory(String category) {
    return categories
        .expand((cat) => cat.items)
        .where((item) => item.category == category)
        .toList();
  }

  factory Menu.fromJson(Map<String, dynamic> json) {
    return Menu(
      categories: (json['categories'] as List)
          .map((category) => MenuCategory.fromJson(category))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'categories': categories.map((category) => category.toJson()).toList(),
    };
  }

  static Function(Menu)? _onMenuUpdated;
  static void setOnMenuUpdated(Function(Menu) callback) {
    _onMenuUpdated = callback;
    _apiService.setOnMenuUpdated((menu) {
      _onMenuUpdated?.call(menu);
    });
  }

  static void dispose() {
    _onMenuUpdated = null;
    _apiService.dispose();
  }
}

class MenuCategory {
  final String name;
  final List<MenuItem> items;

  MenuCategory({
    required this.name,
    required this.items,
  });

  factory MenuCategory.fromJson(Map<String, dynamic> json) {
    return MenuCategory(
      name: json['name'] as String,
      items: (json['items'] as List)
          .map((item) => MenuItem.fromJson(item))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'items': items.map((item) => item.toJson()).toList(),
    };
  }
}
