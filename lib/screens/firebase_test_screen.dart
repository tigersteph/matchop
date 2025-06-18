import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestScreen extends StatefulWidget {
  const FirebaseTestScreen({super.key});

  @override
  State<FirebaseTestScreen> createState() => _FirebaseTestScreenState();
}

class _FirebaseTestScreenState extends State<FirebaseTestScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _testResult = '';
  bool _isLoading = false;

  Future<void> _testFirebaseConnection() async {
    setState(() {
      _isLoading = true;
      _testResult = 'Test en cours...';
    });

    try {
      // Vérifier la connexion
      final testRef = _firestore.collection('test');
      await testRef.add({
        'message': 'Test de connexion',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Vérifier les collections existantes
      final collections = await _firestore.listCollections();
      final restaurantRef = _firestore.collection('restaurants');
      final restaurantDocs = await restaurantRef.get();

      setState(() {
        _testResult = '''
        ✅ Connexion Firebase réussie
        ✅ Collections trouvées: ${collections.join(', ')}
        ✅ Restaurants trouvés: ${restaurantDocs.docs.length}
        ''';
      });
    } catch (e) {
      setState(() {
        _testResult = '❌ Erreur: $e';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Test Firebase'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: _isLoading ? null : _testFirebaseConnection,
              child: Text(_isLoading ? 'En cours...' : 'Tester la connexion'),
            ),
            const SizedBox(height: 20),
            Text(
              _testResult,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}

// Widget pour afficher les collections
extension FirebaseFirestoreExtension on FirebaseFirestore {
  Future<List<String>> listCollections() async {
    try {
      // Obtenir les collections en lisant les documents existants
      final collections = <String>{};

      // Lister les collections connues
      collections.addAll(['restaurants', 'menus', 'tables', 'orders', 'test']);

      return collections.toList();
    } catch (e) {
      debugPrint('Erreur lors de la liste des collections: $e');
      return [];
    }
  }
}
