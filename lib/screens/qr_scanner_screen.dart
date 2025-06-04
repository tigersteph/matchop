import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'menu_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _hasPermission = false;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    final status = await Permission.camera.request();
    setState(() {
      _hasPermission = status.isGranted;
    });
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isProcessing) {
        setState(() {
          _isProcessing = true;
        });
        controller.pauseCamera();
        _processQRCode(scanData.code!);
      }
    });
  }

  bool _isValidTableFormat(String tableNumber) {
    final RegExp tableFormat = RegExp(r'^TABLE_\d+$', caseSensitive: false);
    return tableFormat.hasMatch(tableNumber);
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
    setState(() {
      _isProcessing = false;
    });
    controller?.resumeCamera();
  }

  void _processQRCode(String code) {
    try {
      // Format attendu: "TABLE_XXX:restaurant_id"
      final parts = code.split(':');
      if (parts.length != 2) {
        _showError('Format du QR code invalide');
        return;
      }

      final tableNumber = parts[0];
      final restaurantId = parts[1];

      if (!_isValidTableFormat(tableNumber)) {
        _showError('Numéro de table invalide. Format attendu: TABLE_XXX');
        return;
      }

      if (restaurantId.isEmpty) {
        _showError('Identifiant du restaurant manquant');
        return;
      }

      // Extraire le numéro de table sans le préfixe
      final cleanTableNumber = tableNumber.split('_')[1];

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            tableNumber: cleanTableNumber,
            restaurantId: restaurantId,
          ),
        ),
      );
    } catch (e) {
      _showError('Erreur lors du traitement du QR code');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasPermission) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 16),
              const Text(
                'Accès à la caméra requis',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Pour scanner le QR code de votre table,\nl\'application a besoin d\'accéder à la caméra.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.security),
                label: const Text('Autoriser l\'accès'),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de table'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: Colors.green,
                    borderRadius: 10,
                    borderLength: 30,
                    borderWidth: 10,
                    cutOutSize: 300,
                  ),
                ),
                if (_isProcessing)
                  Container(
                    color: Colors.black54,
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scannez le QR code sur votre table',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Placez le QR code au centre du cadre\npour accéder au menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}
