import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/admin_screen.dart';
import 'screens/order_management_screen.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/qr_code_management_screen.dart';
import 'screens/menu_screen.dart';
import 'utils/test_data.dart';
import 'services/order_service.dart';
import 'services/deep_link_service.dart';
import 'services/qr_generator_service.dart';
import 'services/dynamic_link_service.dart';
import 'services/logging_service.dart';
import 'services/app_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    LoggingService.log('🚀 Début de l\'initialisation...');

    // Initialisation minimale de Firebase Core
    try {
      LoggingService.log('🔥 Initialisation Firebase...');
      final firebaseOptions = DefaultFirebaseOptions.currentPlatform;

      // Vérification sécurisée des propriétés Firebase avec null safety
      if (!_validateFirebaseOptions(firebaseOptions)) {
        throw Exception(
            'Erreur de configuration : au moins une clé Firebase est manquante ou vide.');
      }

      // Initialiser Firebase si nécessaire
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: firebaseOptions,
          name: '[DEFAULT]', // Spécifier le nom de l'application
        );
      } else {
        // Si Firebase est déjà initialisé, récupérer l'instance existante
        Firebase.app('[DEFAULT]');
        LoggingService.log('✅ Firebase déjà initialisé');
      }
      LoggingService.log('✅ Firebase initialisé avec succès');
    } catch (e) {
      LoggingService.error('❌ Erreur Firebase', error: e);
      throw Exception('Erreur lors de l\'initialisation de Firebase: $e');
    }

    LoggingService.log('🎯 Lancement de l\'application...');

    // Initialiser le restaurant de test
    try {
      await TestData.initializeTestRestaurant();
      LoggingService.log('✅ Restaurant de test initialisé');
    } catch (e) {
      LoggingService.error(
          '❌ Erreur lors de l\'initialisation du restaurant de test',
          error: e);
    }

    runApp(const MyApp());
  } catch (e) {
    LoggingService.log('💥 ERREUR PRINCIPALE: $e');
    LoggingService.error('Erreur lors de l\'initialisation',
        error: e, tag: 'Initialisation');
    runApp(MaterialApp(
      home: Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              const Text(
                'Erreur lors du démarrage de l\'application:',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  e.toString(),
                  style: const TextStyle(fontSize: 14),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // Relancer l'app
                  main();
                },
                child: const Text('Réessayer'),
              ),
            ],
          ),
        ),
      ),
    ));
  }
}

// --- Validation des options Firebase ---
bool _validateFirebaseOptions(FirebaseOptions options) {
  try {
    // Vérification avec null safety et opérateurs conditionnels
    final apiKeyValid = options.apiKey.isNotEmpty;
    final appIdValid = options.appId.isNotEmpty;
    final projectIdValid = options.projectId.isNotEmpty;
    final messagingSenderIdValid = options.messagingSenderId.isNotEmpty;
    final storageBucketValid = (options.storageBucket?.isNotEmpty ?? false);

    LoggingService.log('🔍 Validation Firebase Options:');
    LoggingService.log('  - API Key: ${apiKeyValid ? "✅" : "❌"}');
    LoggingService.log('  - App ID: ${appIdValid ? "✅" : "❌"}');
    LoggingService.log('  - Project ID: ${projectIdValid ? "✅" : "❌"}');
    LoggingService.log(
        '  - Messaging Sender ID: ${messagingSenderIdValid ? "✅" : "❌"}');
    LoggingService.log(
        '  - Storage Bucket: ${storageBucketValid ? "✅" : "⚠️"}');

    return apiKeyValid &&
        appIdValid &&
        projectIdValid &&
        messagingSenderIdValid;
  } catch (e) {
    LoggingService.error('Erreur lors de la validation Firebase', error: e);
    return false;
  }
}

// --- Initialisation différée des services Firebase additionnels ---
Future<void> initializeFirebaseServices() async {
  // Initialisation Crashlytics
  try {
    LoggingService.log('📊 Initialisation Crashlytics...');
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    LoggingService.log('✅ Crashlytics initialisé avec succès');
  } catch (e) {
    LoggingService.error('❌ Erreur Crashlytics', error: e, tag: 'Crashlytics');
  }

  // Initialisation App Check
  try {
    LoggingService.log('🔐 Initialisation App Check...');
    await AppCheckService.initialize();
    LoggingService.log('✅ App Check initialisé avec succès');
  } catch (e) {
    LoggingService.error('Erreur App Check', error: e, tag: 'AppCheck');
  }
}

// --- Widget racine ---

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialisation différée des services Firebase additionnels après le premier frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      initializeFirebaseServices();
    });

    try {
      LoggingService.log('🏗️ Construction de MyApp...');
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<OrderService>(
              create: (context) => OrderService()),
          ChangeNotifierProvider<DeepLinkService>(
              create: (context) => DeepLinkService()),
          ChangeNotifierProvider<DynamicLinkService>(
              create: (context) => DynamicLinkService()),
          ChangeNotifierProvider<QRGeneratorService>(
              create: (_) => QRGeneratorService()),
        ],
        child: MaterialApp(
          title: 'Restaurant QR',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            textTheme: GoogleFonts.poppinsTextTheme(),
            useMaterial3: true,
          ),
          routes: {
            '/': (context) => const SplashScreen(),
            '/qr': (context) => const QRScannerScreen(),
            '/admin': (context) => const OrderManagementScreen(),
            '/admin/setup': (context) => const AdminScreen(),
            '/admin/qr': (context) => const QRCodeManagementScreen(),
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/menu') {
              final args = settings.arguments as Map<String, String>?;
              return MaterialPageRoute(
                builder: (context) => MenuScreen(
                  restaurantId: args?['restaurantId'] ?? '',
                  tableNumber: args?['tableNumber'] ?? '',
                ),
              );
            }
            return MaterialPageRoute(
              builder: (context) => const QRScannerScreen(),
            );
          },
          builder: (context, child) {
            ErrorWidget.builder = (FlutterErrorDetails details) {
              LoggingService.error('Erreur dans l\'application',
                  error: details.exception, tag: 'ErrorWidget');
              LoggingService.error('Stack trace:',
                  error: details.stack, tag: 'ErrorWidget');
              return CustomErrorWidget(
                  message: 'Une erreur est survenue. Veuillez réessayer.',
                  onRetry: () {
                    main();
                  });
            };
            return child!;
          },
          navigatorObservers: [
            RouteObserver<PageRoute>(),
          ],
        ),
      );
    } catch (e) {
      LoggingService.error('Erreur lors de l\'initialisation des services',
          error: e, tag: 'Initialisation');
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Matchop'),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdminScreen(),
                      ),
                    );
                  },
                  child: const Text('Admin'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () async {
                    try {
                      await TestData.setupTestRestaurant();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content:
                              Text('Restaurant de test configuré avec succès'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Erreur: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Configurer Restaurant Test'),
                ),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const OrderManagementScreen(),
                      ),
                    );
                  },
                  child: const Text('Gestion des commandes'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// --- Widget d'erreur personnalisé ---
class CustomErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const CustomErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 80,
                color: Colors.red,
              ),
              const SizedBox(height: 20),
              Text(
                'Oops! Une erreur est survenue',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              if (onRetry != null)
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Réessayer'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 30,
                      vertical: 15,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
