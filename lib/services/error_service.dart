import 'package:flutter/material.dart';

class ErrorService {
  static void logError(dynamic error, [StackTrace? stackTrace]) {
    debugPrint('Error: $error');
    if (stackTrace != null) {
      debugPrint('Stack trace: $stackTrace');
    }
  }

  static Future<void> reportError(BuildContext context, dynamic error, {String? message}) {
    logError(error);
    
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Erreur'),
        content: Text(message ?? 'Une erreur est survenue. Veuillez réessayer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
