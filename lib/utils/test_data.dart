import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/qr_code_data.dart';
import 'sample_data.dart';

class TestData {
  static const String testRestaurantId = 'test123';
  static const String testMenuId = 'menu1';
  static const String testTableName = 'table1';
  static const String testRestaurantName = 'Test Restaurant';

  static Future<void> initializeTestRestaurant() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Créer le restaurant
      await firestore.collection('restaurants').doc(testRestaurantId).set({
        'name': testRestaurantName,
        'address': '123 Test Street',
        'phone': '+123456789',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer la table
      await firestore
          .collection('restaurants')
          .doc(testRestaurantId)
          .collection('tables')
          .doc(testTableName)
          .set({
        'name': testTableName,
        'capacity': 4,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      // Créer le menu avec les items de sample_data
      await firestore
          .collection('restaurants')
          .doc(testRestaurantId)
          .collection('menus')
          .doc(testMenuId)
          .set({
        'name': 'Menu Test',
        'description': 'Menu de test pour le restaurant',
        'items': sampleMenuItems,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Restaurant de test configuré avec succès');
      print('QR code pour tester: ${getTestQRCode()}');
    } catch (e) {
      print('❌ Erreur lors de la configuration du restaurant de test: $e');
      rethrow;
    }
  }

  static String getTestQRCode() {
    return QRCodeData(
      restaurantId: testRestaurantId,
      restaurantName: 'Test Restaurant',
      menuId: testMenuId,
      tableName: testTableName,
      timestamp: DateTime.now(),
    ).toQRString();
  }

  static Future<void> setupTestRestaurant() async {
    try {
      final firestore = FirebaseFirestore.instance;
      
      // Créer le restaurant
      await firestore.collection('restaurants').doc(testRestaurantId).set({
        'name': 'Test Restaurant',
        'address': '123 Test Street',
        'phone': '+123456789',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Créer la table
      await firestore
          .collection('restaurants')
          .doc(testRestaurantId)
          .collection('tables')
          .doc(testTableName)
          .set({
        'name': testTableName,
        'capacity': 4,
        'status': 'available',
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Créer le menu
      await firestore
          .collection('restaurants')
          .doc(testRestaurantId)
          .collection('menus')
          .doc(testMenuId)
          .set({
        'name': 'Menu Test',
        'description': 'Menu de test pour le restaurant',
        'items': [
          {
            'name': 'Salade César',
            'description': 'Laitue romaine, croûtons, parmesan, sauce césar maison',
            'price': 8.99,
            'category': 'entrée',
            'imageUrl': 'https://example.com/caesar_salad.jpg',
          },
          {
            'name': 'Steak Frites',
            'description': 'Steak de boeuf grillé, frites maison, sauce au poivre',
            'price': 24.99,
            'category': 'résistance',
            'imageUrl': 'https://example.com/steak_frites.jpg',
          },
          {
            'name': 'Crème Brûlée',
            'description': 'Crème vanille, caramel croustillant',
            'price': 6.99,
            'category': 'dessert',
            'imageUrl': 'https://example.com/creme_brulee.jpg',
          },
        ],
        'createdAt': FieldValue.serverTimestamp(),
      });

      print('✅ Restaurant de test configuré avec succès');
    } catch (e) {
      print('❌ Erreur lors de la configuration du restaurant de test: $e');
      rethrow;
    }
  }
}
