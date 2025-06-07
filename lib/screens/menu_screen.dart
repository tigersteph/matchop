import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/order.dart' as app_order;
import '../services/order_service.dart';
import '../models/menu.dart';
import '../services/deep_link_service.dart';

class MenuScreen extends StatefulWidget {
  final String tableNumber;
  final String restaurantId;

  const MenuScreen({
    Key? key,
    required this.tableNumber,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final Map<String, List<MenuItem>> _categorizedItems = {
    'entrée': [],
    'résistance': [],
    'dessert': [],
    'boisson': [],
  };
  final List<app_order.OrderItem> _selectedItems = [];
  bool _isLoading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadMenuItems();
    Menu.setOnMenuUpdated(_handleMenuUpdate);
    
    // Initialisation des animations
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    _tabController.dispose();
    Menu.dispose();
    super.dispose();
  }

  app_order.MenuCategory _getCategoryFromString(String category) {
    switch (category.toLowerCase()) {
      case 'entrée':
        return app_order.MenuCategory.entree;
      case 'résistance':
        return app_order.MenuCategory.plat;
      case 'dessert':
        return app_order.MenuCategory.dessert;
      case 'boisson':
        return app_order.MenuCategory.boisson;
      default:
        return app_order.MenuCategory.plat;
    }
  }

  void _addToOrder(MenuItem item) {
    setState(() {
      final category = _getCategoryFromString(_tabController.index == 0 ? 'entrée' :
                                            _tabController.index == 1 ? 'résistance' :
                                            _tabController.index == 2 ? 'dessert' : 'boisson');
      
      final existingItemIndex = _selectedItems.indexWhere(
        (orderItem) => orderItem.menuItemId == item.id,
      );

      if (existingItemIndex == -1) {
        _selectedItems.add(app_order.OrderItem(
          menuItemId: item.id,
          name: item.name,
          price: item.price,
          quantity: 1,
          category: category,
        ));
      } else {
        final existingItem = _selectedItems[existingItemIndex];
        _selectedItems[existingItemIndex] = existingItem.copyWith(
          quantity: existingItem.quantity + 1,
        );
      }
    });
  }

  Widget _buildMenuItem(MenuItem item) {
    return Card(
      elevation: 4, // Augmentation de l'élévation
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), // Coins arrondis
      margin: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect( // Coins arrondis pour l'image
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: item.imageUrl.isNotEmpty
              ? Image.network(
                  item.imageUrl,
                  height: 120,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.restaurant, size: 120),
                )
              : Container(
                  height: 120,
                  color: Colors.grey[200],
                  child: const Icon(Icons.restaurant, size: 60),
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(12), // Padding augmenté
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  item.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${item.price.toStringAsFixed(2)} €',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Theme.of(context).primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    ScaleTransition(
                      scale: _scaleAnimation,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _animationController.forward(from: 0);
                          _addToOrder(item);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                        icon: const Icon(Icons.add_shopping_cart, size: 20),
                        label: const Text('Ajouter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _loadMenuItems() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final menu = await Menu.fetchMenu(widget.restaurantId);
      if (mounted) {
        setState(() {
          for (var category in menu.categories) {
            _categorizedItems[category.name.toLowerCase()] = category.items;
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Erreur lors du chargement du menu: $e';
          _isLoading = false;
        });
      }
    }
  }

  void _handleMenuUpdate(Menu menu) {
    if (mounted) {
      setState(() {
        for (var category in menu.categories) {
          _categorizedItems[category.name.toLowerCase()] = category.items;
        }
      });
    }
  }

  Widget _buildCategoryTab(String category) {
    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
      ),
      itemCount: _categorizedItems[category]?.length ?? 0,
      itemBuilder: (context, index) {
        final item = _categorizedItems[category]![index];
        return _buildMenuItem(item);
      },
    );
  }

  Future<void> _submitOrder() async {
    if (_selectedItems.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un article')),
      );
      return;
    }

    final scaffoldMessenger = ScaffoldMessenger.of(context);
    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.submitOrder(
        app_order.Order(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tableNumber: widget.tableNumber,
          items: _selectedItems,
          timestamp: DateTime.now(),
          status: 'pending',
        ),
      );

      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Commande envoyée avec succès')),
      );
      
      setState(() {
        _selectedItems.clear();
      });
    } catch (e) {
      if (!mounted) return;
      scaffoldMessenger.showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Menu - Table ${widget.tableNumber}'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Entrées'),
            Tab(text: 'Plats'),
            Tab(text: 'Desserts'),
            Tab(text: 'Boissons'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () async {
              final scaffoldMessenger = ScaffoldMessenger.of(context);
              final deepLinkService = Provider.of<DeepLinkService>(context, listen: false);
              
              try {
                final link = await deepLinkService.createMenuShareLink(
                  menuId: "test-menu-123",
                  menuName: "Menu Test",
                  restaurantName: "Restaurant Test",
                  imageUrl: "https://example.com/menu-image.jpg"
                );
                
                await Clipboard.setData(ClipboardData(text: link));
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  const SnackBar(
                    content: Text('Lien copié !'),
                    duration: Duration(seconds: 1),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                scaffoldMessenger.showSnackBar(
                  SnackBar(
                    content: Text('Erreur : $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(_error!, style: const TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: _loadMenuItems,
                          child: const Text('Réessayer'),
                        ),
                      ],
                    ),
                  )
                : TabBarView(
                    controller: _tabController,
                    children: [
                      _buildCategoryTab('entrée'),
                      _buildCategoryTab('résistance'),
                      _buildCategoryTab('dessert'),
                      _buildCategoryTab('boisson'),
                    ],
                  ),
          ),
          if (_selectedItems.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    'Total: ${_selectedItems.fold(0.0, (sum, item) => sum + (item.price * item.quantity)).toStringAsFixed(2)}€',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  ElevatedButton(
                    onPressed: _submitOrder,
                    child: const Text('Commander'),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
 
