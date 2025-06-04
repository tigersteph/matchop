enum MenuCategory {
  entree,
  plat,
  dessert,
  boisson
}

class OrderItem {
  final String menuItemId;
  final String name;
  final double price;
  final int quantity;
  final String? specialInstructions;
  final MenuCategory category;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specialInstructions,
    required this.category,
  });

  OrderItem copyWith({
    String? menuItemId,
    String? name,
    double? price,
    int? quantity,
    String? specialInstructions,
    MenuCategory? category,
  }) {
    return OrderItem(
      menuItemId: menuItemId ?? this.menuItemId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      specialInstructions: specialInstructions ?? this.specialInstructions,
      category: category ?? this.category,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'price': price,
      'quantity': quantity,
      'specialInstructions': specialInstructions,
      'category': category.toString().split('.').last,
    };
  }

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'],
      name: json['name'],
      price: json['price'].toDouble(),
      quantity: json['quantity'],
      specialInstructions: json['specialInstructions'],
      category: MenuCategory.values.firstWhere(
        (e) => e.toString().split('.').last == json['category'],
      ),
    );
  }
}

class Order {
  final String id;
  final String tableNumber;
  final List<OrderItem> items;
  final String status;
  final DateTime timestamp;

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      tableNumber: json['tableNumber'],
      items: (json['items'] as List)
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      status: json['status'],
      timestamp: DateTime.parse(json['timestamp']),
    );
  }

  double get totalAmount => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}
