import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseTestPage extends StatelessWidget {
  const FirebaseTestPage({super.key});

  Future<void> _testFirebaseConnection(BuildContext context) async {
    try {
      // Référence à une collection de test
      final testCollection = FirebaseFirestore.instance.collection('test');
      
      // Essayer d'écrire des données
      await testCollection.add({
        'message': 'Test de connexion',
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Essayer de lire des données
      await testCollection.limit(1).get();
      
      if (!context.mounted) return;

      // Afficher un message de succès
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connexion Firebase réussie! ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      
      String errorMessage = 'Erreur de connexion';
      if (e is FirebaseException) {
        errorMessage = 'Erreur Firebase: ${e.message}';
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red,
        ),
      );
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
              onPressed: () => _testFirebaseConnection(context),
              child: const Text('Tester la connexion Firebase'),
            ),
            const SizedBox(height: 20),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('test').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Text('Erreur: ${snapshot.error}');
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircularProgressIndicator();
                }

                return Text(
                  'Nombre de documents dans la collection: ${snapshot.data?.docs.length ?? 0}',
                  style: Theme.of(context).textTheme.titleMedium,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
