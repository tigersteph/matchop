class QRCodeData {
  final String restaurantId;
  final String restaurantName;
  final String menuId;
  final String tableName;
  final DateTime timestamp;

  QRCodeData({
    required this.restaurantId,
    required this.restaurantName,
    required this.menuId,
    required this.tableName,
    required this.timestamp,
  });

  String toQRString() => 'RESTAURANT:$restaurantId:TABLE:$tableName:MENU:$menuId';

  factory QRCodeData.fromQRString(String qrString) {
    try {
      print('Raw QR code string: $qrString');
      
      // Nettoyer la chaîne en enlevant les espaces et les retours à la ligne
      final cleanedString = qrString.trim().replaceAll(RegExp(r'\s+'), '');
      print('Cleaned QR code string: $cleanedString');
      
      final parts = cleanedString.split(':');
      print('QR code parts: $parts');
      
      // Validation plus permissive
      if (parts.length < 6) {
        print('Error: Not enough parts in QR code');
        throw FormatException('Format QR code invalide: Pas assez de parties');
      }
      
      // Vérifier les clés de manière plus flexible
      if (!parts[0].toUpperCase().contains('RESTAURANT')) {
        print('Error: Missing RESTAURANT keyword');
        throw FormatException('Format QR code invalide: Clé RESTAURANT manquante');
      }
      if (!parts[2].toUpperCase().contains('TABLE')) {
        print('Error: Missing TABLE keyword');
        throw FormatException('Format QR code invalide: Clé TABLE manquante');
      }
      if (!parts[4].toUpperCase().contains('MENU')) {
        print('Error: Missing MENU keyword');
        throw FormatException('Format QR code invalide: Clé MENU manquante');
      }

      // Extraire les valeurs
      final restaurantId = parts[1].trim();
      final tableName = parts[3].trim();
      final menuId = parts[5].trim();
      
      print('Parsed values: restaurantId=$restaurantId, tableName=$tableName, menuId=$menuId');

      return QRCodeData(
        restaurantId: restaurantId,
        restaurantName: '', // À récupérer depuis Firebase
        menuId: menuId,
        tableName: tableName,
        timestamp: DateTime.now(),
      );
    } catch (e) {
      throw FormatException('Erreur de parsing du QR code: $e');
    }
  }

  @override
  String toString() => 'QRCodeData{restaurantId: $restaurantId, tableName: $tableName, menuId: $menuId, timestamp: $timestamp}';
}
