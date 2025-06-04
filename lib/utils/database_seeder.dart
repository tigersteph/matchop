import 'package:cloud_firestore/cloud_firestore.dart';
import 'sample_data.dart';

class DatabaseSeeder {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String restaurantId;

  DatabaseSeeder({required this.restaurantId});

  Future<void> seedMenu() async {
    final menuCollection = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('menu');

    // Supprimer les anciens éléments
    final existingItems = await menuCollection.get();
    for (var doc in existingItems.docs) {
      await doc.reference.delete();
    }

    // Ajouter les nouveaux éléments
    for (var item in sampleMenuItems) {
      await menuCollection.add(item);
    }

    print('Menu ajouté avec succès !');
  }

  Future<void> seedTables() async {
    final tablesCollection = _firestore
        .collection('restaurants')
        .doc(restaurantId)
        .collection('tables');

    // Créer 10 tables
    for (int i = 1; i <= 10; i++) {
      await tablesCollection.doc(i.toString()).set({
        'number': i,
        'seats': i % 2 == 0 ? 4 : 2, // Tables paires: 4 places, impaires: 2 places
        'status': 'available',
      });
    }

    print('Tables ajoutées avec succès !');
  }

  Future<void> seedAll() async {
    await seedMenu();
    await seedTables();
    print('Base de données initialisée avec succès !');
  }
}
