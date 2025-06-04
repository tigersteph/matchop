import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/menu_item.dart';
import '../models/order.dart';
import '../services/order_service.dart';
import '../models/menu.dart';

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
  final List<OrderItem> _selectedItems = [];
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

  void _addToOrder(MenuItem item) {
    setState(() {
      final existingItem = _selectedItems.firstWhere(
        (orderItem) => orderItem.menuItemId == item.id,
        orElse: () => OrderItem(
          menuItemId: item.id,
          name: item.name,
          quantity: 0,
          price: item.price,
        ),
      );

      if (existingItem.quantity == 0) {
        _selectedItems.add(existingItem);
      }
      
      existingItem.quantity++;
    });
  }

  Future<void> _submitOrder() async {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez sélectionner au moins un article')),
      );
      return;
    }

    try {
      final orderService = Provider.of<OrderService>(context, listen: false);
      await orderService.submitOrder(
        Order(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          tableNumber: widget.tableNumber,
          items: _selectedItems,
          timestamp: DateTime.now(),
          status: 'pending',
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Commande envoyée avec succès')),
      );
      
      setState(() {
        _selectedItems.clear();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
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
                        Text(_error!, style: TextStyle(color: Colors.red)),
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
 
