import 'package:firebase_app_check/firebase_app_check.dart';
import 'logging_service.dart';

class AppCheckService {
  static Future<void> initialize() async {
    try {
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider('6LfuWFgrAAAAAGhwEhhsgHjfa7cQsuejWSKGBITF'), // Clé de test reCAPTCHA v3
        androidProvider: AndroidProvider.debug,
        appleProvider: AppleProvider.debug, // Optionnel pour iOS
      );
    } catch (e) {
      LoggingService.error('Erreur lors de l\'initialisation de Firebase App Check', error: e);
    }
  }
}