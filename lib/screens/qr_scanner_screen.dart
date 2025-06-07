import 'package:flutter/material.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'menu_screen.dart';
import '../services/dynamic_link_service.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}

class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool _hasPermission = false;
  bool _isProcessing = false;
  String? _error;
  bool _isFlashOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    try {
      final status = await Permission.camera.request();
      setState(() {
        _hasPermission = status.isGranted;
        _error = status.isDenied ? 'Permission refusée' : null;
      });
    } catch (e) {
      setState(() {
        _error = 'Erreur lors de la vérification des permissions: $e';
      });
    }
  }

  void _onQRViewCreated(QRViewController controller) {
    this.controller = controller;
    controller.scannedDataStream.listen((scanData) {
      if (scanData.code != null && !_isProcessing) {
        setState(() {
          _isProcessing = true;
          _error = null;
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
    controller?.resumeCamera();
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

      if (!_isValidTableFormat(tableNumber)) {
        _showError('Numéro de table invalide. Format attendu: TABLE_XXX');
        return;
      }

      if (restaurantId.isEmpty) {
        _showError('Identifiant du restaurant manquant');
        return;
      }

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
      _showError('Erreur lors du traitement du QR code: $e');
    }
  }

  Future<void> _toggleFlash() async {
    try {
      await controller?.toggleFlash();
      final isFlashOn = await controller?.getFlashStatus() ?? false;
      setState(() {
        _isFlashOn = isFlashOn;
      });
    } catch (e) {
      _showError('Erreur lors de l\'activation du flash');
    }
  }

  void _showInfoDialog(BuildContext context) {
    final theme = Theme.of(context);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Comment scanner un QR code',
            style: theme.textTheme.titleLarge,
          ),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('1. Placez le QR code dans le cadre de scan',
                    style: theme.textTheme.bodyMedium),
                Text('2. Maintenez stable jusqu\'à ce que le scan se complète',
                    style: theme.textTheme.bodyMedium),
                Text('3. Le menu de la table s\'affichera automatiquement',
                    style: theme.textTheme.bodyMedium),
                const SizedBox(height: 16),
                Text('Si vous rencontrez des problèmes :',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
                Text('- Vérifiez que la caméra n\'est pas obstruée',
                    style: theme.textTheme.bodyMedium),
                Text('- Assurez-vous d\'avoir un bon éclairage',
                    style: theme.textTheme.bodyMedium),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text(
                'OK',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                ),
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (!_hasPermission) {
      return _buildPermissionRequest();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Scanner de table'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: _toggleFlash,
            tooltip: 'Activer/désactiver le flash',
          ),
          IconButton(
            icon: const Icon(Icons.info_outline),
            onPressed: () => _showInfoDialog(context),
          ),
          IconButton(
            icon: const Icon(Icons.bug_report),
            onPressed: () {
              FirebaseCrashlytics.instance.crash();
            },
          ),
          IconButton(
            icon: const Icon(Icons.link),
            onPressed: () async {
              final dynamicLinkService = Provider.of<DynamicLinkService>(context, listen: false);
              final link = await dynamicLinkService.createLink('123', '456');
              
              if (!mounted) return;
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Lien généré: $link'),
                  action: SnackBarAction(
                    label: 'Copier',
                    onPressed: () {
                      if (!mounted) return;
                      Clipboard.setData(ClipboardData(text: link));
                    },
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          if (_error != null)
            Container(
              color: theme.colorScheme.error.withAlpha(26),
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: theme.colorScheme.error.withAlpha(255)),
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
            flex: 5,
            child: Stack(
              children: [
                QRView(
                  key: qrKey,
                  onQRViewCreated: _onQRViewCreated,
                  overlay: QrScannerOverlayShape(
                    borderColor: theme.colorScheme.primary,
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
            color: theme.cardColor,
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
                Text(
                  'Placez le QR code au centre du cadre\npour accéder au menu',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withAlpha(153),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionRequest() {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.camera_alt,
                size: 64,
                color: Colors.grey,
              ),
              const SizedBox(height: 24),
              const Text(
                'Accès à la caméra requis',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Pour scanner le QR code de votre table,\nl\'application a besoin d\'accéder à la caméra.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _checkPermission,
                icon: const Icon(Icons.security),
                label: const Text('Autoriser l\'accès'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    controller?.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }
}