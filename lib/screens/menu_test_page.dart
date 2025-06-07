import 'package:flutter/material.dart';
import 'package:resto/models/menu.dart';
import 'package:resto/models/menu_item.dart';

class MenuTestPage extends StatefulWidget {
  const MenuTestPage({super.key});

  @override
  State<MenuTestPage> createState() => _MenuTestPageState();
}

class _MenuTestPageState extends State<MenuTestPage> {
  bool _isLoading = false;
  String? _lastCreatedId;
  Menu? _currentMenu;

  static const testRestaurantId = 'test-restaurant-1';
  
  Future<void> _createTestMenu() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
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
              category: MenuCategories.entree,
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
        MenuCategory(
          name: 'Desserts',
          items: [
            MenuItem(
              id: '5',
              name: 'Crème Brûlée',
              description: 'Crème vanille caramélisée',
              price: 7.50,
              category: MenuCategories.dessert,
              imageUrl: 'https://example.com/creme-brulee.jpg',
            ),
          ],
        ),
      ]);

      // Sauvegarder le menu dans Firestore
      await menu.save(testRestaurantId);
      
      setState(() {
        _lastCreatedId = testRestaurantId;
        _currentMenu = menu;
      });

      _showSuccessMessage();
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadExistingMenu() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final menu = await Menu.fetchMenu(testRestaurantId);
      setState(() {
        _currentMenu = menu;
        _lastCreatedId = testRestaurantId;
      });
      _showSuccessMessage('Menu chargé avec succès! ✅');
    } catch (e) {
      _showErrorMessage(e.toString());
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showSuccessMessage([String message = 'Menu de test créé avec succès! ✅']) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message),
            if (_lastCreatedId != null) ...[
              const SizedBox(height: 8),
              SelectableText(
                'ID à utiliser pour le QR code: $_lastCreatedId',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showErrorMessage(String error) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Erreur: $error'),
        backgroundColor: Colors.red,
        action: SnackBarAction(
          label: 'Fermer',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Menu'),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_isLoading)
                const CircularProgressIndicator()
              else ...[
                ElevatedButton(
                  onPressed: _createTestMenu,
                  child: const Text('Créer un menu de test'),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _loadExistingMenu,
                  child: const Text('Charger le dernier menu'),
                ),
              ],
              const SizedBox(height: 20),
              const Text(
                'Après avoir créé le menu de test, utilisez l\'ID fourni pour générer un QR code '
                'et le scanner avec l\'application.',
                textAlign: TextAlign.center,
              ),
              if (_currentMenu != null) ...[
                const SizedBox(height: 32),
                const Text(
                  'Menu actuel:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildMenuPreview(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuPreview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: _currentMenu!.categories.map((category) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                ...category.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name),
                              Text(
                                item.description,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${item.price.toStringAsFixed(2)} €',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    Menu.dispose();
    super.dispose();
  }
}