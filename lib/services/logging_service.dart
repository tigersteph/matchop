import 'dart:developer' as developer;

class LoggingService {
  static void log(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'RestaurantApp');
  }

  static void error(String message, {String? tag, dynamic error}) {
    developer.log(
      message,
      name: tag ?? 'RestaurantApp',
      error: error,
      level: 1000,
    );
  }

  static void info(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'RestaurantApp', level: 1000);
  }

  static void warning(String message, {String? tag}) {
    developer.log(message, name: tag ?? 'RestaurantApp', level: 1000);
  }
}
