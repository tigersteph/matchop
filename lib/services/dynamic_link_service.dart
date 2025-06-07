import 'package:uni_links/uni_links.dart';
import 'package:flutter/material.dart';
import '../screens/menu_screen.dart';

class DynamicLinkService extends ChangeNotifier {
  static const String baseUrl = 'https://matchop.app.link';

  Future<void> initDynamicLinks(BuildContext context) async {
    try {
      uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null && context.mounted) {
            _handleLink(context, uri);
          }
        },
        onError: (error) {
          debugPrint('Erreur de lien: $error');
        },
      );

      final initialUri = await getInitialUri();
      if (initialUri != null && context.mounted) {
        _handleLink(context, initialUri);
      }
    } catch (e) {
      debugPrint('Erreur lors de l\'initialisation des liens: $e');
    }
  }

  void _handleLink(BuildContext context, Uri uri) {
    try {
      final parts = uri.pathSegments;
      if (parts.length == 2) {
        final tableNumber = parts[1].trim();
        final restaurantId = uri.queryParameters['restaurant_id']?.trim();

        if (tableNumber.isNotEmpty && restaurantId?.isNotEmpty == true) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => MenuScreen(
                tableNumber: tableNumber,
                restaurantId: restaurantId!,
              ),
            ),
          );
        } else {
          debugPrint('Invalid link parameters: empty strings');
        }
      } else {
        debugPrint('Invalid path segments: ${parts.length}');
      }
    } catch (e) {
      debugPrint('Erreur lors du traitement du lien: $e');
    }
  }

  Future<String> createLink(String tableNumber, String restaurantId) async {
    return '$baseUrl/table/$tableNumber?restaurant_id=$restaurantId';
  }
}