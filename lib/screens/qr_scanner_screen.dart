import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/logging_service.dart';
import 'menu_screen.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController? controller;
  bool _hasPermission = false;
  bool _isProcessing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
    _checkPermission();
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.request();
      if (!mounted) return;
      setState(() {
        _hasPermission = status.isGranted;
        _error = status.isDenied ? 'Permission refusée' : null;
      });
    } catch (e) {
      LoggingService.error('Erreur de permission', error: e);
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors de la vérification des permissions: $e';
      });
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    setState(() {
      _error = message;
      _isProcessing = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            if (!mounted) return;
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  void _processQRCode(String code) {
    try {
      final parts = code.split(':');
      if (parts.length != 2) {
        _showError('Format du QR code invalide');
        return;
      }

      final tableNumber = parts[0];
      final restaurantId = parts[1];
      
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            tableNumber: tableNumber,
            restaurantId: restaurantId,
          ),
        ),
      );
    } catch (e) {
      LoggingService.error('Erreur de traitement QR code', error: e);
      if (!mounted) return;
      setState(() {
        _error = 'Erreur lors du traitement du QR code: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner QR Code'),
      ),
      body: Container(
        color: Colors.white,
        child: Column(
          children: [
            if (!_hasPermission) ...[
              const Expanded(
                flex: 1,
                child: Center(
                  child: Text(
                    'Permission de caméra requise',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
              Expanded(
                flex: 1,
                child: ElevatedButton(
                  onPressed: _checkPermission,
                  child: const Text('Demander la permission'),
                ),
              ),
            ] else ...[
              if (controller != null) ...[
                Expanded(
                  flex: 5,
                  child: MobileScanner(
                    key: qrKey,
                    controller: controller!,
                    onDetect: (capture) {
                      if (!_isProcessing && capture.barcodes.isNotEmpty) {
                        if (!mounted) return;
                        setState(() {
                          _isProcessing = true;
                          _error = null;
                        });
                        controller?.stop();
                        _processQRCode(capture.barcodes.first.rawValue!);
                      }
                    },
                    errorBuilder: (context, error, child) {
                      return Center(
                        child: Text('Erreur de lecture: ${error.toString()}'),
                      );
                    },
                  ),
                ),
              ],
              if (_error != null) ...<Widget>[
                Expanded(
                  flex: 1,
                  child: Center(
                    child: Text(
                      _error!,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: () {
                      if (!mounted) return;
                      setState(() {
                        _error = null;
                      });
                      controller?.start();
                    },
                    child: const Text('Réessayer'),
                  ),
                ),
              ] else ...<Widget>[
                const Expanded(
                  flex: 1,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text(
                        'Pointez votre caméra sur un QR code',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  flex: 1,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.flash_off, color: Colors.grey, size: 24),
                      IconButton(
                        icon: const Icon(Icons.flash_off),
                        onPressed: () {
                          _showError('Le flash n\'est pas disponible');
                        },
                      ),
                    ],
                  ),
                ),
              ]
            ]
          ],
        ),
      ),
    );
  }



  @override
  void dispose() {
    controller?.stop();
    controller?.dispose();
    super.dispose();
  }
}