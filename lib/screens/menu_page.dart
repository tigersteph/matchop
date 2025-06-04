import 'package:flutter/material.dart';
import 'package:resto/models/menu.dart';

class MenuPage extends StatelessWidget {
  final String restaurantId;

  const MenuPage({
    super.key,
    required this.restaurantId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Menu du Restaurant'),
      ),
      body: FutureBuilder<Menu>(
        future: Menu.fetchMenu(restaurantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 48),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                ],
              ),
            );
          }

          final menu = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: menu.categories.length,
            itemBuilder: (context, index) {
              final category = menu.categories[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: category.items.length,
                      itemBuilder: (context, itemIndex) {
                        final item = category.items[itemIndex];
                        return ListTile(
                          title: Text(item.name),
                          subtitle: Text(item.description),
                          trailing: Text(
                            '${item.price.toStringAsFixed(2)} €',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}
