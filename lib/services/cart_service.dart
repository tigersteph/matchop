import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as app_order;

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<app_order.OrderItem>> _carts = {};

  List<app_order.OrderItem> getCartItems(String tableNumber) {
    return _carts[tableNumber] ?? [];
  }

  void addToCart(MenuItem menuItem, String tableNumber, app_order.MenuCategory category) {
    if (!_carts.containsKey(tableNumber)) {
      _carts[tableNumber] = [];
    }

    final existingItemIndex = _carts[tableNumber]!.indexWhere(
      (item) => item.menuItemId == menuItem.id,
    );

    if (existingItemIndex == -1) {
      // Ajouter un nouvel item
      _carts[tableNumber]!.add(app_order.OrderItem(
        menuItemId: menuItem.id,
        name: menuItem.name,
        price: menuItem.price,
        quantity: 1,
        category: category,
      ));
    } else {
      // Mettre à jour l'item existant
      final existingItem = _carts[tableNumber]![existingItemIndex];
      _carts[tableNumber]![existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
    }
  }

  void removeFromCart(String menuItemId, String tableNumber) {
    _carts[tableNumber]?.removeWhere((item) => item.menuItemId == menuItemId);
  }

  void updateQuantity(String menuItemId, String tableNumber, int quantity) {
    final items = _carts[tableNumber];
    if (items == null) return;

    final itemIndex = items.indexWhere((item) => item.menuItemId == menuItemId);
    if (itemIndex == -1) return;

    if (quantity <= 0) {
      removeFromCart(menuItemId, tableNumber);
    } else {
      final existingItem = items[itemIndex];
      items[itemIndex] = existingItem.copyWith(
        quantity: quantity,
      );
    }
  }

  Future<void> submitOrder(String tableNumber) async {
    final items = _carts[tableNumber];
    if (items == null || items.isEmpty) return;

    final order = app_order.Order(
      id: '',
      tableNumber: tableNumber,
      items: items,
      status: 'pending',
      timestamp: DateTime.now(),
    );

    try {
      await _firestore.collection('orders').add(order.toJson());
      _carts.remove(tableNumber);
    } catch (e) {
      print('Erreur lors de la soumission de la commande: $e');
      rethrow;
    }
  }

  double getTotal(String tableNumber) {
    final items = _carts[tableNumber];
    if (items == null) return 0;
    
    return items.fold(
      0.0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

  void clearCart(String tableNumber) {
    _carts.remove(tableNumber);
  }
} 