import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
    
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform => const FirebaseOptions(
    apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
    appId: '1:859344028714:web:1bda20a0c2dd0c8c184332',
    messagingSenderId: '859344028714',
    projectId: 'matchop-restaurant',
    authDomain: 'matchop-restaurant.firebaseapp.com',
    storageBucket: 'matchop-restaurant.appspot.com',
  );

  static const FirebaseOptions web = FirebaseOptions(
      apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
      authDomain: 'matchop-restaurant.firebaseapp.com',
      projectId: 'matchop-restaurant',
      storageBucket: 'matchop-restaurant.appspot.com',
      messagingSenderId: '859344028714',
      appId: '1:859344028714:web:1bda20a0c2dd0c8c184332',
    );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
    appId: '1:859344028714:android:1bda20a0c2dd0c8c184332',
    messagingSenderId: '859344028714',
    projectId: 'matchop-restaurant',
    storageBucket: 'matchop-restaurant.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCtxwawDgBddPzxYGtkFRWlFajOwSBiXxM',
    appId: '1:859344028714:ios:1bda20a0c2dd0c8c184332',
    messagingSenderId: '859344028714',
    projectId: 'matchop-restaurant',
    storageBucket: 'matchop-restaurant.appspot.com',
    iosClientId: 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com',
    iosBundleId: 'com.example.resto',
  );
}
