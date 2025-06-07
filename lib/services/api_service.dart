import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:resto/models/menu.dart';
import 'package:resto/models/menu_item.dart';

class ApiService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Constantes
  static const String _restaurantsCollection = 'restaurants';
  static const String _categoriesCollection = 'menu_categories';
  static const String _itemsCollection = 'items';
  static const Duration _cacheExpiration = Duration(minutes: 30);
  static const int _batchSize = 20;

  // Cache et état
  final Map<String, _CacheEntry<Menu>> _menuCache = {};
  final Map<String, StreamSubscription<QuerySnapshot>> _menuSubscriptions = {};
  final Map<String, Function(Menu)> _updateCallbacks = {};

  /// Récupère le menu d'un restaurant
  Future<Menu> fetchMenu(String restaurantId) async {
    _validateRestaurantId(restaurantId);

    try {
      // Vérifier le cache
      if (_isCacheValid(restaurantId)) {
        debugPrint('💨 Utilisation du cache pour le restaurant: $restaurantId');
        return _menuCache[restaurantId]!.data!;
      }

      debugPrint('🔍 Récupération du menu pour le restaurant: $restaurantId');
      final menu = await _fetchMenuFromFirebase(restaurantId);
      _updateMenuCache(restaurantId, menu);
      _subscribeToMenuUpdates(restaurantId);
      
      return menu;
    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firebase: ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du menu: $e');
      throw Exception('Impossible de récupérer le menu: $e');
    }
  }

  Future<Menu> _fetchMenuFromFirebase(String restaurantId) async {
    // Vérifier l'existence du restaurant
    final restaurantDoc = await _firestore
        .collection(_restaurantsCollection)
        .doc(restaurantId)
        .get();

    if (!restaurantDoc.exists) {
      throw Exception('Restaurant non trouvé: $restaurantId');
    }

    // Récupérer les catégories avec pagination
    final categories = await _fetchCategoriesWithPagination(restaurantId);
    
    if (categories.isEmpty) {
      debugPrint('ℹ️ Aucune catégorie trouvée pour le restaurant: $restaurantId');
      return Menu(categories: []);
    }

    return Menu(categories: categories);
  }

  Future<List<MenuCategory>> _fetchCategoriesWithPagination(String restaurantId) async {
    List<MenuCategory> allCategories = [];
    DocumentSnapshot? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      final query = _firestore
          .collection(_restaurantsCollection)
          .doc(restaurantId)
          .collection(_categoriesCollection)
          .orderBy('order')
          .limit(_batchSize);

      if (lastDoc != null) {
        query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        continue;
      }

      final categoryFutures = snapshot.docs.map((categoryDoc) async {
        return await _processCategoryDocument(categoryDoc);
      });

      allCategories.addAll(await Future.wait(categoryFutures));
      lastDoc = snapshot.docs.last;
      
      hasMore = snapshot.docs.length >= _batchSize;
    }

    return allCategories;
  }

  Future<MenuCategory> _processCategoryDocument(
    QueryDocumentSnapshot<Map<String, dynamic>> categoryDoc
  ) async {
    final categoryData = categoryDoc.data();
    _validateCategoryData(categoryData, categoryDoc.id);

    final items = await _fetchItemsWithPagination(categoryDoc.reference);
    
    return MenuCategory(
      name: categoryData['name'] as String,
      items: items,
    );
  }

  Future<List<MenuItem>> _fetchItemsWithPagination(
    DocumentReference categoryRef
  ) async {
    List<MenuItem> allItems = [];
    DocumentSnapshot? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      final query = categoryRef
          .collection(_itemsCollection)
          .orderBy('order')
          .limit(_batchSize);

      if (lastDoc != null) {
        query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get();
      
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        continue;
      }

      final items = snapshot.docs.map((doc) => _processItemDocument(doc)).toList();
      allItems.addAll(items);
      lastDoc = snapshot.docs.last;
      
      hasMore = snapshot.docs.length >= _batchSize;
    }

    return allItems;
  }

  MenuItem _processItemDocument(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();
    _validateItemData(data, doc.id);

    return MenuItem(
      id: doc.id,
      name: data['name'] as String,
      description: data['description'] as String,
      price: (data['price'] as num).toDouble(),
      category: data['category'] as String,
      imageUrl: data['imageUrl'] as String? ?? '',
    );
  }

  Future<void> updateMenu(String restaurantId, Menu menu) async {
    _validateRestaurantId(restaurantId);
    _validateMenu(menu);

    try {
      debugPrint('🔄 Mise à jour du menu pour le restaurant: $restaurantId');
      
      final batch = _firestore.batch();
      final restaurantRef = _firestore.collection(_restaurantsCollection).doc(restaurantId);

      // Mettre à jour le timestamp du restaurant
      batch.set(restaurantRef, {
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      // Supprimer les anciennes données
      await _deleteExistingMenuData(restaurantRef, batch);

      // Ajouter les nouvelles données
      _addNewMenuData(restaurantRef, menu, batch);

      // Exécuter le batch
      await batch.commit();
      
      // Mettre à jour le cache
      _updateMenuCache(restaurantId, menu);
      debugPrint('✅ Menu mis à jour avec succès');
    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firebase lors de la mise à jour: ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du menu: $e');
      throw Exception('Impossible de mettre à jour le menu: $e');
    }
  }

  Future<void> _deleteExistingMenuData(
    DocumentReference restaurantRef,
    WriteBatch batch,
  ) async {
    final oldCategories = await restaurantRef
        .collection(_categoriesCollection)
        .get();
    
    for (var oldCategory in oldCategories.docs) {
      final itemsSnapshot = await oldCategory.reference
          .collection(_itemsCollection)
          .get();
          
      for (var item in itemsSnapshot.docs) {
        batch.delete(item.reference);
      }
      batch.delete(oldCategory.reference);
    }
  }

  void _addNewMenuData(
    DocumentReference restaurantRef,
    Menu menu,
    WriteBatch batch,
  ) {
    for (var i = 0; i < menu.categories.length; i++) {
      final category = menu.categories[i];
      final categoryRef = restaurantRef
          .collection(_categoriesCollection)
          .doc();

      batch.set(categoryRef, {
        'name': category.name,
        'order': i,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      for (var j = 0; j < category.items.length; j++) {
        final item = category.items[j];
        final itemRef = categoryRef.collection(_itemsCollection).doc();

        batch.set(itemRef, {
          'name': item.name,
          'description': item.description,
          'price': item.price,
          'order': j,
          'category': category.name,
          'imageUrl': item.imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
    }
  }

  void _subscribeToMenuUpdates(String restaurantId) {
    // Annuler l'ancienne souscription si elle existe
    _menuSubscriptions[restaurantId]?.cancel();
    
    // Créer une nouvelle souscription
    _menuSubscriptions[restaurantId] = _firestore
        .collection(_restaurantsCollection)
        .doc(restaurantId)
        .collection(_categoriesCollection)
        .snapshots()
        .listen((snapshot) async {
      try {
        debugPrint('🔄 Mise à jour du menu détectée pour: $restaurantId');
        final menu = await _fetchMenuFromFirebase(restaurantId);
        _updateMenuCache(restaurantId, menu);
        _notifyMenuUpdate(restaurantId, menu);
      } catch (e) {
        debugPrint('⚠️ Erreur lors de la mise à jour du menu: $e');
      }
    });
  }

  // Méthodes de gestion du cache et des callbacks
  void _updateMenuCache(String restaurantId, Menu menu) {
    _menuCache[restaurantId] = _CacheEntry(menu);
  }

  bool _isCacheValid(String restaurantId) {
    final entry = _menuCache[restaurantId];
    if (entry == null || entry.data == null) return false;
    return DateTime.now().difference(entry.timestamp) < _cacheExpiration;
  }

  void _notifyMenuUpdate(String restaurantId, Menu menu) {
    _updateCallbacks[restaurantId]?.call(menu);
  }

  void setOnMenuUpdated(String restaurantId, Function(Menu) callback) {
    _validateRestaurantId(restaurantId);
    _updateCallbacks[restaurantId] = callback;
  }

  // Méthodes de validation
  void _validateRestaurantId(String restaurantId) {
    if (restaurantId.isEmpty) {
      throw ArgumentError('L\'ID du restaurant ne peut pas être vide');
    }
  }

  void _validateMenu(Menu menu) {
    if (menu.categories.isEmpty) {
      throw ArgumentError('Le menu doit contenir au moins une catégorie');
    }

    for (var category in menu.categories) {
      if (category.name.isEmpty) {
        throw ArgumentError('Le nom de la catégorie ne peut pas être vide');
      }
    }
  }

  void _validateCategoryData(Map<String, dynamic> data, String docId) {
    if (!data.containsKey('name') || data['name'].isEmpty) {
      throw Exception('Nom de catégorie invalide pour: $docId');
    }
  }

  void _validateItemData(Map<String, dynamic> data, String docId) {
    final requiredFields = ['name', 'description', 'price', 'category'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        throw Exception('Champ requis manquant ($field) pour l\'article: $docId');
      }
    }

    if (data['price'] is! num || data['price'] <= 0) {
      throw Exception('Prix invalide pour l\'article: $docId');
    }
  }

  Exception _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Accès non autorisé');
      case 'not-found':
        return Exception('Restaurant ou menu non trouvé');
      case 'unavailable':
        return Exception('Service temporairement indisponible');
      case 'resource-exhausted':
        return Exception('Limite de requêtes atteinte');
      case 'deadline-exceeded':
        return Exception('Délai d\'attente dépassé');
      default:
        return Exception('Erreur Firebase: ${e.message}');
    }
  }

  void dispose() {
    for (var subscription in _menuSubscriptions.values) {
      subscription.cancel();
    }
    _menuSubscriptions.clear();
    _menuCache.clear();
    _updateCallbacks.clear();
  }
}

/// Classe utilitaire pour gérer les entrées du cache avec leur timestamp
class _CacheEntry<T> {
  T? data;
  DateTime timestamp;

  _CacheEntry(this.data) : timestamp = DateTime.now();
}
