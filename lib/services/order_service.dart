import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import '../models/order.dart';
import '../models/menu_item.dart';
import '../services/logging_service.dart';
import 'package:flutter/foundation.dart';

const maxRetries = 3;
const retryDelay = Duration(seconds: 2);

class OrderService extends ChangeNotifier {
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
    try {
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          await _firestore
              .collection('restaurants')
              .doc(_restaurantId)
              .collection('orders')
              .add(order.toJson());
          return;
        } catch (e) {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(retryDelay);
        }
      }
    } catch (e) {
      LoggingService.error('Erreur lors de la soumission de la commande', error: e);
      rethrow;
    }
  }

  Future<void> updateOrderStatus(String orderId, String newStatus) async {
    try {
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          await _firestore
              .collection('restaurants')
              .doc(_restaurantId)
              .collection('orders')
              .doc(orderId)
              .update({
            'status': newStatus,
          });
          return;
        } catch (e) {
          if (attempt == maxRetries) rethrow;
          await Future.delayed(retryDelay);
        }
      }
    } catch (e) {
      LoggingService.error('Erreur lors de la mise à jour du statut', error: e);
      rethrow;
    }
  }

  Future<List<MenuItem>> getMenuItems() async {
    try {
      for (var attempt = 1; attempt <= maxRetries; attempt++) {
        try {
          final snapshot = await _firestore
              .collection('restaurants')
              .doc(_restaurantId)
              .collection('menu')
              .get();
          final menuItems = snapshot.docs
              .map((doc) => MenuItem.fromJson({...doc.data(), 'id': doc.id}))
              .toList();
          return menuItems;
        } catch (e) {
          if (attempt == maxRetries) {
            LoggingService.error('Erreur lors du chargement du menu', error: e);
            throw Exception('Erreur lors du chargement du menu');
          }
          await Future.delayed(retryDelay);
        }
      }
    } catch (e) {
      LoggingService.error('Erreur lors du chargement du menu', error: e);
      throw Exception('Erreur lors du chargement du menu');
    }
    return []; // Valeur par défaut pour éviter le retour null
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

  Future<void> validateOrder(Order order) async {
    // Validation des doublons
    final existingOrders = await _firestore
        .collection('restaurants')
        .doc(_restaurantId)
        .collection('orders')
        .where('tableNumber', isEqualTo: order.tableNumber)
        .where('status', whereIn: ['pending', 'preparing', 'ready'])
        .get();

    if (existingOrders.docs.isNotEmpty) {
      throw Exception('Une commande est déjà en cours pour cette table');
    }

    // Validation du nombre d'articles
    final totalItems = order.items.fold(0, (currentSum, item) => currentSum + item.quantity);
    if (totalItems > 50) {
      throw Exception('Le nombre maximum d\'articles par commande est de 50');
    }
  }
}
