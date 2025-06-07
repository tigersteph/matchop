import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_models;
import '../services/auth_service.dart';

enum OrderStatus {
  pending('En attente', Icons.access_time, Colors.orange),
  preparing('En préparation', Icons.restaurant, Colors.blue),
  completed('Terminées', Icons.check_circle, Colors.green);

  const OrderStatus(this.label, this.icon, this.color);
  
  final String label;
  final IconData icon;
  final Color color;
}

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({super.key});

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> with SingleTickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();
  late TabController _tabController;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: OrderStatus.values.length, vsync: this);
    _tabController.addListener(_handleTabChange);
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {}); // Rafraîchir l'interface
    }
  }

  Future<void> _handleLogout() async {
    setState(() => _isLoading = true);
    
    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      _showErrorSnackBar('Erreur lors de la déconnexion: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
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
    final theme = Theme.of(context);
    
    return DefaultTabController(
      length: OrderStatus.values.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Commandes'),
          bottom: TabBar(
            controller: _tabController,
            tabs: OrderStatus.values.map((status) => Tab(
              icon: Icon(status.icon),
              text: status.label,
            )).toList(),
            indicatorColor: theme.colorScheme.secondary,
            labelColor: theme.colorScheme.primary,
          ),
          actions: [
            if (_isLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                ),
              )
            else
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Déconnexion',
                onPressed: _handleLogout,
              ),
          ],
        ),
        body: TabBarView(
          controller: _tabController,
          children: OrderStatus.values.map((status) => 
            _buildOrdersList(status.name)
          ).toList(),
        ),
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur: ${snapshot.error}',
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          );
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getStatusIcon(status).icon,
                  size: 48,
                  color: Colors.grey,
                ),
                const SizedBox(height: 16),
                Text(
                  'Aucune commande ${_getStatusLabel(status)}',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {}); // Forcer le rafraîchissement
          },
          child: ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final orderData = orders[index].data() as Map<String, dynamic>;
              final order = app_models.Order.fromJson({...orderData, 'id': orders[index].id});
              final timeAgo = _getTimeAgo(order.timestamp);

              return Card(
                margin: const EdgeInsets.only(bottom: 8),
                elevation: 2,
                child: ExpansionTile(
                  title: Text(
                    'Table ${order.tableNumber}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    '$timeAgo - ${_formatTotal(order)} €',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.bodySmall?.color,
                    ),
                  ),
                  leading: _getStatusIcon(order.status),
                  children: [
                    const Divider(height: 1),
                    ...order.items.map((item) => ListTile(
                      title: Text(
                        item.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: Text(
                        '${item.quantity}x - ${item.price}€',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      dense: true,
                    )),
                    if (status != OrderStatus.completed.name)
                      Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (status == OrderStatus.pending.name)
                              _buildActionButton(
                                icon: Icons.restaurant,
                                label: 'Préparer',
                                color: Colors.blue,
                                onPressed: () => _updateOrderStatus(
                                  order.id,
                                  OrderStatus.preparing.name,
                                ),
                              ),
                            if (status == OrderStatus.preparing.name)
                              _buildActionButton(
                                icon: Icons.check_circle,
                                label: 'Terminer',
                                color: Colors.green,
                                onPressed: () => _updateOrderStatus(
                                  order.id,
                                  OrderStatus.completed.name,
                                ),
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: color,
        padding: const EdgeInsets.symmetric(
          horizontal: 24,
          vertical: 12,
        ),
      ),
      onPressed: onPressed,
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    setState(() => _isLoading = true);
    
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      _showSuccessSnackBar('Statut de la commande mis à jour');
    } catch (e) {
      _showErrorSnackBar('Erreur: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      final minutes = difference.inMinutes;
      return 'Il y a $minutes ${minutes == 1 ? 'minute' : 'minutes'}';
    } else if (difference.inHours < 24) {
      final hours = difference.inHours;
      return 'Il y a $hours ${hours == 1 ? 'heure' : 'heures'}';
    } else {
      return '${_padZero(dateTime.day)}/${_padZero(dateTime.month)} ${_padZero(dateTime.hour)}:${_padZero(dateTime.minute)}';
    }
  }

  String _padZero(int number) {
    return number.toString().padLeft(2, '0');
  }

  String _formatTotal(app_models.Order order) {
    final total = order.items.fold(
      0.0,
      (total, item) => total + (item.price * item.quantity),
    );
    return total.toStringAsFixed(2);
  }

  Icon _getStatusIcon(String status) {
    final orderStatus = OrderStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => OrderStatus.pending,
    );
    return Icon(orderStatus.icon, color: orderStatus.color);
  }

  String _getStatusLabel(String status) {
    final orderStatus = OrderStatus.values.firstWhere(
      (s) => s.name == status,
      orElse: () => OrderStatus.pending,
    );
    return orderStatus.label.toLowerCase();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 