import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto/models/menu.dart';
import 'package:resto/models/menu_item.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  Menu? _cachedMenu;
  StreamSubscription<QuerySnapshot>? _menuSubscription;

  Future<Menu> fetchMenu(String restaurantId) async {
    if (_cachedMenu != null) {
      return _cachedMenu!;
    }

    try {
      final menu = await _fetchMenuFromFirebase(restaurantId);
      _cachedMenu = menu;
      _subscribeToMenuUpdates(restaurantId);
      return menu;
    } catch (e) {
      throw Exception('Erreur lors de la récupération du menu: $e');
    }
  }

  Future<Menu> _fetchMenuFromFirebase(String restaurantId) async {
    try {
      final restaurantDoc = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (!restaurantDoc.exists) {
        throw Exception('Restaurant non trouvé');
      }

      final categoriesSnapshot = await _firestore
          .collection('restaurants')
          .doc(restaurantId)
          .collection('menu_categories')
          .orderBy('order')
          .get();

      final categories = await Future.wait(
        categoriesSnapshot.docs.map((categoryDoc) async {
          final categoryData = categoryDoc.data();
          final itemsSnapshot = await categoryDoc.reference
              .collection('items')
              .orderBy('order')
              .get();

          final items = itemsSnapshot.docs.map((itemDoc) {
            final data = itemDoc.data();
            return MenuItem(
              id: itemDoc.id,
              name: data['name'] as String,
              description: data['description'] as String,
              price: (data['price'] as num).toDouble(),
              category: categoryData['name'] as String,
              imageUrl: data['imageUrl'] as String? ?? '',
            );
          }).toList();

          return MenuCategory(
            name: categoryData['name'] as String,
            items: items,
          );
        }),
      );

      return Menu(categories: categories);
    } catch (e) {
      throw Exception('Erreur lors de la récupération du menu: $e');
    }
  }

  Future<void> updateMenu(String restaurantId, Menu menu) async {
    try {
      final batch = _firestore.batch();
      final restaurantRef = _firestore.collection('restaurants').doc(restaurantId);

      batch.set(restaurantRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      final oldCategories = await restaurantRef
          .collection('menu_categories')
          .get();
      
      for (var oldCategory in oldCategories.docs) {
        final itemsSnapshot = await oldCategory.reference.collection('items').get();
        for (var item in itemsSnapshot.docs) {
          batch.delete(item.reference);
        }
        batch.delete(oldCategory.reference);
      }

      for (var i = 0; i < menu.categories.length; i++) {
        final category = menu.categories[i];
        final categoryRef = restaurantRef
            .collection('menu_categories')
            .doc();

        batch.set(categoryRef, {
          'name': category.name,
          'order': i,
        });

        for (var j = 0; j < category.items.length; j++) {
          final item = category.items[j];
          final itemRef = categoryRef.collection('items').doc();

          batch.set(itemRef, {
            'name': item.name,
            'description': item.description,
            'price': item.price,
            'order': j,
            'category': category.name,
            'imageUrl': item.imageUrl,
          });
        }
      }

      await batch.commit();
      _cachedMenu = menu;
    } catch (e) {
      throw Exception('Erreur lors de la mise à jour du menu: $e');
    }
  }

  void _subscribeToMenuUpdates(String restaurantId) {
    _menuSubscription?.cancel();
    _menuSubscription = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu_categories')
        .snapshots()
        .listen((snapshot) async {
      try {
        final menu = await _fetchMenuFromFirebase(restaurantId);
        _cachedMenu = menu;
        _onMenuUpdated?.call(menu);
      } catch (e) {
        print('Erreur lors de la mise à jour du menu: $e');
      }
    });
  }

  Function(Menu)? _onMenuUpdated;

  void setOnMenuUpdated(Function(Menu) callback) {
    _onMenuUpdated = callback;
  }

  void dispose() {
    _menuSubscription?.cancel();
    _menuSubscription = null;
    _cachedMenu = null;
    _onMenuUpdated = null;
  }
}
