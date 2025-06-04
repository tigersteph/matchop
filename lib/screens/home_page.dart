import 'package:flutter/material.dart';
import 'package:resto/widgets/restaurant_card.dart';
import 'package:resto/models/restaurant.dart';
import 'package:resto/screens/qr_scanner_page.dart';
import 'package:resto/screens/firebase_test_page.dart';
import 'package:resto/screens/menu_test_page.dart';
import 'package:resto/screens/order_management_screen.dart';
import 'package:resto/screens/login_screen.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:resto/screens/staff_management_screen.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  void _navigateToPage(BuildContext context, Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  void _navigateToOrderManagement(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      // L'utilisateur n'est pas connecté, rediriger vers la page de connexion
      _navigateToPage(
        context,
        LoginScreen(destinationPage: const OrderManagementScreen()),
      );
    } else {
      // Vérifier si l'utilisateur est un membre du personnel
      final isStaff = await authService.isStaffMember();
      if (isStaff) {
        if (!context.mounted) return;
        _navigateToPage(context, const OrderManagementScreen());
      } else {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Accès non autorisé. Contactez un administrateur.'),
          ),
        );
      }
    }
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
          IconButton(
            icon: const Icon(Icons.receipt_long),
            onPressed: () => _navigateToOrderManagement(context),
          ),IconButton(
            icon: const Icon(Icons.people),
            onPressed: () => _navigateToPage(context, const StaffManagementScreen()),
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
