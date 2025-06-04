import 'package:flutter/material.dart';
import 'package:resto/widgets/restaurant_card.dart';
import 'package:resto/models/restaurant.dart';
import 'package:resto/screens/qr_scanner_page.dart';
import 'package:resto/screens/firebase_test_page.dart';
import 'package:resto/screens/menu_test_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resto'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () => _navigateToPage(context, const QRScannerPage()),
          ),
          IconButton(
            icon: const Icon(Icons.cloud),
            onPressed: () => _navigateToPage(context, const FirebaseTestPage()),
          ),
          IconButton(
            icon: const Icon(Icons.restaurant_menu),
            onPressed: () => _navigateToPage(context, const MenuTestPage()),
          ),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: Restaurant.sampleData.length,
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: RestaurantCard(
              restaurant: Restaurant.sampleData[index],
            ),
          );
        },
      ),
    );
  }
}
