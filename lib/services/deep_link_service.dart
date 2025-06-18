import 'package:flutter/material.dart';
import 'dart:async';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:app_links/app_links.dart';

class DeepLinkService extends ChangeNotifier {
  final FirebaseFunctions functions;
  final _appLinks = AppLinks();
  StreamSubscription? _linkSubscription;

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  DeepLinkService() : functions = FirebaseFunctions.instance;

  /// Initialise le service de liens
  Future<void> initDeepLinks(BuildContext context) async {
    if (!context.mounted) return;
    final navigator = Navigator.of(context);
    final snackBarContext = context;

    try {
      // Gérer les liens pendant que l'app est en arrière-plan
      _linkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          if (context.mounted) {
            _handleDeepLink(uri, navigator);
          }
        },
        onError: (error) {
          debugPrint('Erreur de lien: $error');
          if (snackBarContext.mounted) {
            _showErrorSnackBar(
                snackBarContext, 'Erreur lors de l\'ouverture du lien');
          }
        },
      );

      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null && context.mounted) {
        _handleDeepLink(initialUri, navigator);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des liens: $e');
      if (snackBarContext.mounted) {
        _showErrorSnackBar(
            snackBarContext, 'Erreur lors de l\'initialisation des liens');
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
      if (description.isEmpty) {
        throw ArgumentError('La description ne peut pas être vide');
      }

      final callable = functions.httpsCallable('createShortLink');
      final result = await callable.call({
        'path': path,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
      });

      final shortLink = result.data['shortLink'] as String;
      if (shortLink.isEmpty) {
        throw Exception('Réponse invalide du serveur');
      }

      return shortLink;
    } catch (e) {
      debugPrint('Erreur lors de la création du lien: $e');
      throw Exception('Impossible de créer le lien');
    }
  }

  /// Crée un lien de partage pour un menu
  Future<String> createMenuShareLink({
    required String menuId,
    required String restaurantName,
    required String menuName,
    String? imageUrl,
  }) async {
    return await createShortLink(
      path: '/menu/$menuId',
      title: 'Menu - $restaurantName',
      description: 'Découvrez le menu $menuName chez $restaurantName',
      imageUrl: imageUrl,
    );
  }

  /// Crée un lien de partage pour une table
  Future<String> createTableShareLink({
    required String restaurantId,
    required String tableName,
    required String restaurantName,
  }) async {
    return await createShortLink(
      path: '/table/$restaurantId/$tableName',
      title: 'Table - $restaurantName',
      description: 'Réservez la table $tableName chez $restaurantName',
    );
  }

  /// Gère un lien profond
  void _handleDeepLink(Uri uri, NavigatorState navigator) {
    try {
      final path = uri.path;
      final pathSegments = uri.pathSegments;

      if (pathSegments.isEmpty) return;

      switch (pathSegments[0]) {
        case 'menu':
          if (pathSegments.length > 1) {
            final menuId = pathSegments[1];
            navigator.pushNamed('/menu', arguments: {'id': menuId});
          }
          break;

        case 'table':
          if (pathSegments.length > 2) {
            final restaurantId = pathSegments[1];
            final tableName = pathSegments[2];
            navigator.pushNamed('/table', arguments: {
              'restaurantId': restaurantId,
              'tableName': tableName,
            });
          }
          break;

        default:
          debugPrint('Lien non géré: $path');
          break;
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement du lien: $e');
      if (navigator.context.mounted) {
        _showErrorSnackBar(navigator.context, 'Lien invalide');
      }
    }
  }

  /// Affiche un SnackBar d'erreur
  void _showErrorSnackBar(BuildContext context, String message) {
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
