import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../models/menu_item.dart';
import 'dart:async';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  // Constantes pour la configuration
  static const String _menuItemsCollection = 'menu_items';
  static const String _categoryField = 'category';
  static const Duration _cacheExpiration = Duration(hours: 24);
  static const int _batchSize = 20;
  static const bool _isTestMode = bool.fromEnvironment('FLUTTER_TEST', defaultValue: false);

  // Cache en mémoire pour les performances
  final Map<String, _CacheEntry<List<MenuItem>>> _categoryCache = {};
  final _CacheEntry<List<MenuItem>> _allItemsCache = _CacheEntry<List<MenuItem>>();
  
  // Métriques de performance
  final Map<String, int> _cacheHits = {};
  final Map<String, int> _cacheMisses = {};
  final Stopwatch _performanceTimer = Stopwatch();

  CollectionReference<Map<String, dynamic>> get _menuCollection =>
      _firestore.collection(_menuItemsCollection);

  /// Initialise le service avec la configuration du cache
  Future<void> initialize() async {
    try {
      _performanceTimer.start();

      if (!_isTestMode) {
        
        // Configuration du cache réseau
        _firestore.settings = const Settings(
          persistenceEnabled: true,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
      }

      debugPrint('✅ Cache Firestore initialisé avec succès ${_isTestMode ? "(Mode Test)" : ""}');
      
      // Préchargement des données fréquemment utilisées
      if (!_isTestMode) {
        await _preloadFrequentData();
      }
    } catch (e) {
      debugPrint('⚠️ Erreur lors de l\'initialisation du cache: $e');
      // On ne relance pas l'erreur car l'app peut fonctionner sans cache
    }
  }

  /// Réinitialise le service (utile pour les tests)
  void reset() {
    _categoryCache.clear();
    _allItemsCache.data = null;
    _cacheHits.clear();
    _cacheMisses.clear();
    _performanceTimer.reset();
  }

  /// Obtient les métriques de performance
  Map<String, dynamic> getMetrics() {
    return {
      'cacheHits': Map<String, int>.from(_cacheHits),
      'cacheMisses': Map<String, int>.from(_cacheMisses),
      'uptime': _performanceTimer.elapsed.toString(),
      'cacheSize': {
        'categories': _categoryCache.length,
        'totalItems': _allItemsCache.data?.length ?? 0,
      },
    };
  }

  /// Vérifie la santé du service
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      await _firestore
          .collection(_menuItemsCollection)
          .limit(1)
          .get();

      return {
        'status': 'healthy',
        'firestore': 'connected',
        'lastCheck': DateTime.now().toIso8601String(),
        'metrics': getMetrics(),
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
        'lastCheck': DateTime.now().toIso8601String(),
        'metrics': getMetrics(),
      };
    }
  }

  void _updateCacheMetrics(String category, bool isHit) {
    if (isHit) {
      _cacheHits[category] = (_cacheHits[category] ?? 0) + 1;
    } else {
      _cacheMisses[category] = (_cacheMisses[category] ?? 0) + 1;
    }
  }

  Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    _validateCategory(category);

    try {
      // Vérifier le cache en mémoire d'abord
      if (_isCacheValid(_categoryCache[category])) {
        _updateCacheMetrics(category, true);
        debugPrint('💨 Utilisation du cache en mémoire pour la catégorie: $category');
        return _categoryCache[category]!.data!;
      }

      _updateCacheMetrics(category, false);
      debugPrint('🔍 Récupération des articles pour la catégorie: $category');
      
      // Essayer depuis le cache Firestore
      if (!_isTestMode) {
        try {
          final cachedSnapshot = await _menuCollection
              .where(_categoryField, isEqualTo: category)
              .get(const GetOptions(source: Source.cache));

          if (cachedSnapshot.docs.isNotEmpty) {
            final items = _processQuerySnapshot(cachedSnapshot);
            _updateCategoryCache(category, items);
            debugPrint('📦 ${items.length} articles récupérés depuis le cache pour la catégorie: $category');
            return items;
          }
        } catch (e) {
          debugPrint('⚠️ Cache miss pour la catégorie: $category');
        }
      }

      // Requête au serveur avec pagination
      final items = await _fetchAllItemsWithPagination(category);
      _updateCategoryCache(category, items);
      debugPrint('🌐 ${items.length} articles récupérés du serveur pour la catégorie: $category');
      return items;

    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firebase lors de la récupération des articles: ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des articles: $e');
      throw Exception('Impossible de récupérer les articles du menu: $e');
    }
  }

  Future<List<MenuItem>> getAllMenuItems() async {
    try {
      // Vérifier le cache en mémoire d'abord
      if (_isCacheValid(_allItemsCache)) {
        _updateCacheMetrics('all', true);
        debugPrint('💨 Utilisation du cache en mémoire pour tous les articles');
        return _allItemsCache.data!;
      }

      _updateCacheMetrics('all', false);
      debugPrint('🔍 Récupération de tous les articles du menu');
      
      // Essayer depuis le cache Firestore
      if (!_isTestMode) {
        try {
          final cachedSnapshot = await _menuCollection
              .get(const GetOptions(source: Source.cache));

          if (cachedSnapshot.docs.isNotEmpty) {
            final items = _processQuerySnapshot(cachedSnapshot);
            _updateAllItemsCache(items);
            debugPrint('📦 ${items.length} articles récupérés depuis le cache');
            return items;
          }
        } catch (e) {
          debugPrint('⚠️ Cache miss pour tous les articles');
        }
      }

      // Requête au serveur avec pagination
      final items = await _fetchAllItemsWithPagination(null);
      _updateAllItemsCache(items);
      debugPrint('🌐 ${items.length} articles récupérés du serveur');
      return items;

    } on FirebaseException catch (e) {
      debugPrint('❌ Erreur Firebase lors de la récupération du menu: ${e.message}');
      throw _handleFirebaseError(e);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du menu: $e');
      throw Exception('Impossible de récupérer le menu: $e');
    }
  }

  // Méthodes privées pour la gestion du cache et des requêtes

  Future<void> _preloadFrequentData() async {
    try {
      debugPrint('🔄 Préchargement des données fréquentes...');
      await getAllMenuItems();
      debugPrint('✅ Préchargement terminé');
    } catch (e) {
      debugPrint('⚠️ Erreur lors du préchargement: $e');
    }
  }

  Future<List<MenuItem>> _fetchAllItemsWithPagination(String? category) async {
    List<MenuItem> allItems = [];
    DocumentSnapshot? lastDoc;
    bool hasMore = true;

    while (hasMore) {
      Query<Map<String, dynamic>> query = _menuCollection;
      
      if (category != null) {
        query = query.where(_categoryField, isEqualTo: category);
      }

      query = query
          .orderBy('name')
          .limit(_batchSize);

      if (lastDoc != null) {
        query = query.startAfterDocument(lastDoc);
      }

      final snapshot = await query.get(const GetOptions(source: Source.server));
      
      if (snapshot.docs.isEmpty) {
        hasMore = false;
        continue;
      }

      allItems.addAll(_processQuerySnapshot(snapshot));
      lastDoc = snapshot.docs.last;
      
      if (snapshot.docs.length < _batchSize) {
        hasMore = false;
      }
    }

    return allItems;
  }

  List<MenuItem> _processQuerySnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
    return snapshot.docs.map(_docToMenuItem).toList();
  }

  void _updateCategoryCache(String category, List<MenuItem> items) {
    _categoryCache[category] = _CacheEntry(items);
  }

  void _updateAllItemsCache(List<MenuItem> items) {
    _allItemsCache.update(items);
  }

  bool _isCacheValid(_CacheEntry? entry) {
    if (entry == null || entry.data == null) return false;
    return DateTime.now().difference(entry.timestamp) < _cacheExpiration;
  }

  void _validateCategory(String category) {
    if (category.isEmpty) {
      throw ArgumentError('La catégorie ne peut pas être vide');
    }
  }

  MenuItem _docToMenuItem(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    try {
      final data = doc.data();
      _validateMenuItemData(data, doc.id);
      
      return MenuItem.fromJson({
        ...data,
        'id': doc.id,
      });
    } catch (e) {
      debugPrint('❌ Erreur lors de la conversion du document ${doc.id}: $e');
      throw Exception('Erreur de format pour l\'article ${doc.id}: $e');
    }
  }

  void _validateMenuItemData(Map<String, dynamic> data, String docId) {
    final requiredFields = ['name', 'price', 'category'];
    for (final field in requiredFields) {
      if (!data.containsKey(field)) {
        throw Exception('Champ requis manquant ($field) pour l\'article $docId');
      }
    }

    if (data['price'] is! num || data['price'] <= 0) {
      throw Exception('Prix invalide pour l\'article $docId');
    }
  }

  Exception _handleFirebaseError(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return Exception('Accès non autorisé au menu');
      case 'unavailable':
        return Exception('Service temporairement indisponible');
      case 'not-found':
        return Exception('Menu introuvable');
      case 'resource-exhausted':
        return Exception('Limite de requêtes atteinte, veuillez réessayer plus tard');
      case 'deadline-exceeded':
        return Exception('Délai d\'attente dépassé, veuillez réessayer');
      default:
        return Exception('Erreur Firebase: ${e.message}');
    }
  }
}

/// Classe utilitaire pour gérer les entrées du cache avec leur timestamp
class _CacheEntry<T> {
  T? data;
  DateTime timestamp;

  _CacheEntry([this.data]) : timestamp = DateTime.now();

  void update(T newData) {
    data = newData;
    timestamp = DateTime.now();
  }
} 