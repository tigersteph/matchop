import 'dart:io';
import 'package:qr/qr.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'dart:ui' as ui; // Pour ImageByteFormat

class QRGeneratorService with ChangeNotifier {
  Future<String> generateQRCode(String restaurantId, String tableNumber) async {
    try {
      // Vérifier les permissions d'écriture
      final status = await Permission.storage.request();
      if (!status.isGranted) {
        throw Exception('Permission de stockage refusée');
      }

      // Créer le contenu du QR code
      final qrData = 'RESTAURANT:$restaurantId:TABLE:$tableNumber';

      // Générer le QR code
      final qrCode = QrCode.fromData(
        data: qrData,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );

      // Convertir en image
      final qrImage = QrImage(qrCode);
      final imageData = await _generateImageData(qrImage, 400, 400);

      // Sauvegarder l'image
      final directory = await getApplicationDocumentsDirectory();
      final filePath =
          '${directory.path}/qr_${restaurantId}_table_$tableNumber.png';
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de la génération du QR code: $e');
    }
  }

  Future<String> generateRestaurantQRCode(String restaurantId) async {
    try {
      // Générer un QR code pour le restaurant (sans numéro de table)
      final qrData = 'RESTAURANT:$restaurantId';

      // Générer le QR code
      final qrCode = QrCode.fromData(
        data: qrData,
        errorCorrectLevel: QrErrorCorrectLevel.H,
      );

      // Convertir en image
      final qrImage = QrImage(qrCode);
      final imageData = await _generateImageData(qrImage, 400, 400);

      // Sauvegarder l'image
      final directory = await getApplicationDocumentsDirectory();
      final filePath = '${directory.path}/qr_restaurant_$restaurantId.png';
      final file = File(filePath);
      await file.writeAsBytes(imageData);

      return filePath;
    } catch (e) {
      throw Exception('Erreur lors de la génération du QR code restaurant: $e');
    }
  }

  Future<Uint8List> _generateImageData(
      QrImage qrImage, int width, int height) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = Colors.black;

    // Dessiner le QR code
    for (int x = 0; x < qrImage.moduleCount; x++) {
      for (int y = 0; y < qrImage.moduleCount; y++) {
        if (qrImage.isDark(y, x)) {
          canvas.drawRect(
            Rect.fromLTWH(
              x * (width / qrImage.moduleCount),
              y * (height / qrImage.moduleCount),
              width / qrImage.moduleCount,
              height / qrImage.moduleCount,
            ),
            paint,
          );
        }
      }
    }

    final picture = recorder.endRecording();
    final image = await picture.toImage(width, height);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData!.buffer.asUint8List();
  }
}
