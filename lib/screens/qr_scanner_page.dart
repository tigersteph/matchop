import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:io';
import 'order_screen.dart';

class QRScannerOverlayPainter extends CustomPainter {
  final Color borderColor;
  final double borderRadius;
  final double borderLength;
  final double borderWidth;
  final double cutOutSize;

  QRScannerOverlayPainter({
    required this.borderColor,
    required this.borderRadius,
    required this.borderLength,
    required this.borderWidth,
    required this.cutOutSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth;

    final center = Offset(size.width / 2, size.height / 2);
    final rect = Rect.fromCenter(
      center: center,
      width: cutOutSize,
      height: cutOutSize,
    );

    // Dessine les coins
    final path = Path();
    path.moveTo(rect.left, rect.top);
    path.lineTo(rect.left + borderLength, rect.top);
    path.moveTo(rect.left, rect.top);
    path.lineTo(rect.left, rect.top + borderLength);

    path.moveTo(rect.right, rect.top);
    path.lineTo(rect.right - borderLength, rect.top);
    path.moveTo(rect.right, rect.top);
    path.lineTo(rect.right, rect.top + borderLength);

    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left + borderLength, rect.bottom);
    path.moveTo(rect.left, rect.bottom);
    path.lineTo(rect.left, rect.bottom - borderLength);

    path.moveTo(rect.right, rect.bottom);
    path.lineTo(rect.right - borderLength, rect.bottom);
    path.moveTo(rect.right, rect.bottom);
    path.lineTo(rect.right, rect.bottom - borderLength);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(QRScannerOverlayPainter oldDelegate) {
    return oldDelegate.borderColor != borderColor ||
        oldDelegate.borderRadius != borderRadius ||
        oldDelegate.borderLength != borderLength ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.cutOutSize != cutOutSize;
  }
}

class QRScannerPage extends StatefulWidget {
  const QRScannerPage({super.key});

  @override
  State<QRScannerPage> createState() => _QRScannerPageState();
}

class _QRScannerPageState extends State<QRScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  MobileScannerController? controller;
  String result = 'Scannez le QR code de votre table';
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    controller = MobileScannerController();
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
      controller?.stop();
    } else if (Platform.isIOS) {
      controller?.start();
    }
  }

  bool _isValidTableQRCode(String code) {
    // Vérifie si le QR code correspond au format attendu
    // Par exemple: "TABLE_123" ou un format similaire
    return code.startsWith('TABLE_') && code.length > 6;
  }

  void _onQRCodeDetected(BarcodeCapture capture) async {
    if (_isProcessing || capture.barcodes.isEmpty) return;
    _isProcessing = true;

    final code = capture.barcodes.first.rawValue;
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

    // Arrête le scanner avant la navigation
    await controller?.stop();

    if (!mounted) return;
    
    // Navigation vers l'écran de commande
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderScreen(tableNumber: tableNumber),
      ),
    );

    // Redémarre le scanner après le retour
    await controller?.start();
    _isProcessing = false;
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
            child: MobileScanner(
              key: qrKey,
              controller: controller!,
              onDetect: _onQRCodeDetected,
              errorBuilder: (context, error, child) {
                return Center(
                  child: Text('Erreur de lecture: ${error.toString()}'),
                );
              },
              overlay: CustomPaint(
                painter: QRScannerOverlayPainter(
                  borderColor: Colors.green,
                  borderRadius: 10,
                  borderLength: 30,
                  borderWidth: 10,
                  cutOutSize: 300,
                ),
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