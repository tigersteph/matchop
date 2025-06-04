import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
    
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'YOUR-API-KEY',
    appId: 'YOUR-APP-ID',
    messagingSenderId: 'YOUR-SENDER-ID',
    projectId: 'YOUR-PROJECT-ID',
    authDomain: 'YOUR-AUTH-DOMAIN',
    storageBucket: 'YOUR-STORAGE-BUCKET',
  );

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
