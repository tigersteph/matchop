import 'package:firebase_core/firebase_core.dart';
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
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBetfoabzT3iv2Kyh78G-EpgjPnhIktTX8',
    appId: '1:616163558071:web:304bf574cf345811184332',
    messagingSenderId: '616163558071',
    projectId: 'resto-e9414',
    authDomain: 'resto-e9414.firebaseapp.com',
    storageBucket: 'resto-e9414.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBetfoabzT3iv2Kyh78G-EpgjPnhIktTX8',
    appId: '1:616163558071:android:304bf574cf345811184332',
    messagingSenderId: '616163558071',
    projectId: 'resto-e9414',
    storageBucket: 'resto-e9414.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBetfoabzT3iv2Kyh78G-EpgjPnhIktTX8',
    appId: '1:616163558071:ios:304bf574cf345811184332',
    messagingSenderId: '616163558071',
    projectId: 'resto-e9414',
    storageBucket: 'resto-e9414.firebasestorage.app',
    iosClientId: '616163558071-304bf574cf345811184332.apps.googleusercontent.com',
    iosBundleId: 'com.example.resto',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBetfoabzT3iv2Kyh78G-EpgjPnhIktTX8',
    appId: '1:616163558071:macos:304bf574cf345811184332',
    messagingSenderId: '616163558071',
    projectId: 'resto-e9414',
    storageBucket: 'resto-e9414.firebasestorage.app',
    iosClientId: '616163558071-304bf574cf345811184332.apps.googleusercontent.com',
    iosBundleId: 'com.example.resto',
  );
}
