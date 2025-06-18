import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:resto/widgets/restaurant_card.dart';
import 'package:resto/models/restaurant.dart';
import 'package:resto/screens/qr_scanner_page.dart';
import 'package:resto/screens/firebase_test_page.dart';
import 'package:resto/screens/menu_test_page.dart';
import 'package:resto/screens/order_management_screen.dart';
import 'package:resto/screens/login_screen.dart';
import 'package:resto/screens/staff_management_screen.dart';
import '../services/auth_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _isLoading = false;
  String? _error;

  Future<void> _navigateToOrderManagement() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
    final authService = Provider.of<AuthService>(context, listen: false);
    final user = authService.currentUser;

    if (user == null) {
      // L'utilisateur n'est pas connecté, rediriger vers la page de connexion
        if (!mounted) return;
      _navigateToPage(
        const LoginScreen(destinationPage: OrderManagementScreen()),
      );
        return;
      }

      // Vérifier si l'utilisateur est un membre du personnel
      final isStaff = await authService.isStaffMember();
      if (!mounted) return;

      if (isStaff) {
        _navigateToPage(const OrderManagementScreen());
      } else {
        _showError('Accès non autorisé. Contactez un administrateur.');
      }
    } catch (e) {
      _showError('Erreur lors de la vérification des permissions: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _navigateToPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => page,
      ),
    );
  }

  void _showError(String message) {
    setState(() {
      _error = message;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resto'),
        centerTitle: true,
        elevation: 2,
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
                  ),
                ),
              ),
            )
          else ...[
            _buildActionButton(
              icon: Icons.qr_code_scanner,
              tooltip: 'Scanner un QR code',
              onPressed: () => _navigateToPage(const QRScannerPage()),
            ),
            _buildActionButton(
              icon: Icons.cloud,
              tooltip: 'Tests Firebase',
              onPressed: () => _navigateToPage(const FirebaseTestPage()),
            ),
            _buildActionButton(
              icon: Icons.restaurant_menu,
              tooltip: 'Tests Menu',
              onPressed: () => _navigateToPage(const MenuTestPage()),
            ),
            _buildActionButton(
              icon: Icons.receipt_long,
              tooltip: 'Gestion des commandes',
              onPressed: _navigateToOrderManagement,
            ),
            _buildActionButton(
              icon: Icons.people,
              tooltip: 'Gestion du personnel',
              onPressed: () => _navigateToPage(const StaffManagementScreen()),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              color: theme.colorScheme.error.withValues(alpha: 26), // 26 = 0.1 * 255
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(() => _error = null),
                    color: theme.colorScheme.error,
                  ),
                ],
              ),
            ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                // Recharger les données ici si nécessaire
              },
              child: ListView.builder(
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
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon),
      tooltip: tooltip,
      onPressed: onPressed,
    );
  }
}