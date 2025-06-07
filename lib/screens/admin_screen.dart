import 'package:flutter/material.dart';
import '../utils/database_seeder.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({Key? key}) : super(key: key);

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  Future<void> _initializeDatabase() async {
    try {
      final seeder = DatabaseSeeder(restaurantId: 'resto-e9414');
      await seeder.seedAll();
      _showMessage('Données ajoutées avec succès !', false);
    } catch (e) {
      _showMessage('Erreur: $e', true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Administration'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _initializeDatabase,
              child: const Text('Initialiser la base de données'),
            ),
          ],
        ),
      ),
    );
  }
}
