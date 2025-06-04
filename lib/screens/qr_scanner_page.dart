import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'dart:io';
import 'package:permission_handler/permission_handler.dart';
import 'order_screen.dart';

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  String result = 'Scannez le QR code de votre table';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _requestCameraPermission();
  }

  Future<void> _requestCameraPermission() async {
    final status = await Permission.camera.request();
    if (status.isDenied) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('La permission de la caméra est nécessaire pour scanner'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller?.pauseCamera();
    } else if (Platform.isIOS) {
      controller?.resumeCamera();
    }
  }

  bool _isValidTableQRCode(String code) {
    // Vérifie si le QR code correspond au format attendu
    // Par exemple: "TABLE_123" ou un format similaire
    return code.startsWith('TABLE_') && code.length > 6;
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) async {
      if (_isProcessing) return; // Évite le traitement multiple
      _isProcessing = true;

      final code = scanData.code;
      if (code == null || code.isEmpty) {
        setState(() {
          result = 'QR code invalide, veuillez réessayer';
          _isProcessing = false;
        });
        return;
      }

      if (!_isValidTableQRCode(code)) {
        setState(() {
          result = 'Ce QR code n\'est pas valide pour une table';
          _isProcessing = false;
        });
        return;
      }

      // Extrait le numéro de table du QR code
      final tableNumber = code.substring(6); // Enlève 'TABLE_'

      setState(() {
        result = 'Table trouvée: $tableNumber';
      });

      // Pause la caméra avant la navigation
      await controller.pauseCamera();

      if (!mounted) return;
      
      // Navigation vers l'écran de commande
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => OrderScreen(tableNumber: tableNumber),
        ),
      );

      // Reprend la caméra après le retour à cette page
      await controller.resumeCamera();
      _isProcessing = false;
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de Table'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 5,
            child: QRView(
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
          ),
          Expanded(
            flex: 1,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  result,
                  style: const TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 