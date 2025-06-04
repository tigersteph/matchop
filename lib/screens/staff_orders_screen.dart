import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/order.dart' as app_models;
import '../services/auth_service.dart';

class StaffOrdersScreen extends StatefulWidget {
  const StaffOrdersScreen({Key? key}) : super(key: key);

  @override
  State<StaffOrdersScreen> createState() => _StaffOrdersScreenState();
}

class _StaffOrdersScreenState extends State<StaffOrdersScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Commandes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'En préparation'),
              Tab(text: 'Terminées'),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () async {
                await _authService.signOut();
                if (!mounted) return;
                Navigator.of(context).pushReplacementNamed('/login');
              },
            ),
          ],
        ),
        body: TabBarView(
          children: [
            _buildOrdersList('pending'),
            _buildOrdersList('preparing'),
            _buildOrdersList('completed'),
          ],
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
          return Center(child: Text('Erreur: ${snapshot.error}'));
        }

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final orders = snapshot.data?.docs ?? [];
        if (orders.isEmpty) {
          return const Center(child: Text('Aucune commande'));
        }

        return ListView.builder(
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final orderData = orders[index].data() as Map<String, dynamic>;
            final order =app_models.Order.fromJson({...orderData, 'id': orders[index].id});
            final timeAgo = _getTimeAgo(order.timestamp);

            return Card(
              margin: const EdgeInsets.all(8.0),
              child: ExpansionTile(
                title: Text('Table ${order.tableNumber}'),
                subtitle: Text('$timeAgo - ${_formatTotal(order)} €'),
                leading: _getStatusIcon(order.status),
                children: [
                  ...order.items.map((item) => ListTile(
                        title: Text(item.name),
                        trailing: Text('${item.quantity}x - ${item.price}€'),
                      )),
                  if (status != 'completed')
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (status == 'pending')
                            ElevatedButton.icon(
                              icon: const Icon(Icons.restaurant),
                              label: const Text('Préparer'),
                              onPressed: () => _updateOrderStatus(order.id, 'preparing'),
                            ),
                          if (status == 'preparing')
                            ElevatedButton.icon(
                              icon: const Icon(Icons.check_circle),
                              label: const Text('Terminer'),
                              onPressed: () => _updateOrderStatus(order.id, 'completed'),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String orderId, String newStatus) async {
    try {
      await _firestore.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de la commande mis à jour'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return 'Il y a ${difference.inMinutes} min';
    } else if (difference.inHours < 24) {
      return 'Il y a ${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute}';
    }
  }

  String _formatTotal(app_models.Order order) {
    final total = order.items.fold(
      0.0,
      (sum, item) => sum + (item.price * item.quantity),
    );
    return total.toStringAsFixed(2);
  }

  Widget _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return const Icon(Icons.access_time, color: Colors.orange);
      case 'preparing':
        return const Icon(Icons.restaurant, color: Colors.blue);
      case 'completed':
        return const Icon(Icons.check_circle, color: Colors.green);
      default:
        return const Icon(Icons.error);
    }
  }
} 