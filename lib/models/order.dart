class Order {
  final String id;
  final String tableNumber;
  final List<OrderItem> items;
  final DateTime timestamp;
  final String status; // 'pending', 'preparing', 'ready', 'served'

  Order({
    required this.id,
    required this.tableNumber,
    required this.items,
    required this.timestamp,
    required this.status,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      tableNumber: json['tableNumber'] as String,
      items: (json['items'] as List).map((item) => OrderItem.fromJson(item)).toList(),
      timestamp: DateTime.parse(json['timestamp'] as String),
      status: json['status'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'tableNumber': tableNumber,
      'items': items.map((item) => item.toJson()).toList(),
      'timestamp': timestamp.toIso8601String(),
      'status': status,
    };
  }

  double get totalAmount => items.fold(0, (sum, item) => sum + (item.price * item.quantity));
}

class OrderItem {
  final String menuItemId;
  final String name;
  int quantity; // Removed final to allow modification
  final double price;
  final String? specialInstructions;

  OrderItem({
    required this.menuItemId,
    required this.name,
    required this.quantity,
    required this.price,
    this.specialInstructions,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      menuItemId: json['menuItemId'] as String,
      name: json['name'] as String,
      quantity: json['quantity'] as int,
      price: (json['price'] as num).toDouble(),
      specialInstructions: json['specialInstructions'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'menuItemId': menuItemId,
      'name': name,
      'quantity': quantity,
      'price': price,
      'specialInstructions': specialInstructions,
    };
  }
}
