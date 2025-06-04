import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_item.dart';

class MenuService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<List<MenuItem>> getMenuItemsByCategory(String category) async {
    try {
      final snapshot = await _firestore
          .collection('menu_items')
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => MenuItem.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération des articles du menu: $e');
      return [];
    }
  }

  Future<List<MenuItem>> getAllMenuItems() async {
    try {
      final snapshot = await _firestore.collection('menu_items').get();
      return snapshot.docs
          .map((doc) => MenuItem.fromJson({
                ...doc.data(),
                'id': doc.id,
              }))
          .toList();
    } catch (e) {
      print('Erreur lors de la récupération du menu: $e');
      return [];
    }
  }
} 