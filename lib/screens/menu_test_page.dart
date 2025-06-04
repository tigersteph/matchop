import 'package:flutter/material.dart';
import 'package:resto/models/menu.dart';
import 'package:resto/models/menu_item.dart';

class MenuTestPage extends StatelessWidget {
  const MenuTestPage({super.key});

  Future<void> _createTestMenu(BuildContext context) async {
    try {
      final testRestaurantId = 'test-restaurant-1';
      
      // Créer un menu de test
      final menu = Menu(categories: [
        MenuCategory(
          name: 'Entrées',
          items: [
            MenuItem(
              id: '1',
              name: 'Salade César',
              description: 'Laitue romaine, parmesan, croûtons, sauce César',
              price: 8.50,
              category: 'entrée',  // Modifier ici
              imageUrl: 'https://example.com/salade-cesar.jpg',
            ),
            MenuItem(
              id: '2',
              name: 'Soupe à l\'oignon',
              description: 'Soupe à l\'oignon gratinée au fromage',
              price: 7.00,
              category: MenuCategories.entree,
              imageUrl: 'https://example.com/soupe-oignon.jpg',
            ),
          ],
        ),
        MenuCategory(
          name: 'Plats Principaux',
          items: [
            MenuItem(
              id: '3',
              name: 'Steak Frites',
              description: 'Steak de bœuf, frites maison, sauce au poivre',
              price: 22.00,
              category: MenuCategories.resistance,
              imageUrl: 'https://example.com/steak-frites.jpg',
            ),
            MenuItem(
              id: '4',
              name: 'Saumon Grillé',
              description: 'Saumon frais grillé, légumes de saison',
              price: 24.00,
              category: MenuCategories.resistance,
              imageUrl: 'https://example.com/saumon-grille.jpg',
            ),
          ],
        ),
      ]);

      // Sauvegarder le menu dans Firestore
      await menu.save(testRestaurantId);

      if (!context.mounted) return;

      // Afficher le QR code à scanner
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Menu de test créé avec succès! ✅'),
              const SizedBox(height: 8),
              Text('ID à utiliser pour le QR code: $testRestaurantId'),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 10),
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de la création du menu: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Menu'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () => _createTestMenu(context),
              child: const Text('Créer un menu de test'),
            ),
            const SizedBox(height: 20),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Après avoir créé le menu de test, utilisez l\'ID fourni pour générer un QR code '
                'et le scanner avec l\'application.',
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}