import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
      authDomain: 'resto-e9414.firebaseapp.com',
      projectId: 'resto-e9414',
      storageBucket: 'resto-e9414.firebasestorage.app',
      messagingSenderId: '616163558071',
      appId: '1:616163558071:web:1bda20a0c2dd0c8c184332',
      measurementId: 'G-HLPJSLCGFD',
    );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
    appId: '1:616163558071:android:1bda20a0c2dd0c8c184332',
    messagingSenderId: '616163558071',
    projectId: 'resto-e9414',
    storageBucket: 'resto-e9414.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
    appId: '1:616163558071:ios:1bda20a0c2dd0c8c184332',
    messagingSenderId: '616163558071',
    projectId: 'resto-e9414',
    storageBucket: 'resto-e9414.firebasestorage.app',
    iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.example.resto',
  );
}
