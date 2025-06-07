import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as app_order;

class CartService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final Map<String, List<app_order.OrderItem>> _carts = {};
  
  static const String _ordersCollection = 'orders';
  static const int _maxItemQuantity = 99;
  static const Duration _orderTimeout = Duration(minutes: 30);

  // Obtenir les articles du panier
  List<app_order.OrderItem> getCartItems(String tableNumber) {
    _validateTableNumber(tableNumber);
    return List.unmodifiable(_carts[tableNumber] ?? []);
  }

  // Ajouter au panier
  void addToCart(MenuItem menuItem, String tableNumber, app_order.MenuCategory category) {
    _validateTableNumber(tableNumber);
    _validateMenuItem(menuItem);

    debugPrint('🛒 Ajout au panier - Table $tableNumber: ${menuItem.name}');

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
      debugPrint('✅ Nouvel article ajouté au panier');
    } else {
      // Vérifier la quantité maximale
      final existingItem = _carts[tableNumber]![existingItemIndex];
      if (existingItem.quantity >= _maxItemQuantity) {
        debugPrint('⚠️ Quantité maximale atteinte pour ${menuItem.name}');
        throw Exception('Quantité maximale atteinte pour cet article');
      }

      // Mettre à jour l'item existant
      _carts[tableNumber]![existingItemIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + 1,
      );
      debugPrint('✅ Quantité mise à jour: ${existingItem.quantity + 1}');
    }
  }

  // Supprimer du panier
  void removeFromCart(String menuItemId, String tableNumber) {
    _validateTableNumber(tableNumber);
    _validateMenuItemId(menuItemId);

    final itemsBeforeRemoval = _carts[tableNumber]?.length ?? 0;
    _carts[tableNumber]?.removeWhere((item) => item.menuItemId == menuItemId);
    final itemsAfterRemoval = _carts[tableNumber]?.length ?? 0;

    if (itemsBeforeRemoval > itemsAfterRemoval) {
      debugPrint('🗑️ Article supprimé du panier - Table $tableNumber');
    }
  }

  // Mettre à jour la quantité
  void updateQuantity(String menuItemId, String tableNumber, int quantity) {
    _validateTableNumber(tableNumber);
    _validateMenuItemId(menuItemId);
    _validateQuantity(quantity);

    final items = _carts[tableNumber];
    if (items == null) {
      throw StateError('Panier non trouvé pour la table $tableNumber');
    }

    final itemIndex = items.indexWhere((item) => item.menuItemId == menuItemId);
    if (itemIndex == -1) {
      throw StateError('Article non trouvé dans le panier');
    }

    if (quantity <= 0) {
      removeFromCart(menuItemId, tableNumber);
    } else {
      final existingItem = items[itemIndex];
      items[itemIndex] = existingItem.copyWith(quantity: quantity);
      debugPrint('✅ Quantité mise à jour - Table $tableNumber: ${existingItem.name} x$quantity');
    }
  }

  // Soumettre la commande
  Future<String> submitOrder(String tableNumber) async {
    _validateTableNumber(tableNumber);

    final items = _carts[tableNumber];
    if (items == null || items.isEmpty) {
      throw StateError('Le panier est vide');
    }

    final order = app_order.Order(
      id: '',
      tableNumber: tableNumber,
      items: List.from(items), // Créer une copie de la liste
      status: 'pending',
      timestamp: DateTime.now(),
    );

    try {
      debugPrint('🚀 Soumission de la commande - Table $tableNumber');
      
      final docRef = await _firestore.collection(_ordersCollection).add({
        ...order.toJson(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'timeoutAt': Timestamp.fromDate(DateTime.now().add(_orderTimeout)),
      });

      debugPrint('✅ Commande soumise avec succès - ID: ${docRef.id}');
      _carts.remove(tableNumber);
      return docRef.id;
    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firebase lors de la soumission: ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      debugPrint('❌ Erreur lors de la soumission: $e');
      throw Exception('Impossible de soumettre la commande: $e');
    }
  }

  // Calculer le total
  double getTotal(String tableNumber) {
    _validateTableNumber(tableNumber);
    
    final items = _carts[tableNumber];
    if (items == null) return 0;
    
    return items.fold(
      0.0,
      (total, item) => total + (item.price * item.quantity),
    );
  }

  // Vider le panier
  void clearCart(String tableNumber) {
    _validateTableNumber(tableNumber);
    
    if (_carts.remove(tableNumber) != null) {
      debugPrint('🧹 Panier vidé - Table $tableNumber');
    }
  }

  // Méthodes de validation
  void _validateTableNumber(String tableNumber) {
    if (tableNumber.isEmpty) {
      throw ArgumentError('Le numéro de table ne peut pas être vide');
    }
  }

  void _validateMenuItem(MenuItem item) {
    if (item.id.isEmpty) {
      throw ArgumentError('L\'ID de l\'article ne peut pas être vide');
    }
    if (item.price <= 0) {
      throw ArgumentError('Le prix doit être supérieur à 0');
    }
  }

  void _validateMenuItemId(String menuItemId) {
    if (menuItemId.isEmpty) {
      throw ArgumentError('L\'ID de l\'article ne peut pas être vide');
    }
  }

  void _validateQuantity(int quantity) {
    if (quantity < 0) {
      throw ArgumentError('La quantité ne peut pas être négative');
    }
    if (quantity > _maxItemQuantity) {
      throw ArgumentError('La quantité maximum est de $_maxItemQuantity');
    }
  }

  Exception _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Accès non autorisé');
      case 'unavailable':
        return Exception('Service temporairement indisponible');
      default:
        return Exception('Erreur Firebase: ${e.message}');
    }
  }
} 