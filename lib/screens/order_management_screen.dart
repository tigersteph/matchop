import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order.dart';
import '../services/order_service.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 4,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Gestion des Commandes'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'En attente'),
              Tab(text: 'En préparation'),
              Tab(text: 'Prêtes'),
              Tab(text: 'Servies'),
            ],
          ),
        ),
        body: StreamBuilder<List<Order>>(
          stream: Provider.of<OrderService>(context).ordersStream,
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text('Erreur: ${snapshot.error}'));
            }

            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final orders = snapshot.data!;
            final pendingOrders = orders.where((o) => o.status == 'pending').toList();
            final preparingOrders = orders.where((o) => o.status == 'preparing').toList();
            final readyOrders = orders.where((o) => o.status == 'ready').toList();
            final servedOrders = orders.where((o) => o.status == 'served').toList();

            return TabBarView(
              children: [
                _buildOrderList(context, pendingOrders, 'preparing'),
                _buildOrderList(context, preparingOrders, 'ready'),
                _buildOrderList(context, readyOrders, 'served'),
                _buildOrderList(context, servedOrders, null),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildOrderList(BuildContext context, List<Order> orders, String? nextStatus) {
    if (orders.isEmpty) {
      return const Center(child: Text('Aucune commande'));
    }

    return ListView.builder(
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return Card(
          margin: const EdgeInsets.all(8),
          child: ExpansionTile(
            title: Text('Table ${order.tableNumber}'),
            subtitle: Text(
              'Total: ${order.totalAmount.toStringAsFixed(2)}€\n'
              '${order.timestamp.hour}:${order.timestamp.minute}',
            ),
            children: [
              ...order.items.map((item) => ListTile(
                    title: Text(item.name),
                    trailing: Text('${item.quantity}x'),
                    subtitle: item.specialInstructions != null
                        ? Text('Note: ${item.specialInstructions}')
                        : null,
                  )),
              if (nextStatus != null)
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ElevatedButton(
                    onPressed: () {
                      Provider.of<OrderService>(context, listen: false)
                          .updateOrderStatus(order.id, nextStatus);
                    },
                    child: Text(
                      nextStatus == 'preparing'
                          ? 'Commencer la préparation'
                          : nextStatus == 'ready'
                              ? 'Marquer comme prêt'
                              : 'Marquer comme servi',
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
