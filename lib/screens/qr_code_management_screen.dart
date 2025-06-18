import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'dart:io';
import '../models/qr_code_data.dart';
import '../services/qr_generator_service.dart';
import '../services/logging_service.dart';

class QRCodeManagementScreen extends StatefulWidget {
  const QRCodeManagementScreen({super.key});

  @override
  State<QRCodeManagementScreen> createState() => _QRCodeManagementScreenState();
}

class _QRCodeManagementScreenState extends State<QRCodeManagementScreen> {
  final _formKey = GlobalKey<FormState>();
  final _restaurantIdController = TextEditingController();
  final _menuIdController = TextEditingController();
  final _tableNumberController = TextEditingController();
  bool _isLoading = false;
  final List<QRCodeData> _generatedQRs = []; // Rendue finale car immutable après création

  @override
  void dispose() {
    _restaurantIdController.dispose();
    _menuIdController.dispose();
    _tableNumberController.dispose();
    super.dispose();
  }

  Future<void> _generateQRCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final qrGenerator = context.read<QRGeneratorService>();

      final restaurantId = _restaurantIdController.text;
      final menuId = _menuIdController.text;
      final tableNumber = _tableNumberController.text;

      // Vérifier si le restaurant existe
      final restaurantDoc = await FirebaseFirestore.instance
          .collection('restaurants')
          .doc(restaurantId)
          .get();

      if (!restaurantDoc.exists) {
        throw Exception('Restaurant non trouvé');
      }

      // Générer le QR code
      final qrData = QRCodeData(
        restaurantId: restaurantId,
        restaurantName: restaurantDoc.data()!['name'] ?? '',
        menuId: menuId,
        tableName: 'TABLE_$tableNumber',
        timestamp: DateTime.now(),
      );

      await qrGenerator.generateQRCode(restaurantId, tableNumber);

      setState(() {
        _generatedQRs.add(qrData);
        _isLoading = false;
      });

      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('QR code généré pour la table $tableNumber'),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      LoggingService.error('Erreur de génération QR code', error: e);
      if (mounted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erreur: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestion des QR codes'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _restaurantIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID du Restaurant',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer l\'ID du restaurant';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _menuIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID du Menu',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer l\'ID du menu';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _tableNumberController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de Table',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un numéro de table';
                      }
                      if (!RegExp(r'^\d+$').hasMatch(value)) {
                        return 'Le numéro de table doit être un nombre';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _generateQRCode,
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('Générer QR code'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Expanded(
              child: ListView.builder(
                itemCount: _generatedQRs.length,
                itemBuilder: (context, index) {
                  final qr = _generatedQRs[index];
                  return Card(
                    child: ListTile(
                      title: Text('Table ${qr.tableName}'),
                      subtitle: Text(
                        'Restaurant: ${qr.restaurantId}\nMenu: ${qr.menuId}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.download),
                        onPressed: () async {
                          try {
                            final qrGenerator = context.read<QRGeneratorService>();

                            final filePath = await qrGenerator.generateQRCode(
                              qr.restaurantId,
                              qr.tableName,
                            );
                            
                            // Ouvrir le fichier avec le gestionnaire de fichiers système
                            final file = File(filePath);
                            if (await file.exists()) {
                              if (await launcher.canLaunchUrl(Uri.parse('file://$filePath'))) {
                              await launcher.launchUrl(Uri.parse('file://$filePath'));
                            } else {
                              throw Exception('Impossible d\'ouvrir le fichier');
                            }
                            } else {
                              throw Exception('Le fichier QR code n\'existe pas');
                            }
                          } catch (e) {
                            if (mounted && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('Erreur lors du téléchargement: $e'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
