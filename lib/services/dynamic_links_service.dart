import 'package:firebase_dynamic_links/firebase_dynamic_links.dart';
import 'package:flutter/material.dart';

class DynamicLinksService {
  final dynamicLinks = FirebaseDynamicLinks.instance;

  Future<void> initDynamicLinks(BuildContext context) async {
    // Handle links while app is in background
    dynamicLinks.onLink.listen((dynamicLinkData) {
      _handleDynamicLink(dynamicLinkData, context);
    }).onError((error) {
      print('Dynamic Link Failed: $error');
    });

    // Handle links that opened the app
    final PendingDynamicLinkData? data = await dynamicLinks.getInitialLink();
    if (data != null) {
      _handleDynamicLink(data, context);
    }
  }

  Future<String> createDynamicLink({
    required String path,
    required String title,
    required String description,
    String? imageUrl,
  }) async {
    final DynamicLinkParameters parameters = DynamicLinkParameters(
      uriPrefix: 'https://resto-e9414.web.app',
      link: Uri.parse('https://resto-e9414.firebaseapp.com/$path'),
      androidParameters: const AndroidParameters(
        packageName: 'com.resto.app',
        minimumVersion: 1,
      ),
      iosParameters: const IOSParameters(
        bundleId: 'com.resto.app',
        minimumVersion: '1',
      ),
      socialMetaTagParameters: SocialMetaTagParameters(
        title: title,
        description: description,
        imageUrl: imageUrl != null ? Uri.parse(imageUrl) : null,
      ),
    );

    final ShortDynamicLink shortLink = await dynamicLinks.buildShortLink(parameters);
    return shortLink.shortUrl.toString();
  }

  Future<String> createMenuShareLink({
    required String menuId,
    required String restaurantName,
    String? imageUrl,
  }) async {
    return createDynamicLink(
      path: 'menu/$menuId',
      title: 'Menu de $restaurantName',
      description: 'Découvrez notre carte et commandez en ligne !',
      imageUrl: imageUrl,
    );
  }

  Future<String> createOrderShareLink({
    required String orderId,
    required String restaurantName,
  }) async {
    return createDynamicLink(
      path: 'order/$orderId',
      title: 'Commande - $restaurantName',
      description: 'Suivez votre commande en temps réel',
      imageUrl: null,
    );
  }

  void _handleDynamicLink(PendingDynamicLinkData data, BuildContext context) {
    final Uri deepLink = data.link;
    final pathSegments = deepLink.pathSegments;

    if (pathSegments.isEmpty) return;

    switch (pathSegments[0]) {
      case 'menu':
        if (pathSegments.length > 1) {
          final menuId = pathSegments[1];
          Navigator.pushNamed(context, '/menu', arguments: menuId);
        }
        break;
      case 'order':
        if (pathSegments.length > 1) {
          final orderId = pathSegments[1];
          Navigator.pushNamed(context, '/order', arguments: orderId);
        }
        break;
    }
  }
}