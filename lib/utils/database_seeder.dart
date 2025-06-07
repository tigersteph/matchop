import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'sample_data.dart';

class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String restaurantId;

  static const int _defaultTableCount = 10;
  static const String _restaurantsCollection = 'restaurants';
  static const String _menuCollection = 'menu';
  static const String _tablesCollection = 'tables';

  DatabaseSeeder({required this.restaurantId}) {
    if (restaurantId.isEmpty) {
      throw ArgumentError('restaurantId ne peut pas être vide');
    }
  }

  DocumentReference get _restaurantRef => 
      _firestore.collection(_restaurantsCollection).doc(restaurantId);

  Future<void> seedMenu() async {
    try {
      final menuCollection = _restaurantRef.collection(_menuCollection);
      debugPrint('🔄 Début de la mise à jour du menu...');

      // Supprimer les anciens éléments dans une transaction
      final batch = _firestore.batch();
      final existingItems = await menuCollection.get();
      for (var doc in existingItems.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
      debugPrint('🗑️ Ancien menu supprimé');

      // Ajouter les nouveaux éléments dans une transaction
      final newBatch = _firestore.batch();
      for (var item in sampleMenuItems) {
        final docRef = menuCollection.doc();
        newBatch.set(docRef, item);
      }
      await newBatch.commit();
      
      debugPrint('✅ Menu ajouté avec succès !');
    } catch (e) {
      debugPrint('❌ Erreur lors de la mise à jour du menu: $e');
      throw Exception('Échec de la mise à jour du menu: $e');
    }
  }

  Future<void> seedTables() async {
    try {
      final tablesCollection = _restaurantRef.collection(_tablesCollection);
      debugPrint('🔄 Début de la création des tables...');

      // Créer les tables dans une transaction
      final batch = _firestore.batch();
      
      for (int i = 1; i <= _defaultTableCount; i++) {
        final tableData = {
          'number': i,
          'seats': i % 2 == 0 ? 4 : 2, // Tables paires: 4 places, impaires: 2 places
          'status': 'available',
          'lastUpdated': FieldValue.serverTimestamp(),
        };
        
        batch.set(tablesCollection.doc(i.toString()), tableData);
      }
      
      await batch.commit();
      debugPrint('✅ Tables créées avec succès !');
    } catch (e) {
      debugPrint('❌ Erreur lors de la création des tables: $e');
      throw Exception('Échec de la création des tables: $e');
    }
  }

  Future<void> seedAll() async {
    try {
      debugPrint('🚀 Début de l\'initialisation de la base de données...');
      
      await _checkRestaurantExists();
      await seedMenu();
      await seedTables();
      
      debugPrint('✨ Base de données initialisée avec succès !');
    } catch (e) {
      debugPrint('💥 Erreur lors de l\'initialisation de la base de données: $e');
      throw Exception('Échec de l\'initialisation de la base de données: $e');
    }
  }

  Future<void> _checkRestaurantExists() async {
    try {
      final restaurantDoc = await _restaurantRef.get();
      if (!restaurantDoc.exists) {
        await _restaurantRef.set({
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'status': 'active',
        });
        debugPrint('✅ Restaurant créé avec succès !');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la vérification/création du restaurant: $e');
      throw Exception('Échec de la vérification/création du restaurant: $e');
    }
  }
}
