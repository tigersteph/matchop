import 'dart:async';
import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import '../screens/menu_screen.dart';

class DynamicLinkService extends ChangeNotifier {
  static const String baseUrl = 'https://matchop.app.link';

  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  bool _isInitialized = false;
  bool get isInitialized => _isInitialized;

  DynamicLinkService() {
    _appLinks = AppLinks();
  }

  Future<void> initDynamicLinks(BuildContext context) async {
    if (_isInitialized) {
      debugPrint('DynamicLinkService déjà initialisé');
      return;
    }

    try {
      // Écouter les nouveaux liens
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          debugPrint('Nouveau lien reçu: ${uri.toString()}');
          if (context.mounted) {
            _handleLink(context, uri);
          }
        },
        onError: (error) {
          debugPrint('Erreur de lien dynamique: $error');
        },
      );

      // Gérer le lien initial
      try {
        final initialUri = await _appLinks.getInitialAppLink();
        if (initialUri != null && context.mounted) {
          debugPrint('Lien initial détecté: ${initialUri.toString()}');
          await Future.delayed(const Duration(milliseconds: 500));
          if (context.mounted) {
            _handleLink(context, initialUri);
          }
        }
      } catch (e) {
        debugPrint('Pas de lien initial: $e');
      }

      _isInitialized = true;
      debugPrint('DynamicLinkService initialisé avec succès');
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation: $e');
    }
  }

  void _handleLink(BuildContext context, Uri uri) {
    try {
      debugPrint('Traitement du lien: ${uri.toString()}');

      if (!_isValidDomain(uri)) {
        debugPrint('Domaine non autorisé: ${uri.host}');
        return;
      }

      final segments = uri.pathSegments;

      if (segments.length >= 2 && segments[0].toLowerCase() == 'table') {
        final tableNumber = segments[1].trim();
        final restaurantId = uri.queryParameters['restaurant_id']?.trim();

        if (tableNumber.isNotEmpty && restaurantId?.isNotEmpty == true) {
          _navigateToMenu(context, tableNumber, restaurantId!);
        } else {
          debugPrint('Paramètres de lien invalides');
        }
      } else {
        debugPrint('Format de lien invalide');
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement du lien: $e');
    }
  }

  bool _isValidDomain(Uri uri) {
    final allowedHosts = [
      'matchop.app.link',
      'matchop.page.link',
      'matchop.com',
      'www.matchop.com'
    ];
    return allowedHosts.contains(uri.host.toLowerCase());
  }

  void _navigateToMenu(
      BuildContext context, String tableNumber, String restaurantId) {
    try {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => MenuScreen(
            tableNumber: tableNumber,
            restaurantId: restaurantId,
          ),
        ),
      );

      debugPrint(
          'Navigation vers table $tableNumber, restaurant $restaurantId');
    } catch (e) {
      debugPrint('Erreur de navigation: $e');
    }
  }

  Future<String> createLink(String tableNumber, String restaurantId) async {
    if (tableNumber.trim().isEmpty || restaurantId.trim().isEmpty) {
      throw ArgumentError('Table number and restaurant ID cannot be empty');
    }

    final cleanTableNumber = tableNumber.trim();
    final cleanRestaurantId = restaurantId.trim();

    return '$baseUrl/table/$cleanTableNumber?restaurant_id=$cleanRestaurantId';
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    _linkSubscription = null;
    _isInitialized = false;
    super.dispose();
  }
}
