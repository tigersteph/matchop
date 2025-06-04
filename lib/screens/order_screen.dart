import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order.dart';
import '../services/order_service.dart';
import '../widgets/add_order_item_dialog.dart';

class OrderScreen extends StatefulWidget {
  final String tableNumber;

  const OrderScreen({
    Key? key,
    required this.tableNumber,
  }) : super(key: key);

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  Timer? _resetTimer;
  final List<OrderItem> _items = [];
  bool _orderSubmitted = false;
  int _remainingSeconds = 300; // 5 minutes en secondes

  @override
  void initState() {
    super.initState();
    _startResetTimer();
  }

  @override
  void dispose() {
    _resetTimer?.cancel();
    super.dispose();
  }

  void _startResetTimer() {
    _resetTimer?.cancel();
    setState(() {
      _remainingSeconds = 300;
    });
    
    _resetTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingSeconds > 0) {
          _remainingSeconds--;
        } else {
          timer.cancel();
          if (mounted && _orderSubmitted) {
            Navigator.of(context).pop();
          }
        }
      });
    });
  }

  void _resetTimerOnAction() {
    if (!_orderSubmitted) {
      _startResetTimer();
    }
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> _submitOrder() async {
    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez ajouter des articles à votre commande'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final order = Order(
        id: '',
        tableNumber: widget.tableNumber,
        items: _items,
        status: 'pending',
        timestamp: DateTime.now(),
      );

      final orderService = OrderService();
      await orderService.submitOrder(order);

      setState(() {
        _orderSubmitted = true;
      });

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commande envoyée avec succès!'),
          backgroundColor: Colors.green,
        ),
      );

      _startResetTimer();

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur lors de l\'envoi de la commande: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Map<MenuCategory, List<OrderItem>> _groupItemsByCategory() {
    final groupedItems = <MenuCategory, List<OrderItem>>{};
    for (final category in MenuCategory.values) {
      groupedItems[category] = _items
          .where((item) => item.category == category)
          .toList();
    }
    return groupedItems;
  }

  String _getCategoryLabel(MenuCategory category) {
    switch (category) {
      case MenuCategory.entree:
        return 'Entrées';
      case MenuCategory.plat:
        return 'Plats';
      case MenuCategory.dessert:
        return 'Desserts';
      case MenuCategory.boisson:
        return 'Boissons';
    }
  }

  double _calculateTotal() {
    return _items.fold(0, (total, item) => total + (item.price * item.quantity));
  }

  void _addItem(OrderItem item) {
    setState(() {
      _items.add(item);
    });
    _resetTimerOnAction();
  }

  void _removeItem(int index) {
    setState(() {
      _items.removeAt(index);
    });
    _resetTimerOnAction();
  }

  Future<void> _showAddItemDialog() async {
    final result = await showDialog<OrderItem>(
      context: context,
      builder: (context) => const AddOrderItemDialog(),
    );

    if (result != null) {
      _addItem(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupedItems = _groupItemsByCategory();

    return GestureDetector(
      onTap: _resetTimerOnAction,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Commande - Table ${widget.tableNumber}'),
          actions: [
            if (_orderSubmitted)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text(
                        'Commande validée - ',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _formatDuration(_remainingSeconds),
                        style: const TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: ListView(
                children: [
                  for (final category in MenuCategory.values)
                    if (groupedItems[category]!.isNotEmpty)
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              _getCategoryLabel(category),
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: groupedItems[category]!.length,
                            itemBuilder: (context, index) {
                              final item = groupedItems[category]![index];
                              return ListTile(
                                title: Text(item.name),
                                subtitle: Text('${item.price.toStringAsFixed(2)}€ x ${item.quantity}'),
                                trailing: _orderSubmitted
                                    ? null
                                    : IconButton(
                                        icon: const Icon(Icons.remove_circle_outline),
                                        onPressed: () => _removeItem(_items.indexOf(item)),
                                      ),
                              );
                            },
                          ),
                          const Divider(),
                        ],
                      ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    'Total: ${_calculateTotal().toStringAsFixed(2)}€',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_orderSubmitted)
                    ElevatedButton(
                      onPressed: _submitOrder,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Valider la commande'),
                    ),
                  if (_orderSubmitted)
                    Text(
                      'La page se fermera dans ${_formatDuration(_remainingSeconds)}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
        floatingActionButton: _orderSubmitted
            ? null
            : FloatingActionButton(
                onPressed: _showAddItemDialog,
                child: const Icon(Icons.add),
              ),
      ),
    );
  }
} 