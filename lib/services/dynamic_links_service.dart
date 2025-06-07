import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';

/// Types de liens supportés
enum DeepLinkType {
  menu('menu'),
  order('order'),
  table('table'),
  restaurant('restaurant');

  const DeepLinkType(this.path);
  final String path;
}

/// Exception personnalisée pour les erreurs de liens
class DeepLinkException implements Exception {
  final String message;
  final dynamic originalError;

  DeepLinkException(this.message, [this.originalError]);

  @override
  String toString() => 'DeepLinkException: $message${originalError != null ? ' ($originalError)' : ''}';
}

class DeepLinkService {
  final functions = FirebaseFunctions.instance;
  StreamSubscription? _linkSubscription;
  


  /// Initialise le service de liens
  Future<void> initDeepLinks(BuildContext context) async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final snackBarContext = context;

    try {
      // Gérer les liens pendant que l'app est en arrière-plan
      _linkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null && context.mounted) {
            _handleDeepLink(uri, navigator);
          }
        },
        onError: (error) {
          debugPrint('Erreur de lien: $error');
          if (snackBarContext.mounted) {
            _showErrorSnackBar(snackBarContext, 'Erreur lors de l\'ouverture du lien');
          }
        },
      );

      // Gérer les liens qui ont ouvert l'app
      final initialUri = await getInitialUri();
      if (initialUri != null && context.mounted) {
        _handleDeepLink(initialUri, navigator);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des liens: $e');
      if (snackBarContext.mounted) {
        _showErrorSnackBar(snackBarContext, 'Erreur lors de l\'initialisation des liens');
      }
    }
  }

  /// Crée un lien court via Cloud Functions
  Future<String> createShortLink({
    required String path,
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    try {
      // Valider les paramètres
      if (path.isEmpty) throw ArgumentError('Le chemin ne peut pas être vide');
      if (title.isEmpty) throw ArgumentError('Le titre ne peut pas être vide');
      if (description.isEmpty) throw ArgumentError('La description ne peut pas être vide');

      final callable = functions.httpsCallable('createShortLink');
      final result = await callable.call({
        'path': path,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
      });

      final shortLink = result.data['shortLink'] as String;
      if (shortLink.isEmpty) {
        throw DeepLinkException('Réponse invalide du serveur');
      }

      return shortLink;
    } catch (e) {
      throw DeepLinkException('Impossible de créer le lien', e);
    }
  }

  /// Crée un lien de partage pour un menu
  Future<String> createMenuShareLink({
    required String menuId,
    required String restaurantName,
    String? imageUrl,
  }) async {
    _validateParameters({
      'menuId': menuId,
      'restaurantName': restaurantName,
    });

    return createShortLink(
      path: '${DeepLinkType.menu.path}/$menuId',
      title: 'Menu de $restaurantName',
      description: 'Découvrez notre carte et commandez en ligne !',
      imageUrl: imageUrl,
    );
  }

  /// Crée un lien de partage pour une commande
  Future<String> createOrderShareLink({
    required String orderId,
    required String restaurantName,
  }) async {
    _validateParameters({
      'orderId': orderId,
      'restaurantName': restaurantName,
    });

    return createShortLink(
      path: '${DeepLinkType.order.path}/$orderId',
      title: 'Commande - $restaurantName',
      description: 'Suivez votre commande en temps réel',
    );
  }

  /// Crée un lien de partage pour une table
  Future<String> createTableShareLink({
    required String tableId,
    required String restaurantName,
    required String restaurantId,
  }) async {
    _validateParameters({
      'tableId': tableId,
      'restaurantName': restaurantName,
      'restaurantId': restaurantId,
    });

    return createShortLink(
      path: '${DeepLinkType.table.path}/$restaurantId/$tableId',
      title: 'Table $tableId - $restaurantName',
      description: 'Rejoignez la table et commandez ensemble !',
    );
  }

  /// Gère les liens entrants
  void _handleDeepLink(Uri uri, NavigatorState navigator) {
    try {
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) return;

      final linkType = DeepLinkType.values.firstWhere(
        (type) => type.path == pathSegments[0],
        orElse: () => throw DeepLinkException('Type de lien inconnu: ${pathSegments[0]}'),
      );

      if (pathSegments.length < 2) {
        throw DeepLinkException('Lien incomplet pour ${linkType.path}');
      }

      switch (linkType) {
        case DeepLinkType.menu:
          navigator.pushNamed('/menu', arguments: pathSegments[1]);
          break;
        case DeepLinkType.order:
          navigator.pushNamed('/order', arguments: pathSegments[1]);
          break;
        case DeepLinkType.table:
          if (pathSegments.length < 3) {
            throw DeepLinkException('ID de restaurant manquant pour la table');
          }
          navigator.pushNamed(
            '/table',
            arguments: {
              'restaurantId': pathSegments[1],
              'tableId': pathSegments[2],
            },
          );
          break;
        case DeepLinkType.restaurant:
          navigator.pushNamed('/restaurant', arguments: pathSegments[1]);
          break;
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement du lien: $e');
    }
  }

  /// Valide les paramètres requis
  void _validateParameters(Map<String, String> parameters) {
    parameters.forEach((key, value) {
      if (value.isEmpty) {
        throw ArgumentError('Le paramètre $key ne peut pas être vide');
      }
    });
  }

  /// Affiche une snackbar d'erreur
  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
        ),
      ),
    );
  }

  /// Dispose des ressources
  void dispose() {
    _linkSubscription?.cancel();
  }
}