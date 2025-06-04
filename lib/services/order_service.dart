import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../models/menu_item.dart';

class OrderService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _restaurantId;

  OrderService({String? restaurantId}) : _restaurantId = restaurantId ?? 'resto-e9414';

  Stream<List<Order>> get ordersStream {
    return _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Order.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }

  Future<void> submitOrder(Order order) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .add(order.toJson());
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .doc(orderId)
        .update({
      'status': newStatus,
    });
  }

  Future<List<MenuItem>> getMenuItems() async {
    final snapshot = await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('menu')
        .get();

    return snapshot.docs
        .map((doc) => MenuItem.fromJson({...doc.data(), 'id': doc.id}))
        .toList();
  }

  Stream<List<MenuItem>> get menuStream {
    return _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('menu')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => MenuItem.fromJson({...doc.data(), 'id': doc.id}))
          .toList();
    });
  }
}
