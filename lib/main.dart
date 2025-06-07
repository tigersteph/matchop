import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'firebase_options.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/order_management_screen.dart';
import 'screens/admin_screen.dart';
import 'services/order_service.dart';
import 'services/deep_link_service.dart';
import 'services/dynamic_link_service.dart';
import 'services/logging_service.dart';
import 'services/app_check_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Initialiser Firebase Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    
    // Initialiser Firebase App Check
    await AppCheckService.initialize();
    runApp(const MyApp());
  } catch (e) {
    LoggingService.error(
      'Erreur lors de l\'initialisation', 
      error: e,
      tag: 'Initialisation'
    );
    runApp(const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text(
            'Erreur lors du démarrage de l\'application. Veuillez réessayer.',
            style: TextStyle(fontSize: 16),
          ),
        ),
      ),
    ));
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key}) : super();

  final TextStyle _textStyle = const TextStyle(fontSize: 16);

  @override
  Widget build(BuildContext context) {
    try {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<OrderService>(create: (context) => OrderService()),
          ChangeNotifierProvider<DeepLinkService>(create: (context) => DeepLinkService()),
          ChangeNotifierProvider<DynamicLinkService>(create: (context) => DynamicLinkService()),
        ],
        child: MaterialApp(
          title: 'Restaurant QR',
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
            textTheme: GoogleFonts.poppinsTextTheme(),
            useMaterial3: true,
          ),
          home: const QRScannerScreen(),
          routes: {
            '/admin': (context) => const OrderManagementScreen(),
            '/admin/setup': (context) => const AdminScreen(),
          },
          builder: (context, child) {
            ErrorWidget.builder = (FlutterErrorDetails details) {
              LoggingService.error(
                'Erreur dans l\'application', 
                error: details.exception,
                tag: 'ErrorWidget'
              );
              LoggingService.error('Stack trace:', error: details.stack, tag: 'ErrorWidget');
              return ErrorWidget('Une erreur est survenue. Veuillez réessayer.');
            };
            return child!;
          },
          onGenerateRoute: (settings) {
            if (settings.name == '/') {
              return MaterialPageRoute(
                builder: (context) {
                  final deepLinkService = Provider.of<DeepLinkService>(context, listen: false);
                  final dynamicLinkService = Provider.of<DynamicLinkService>(context, listen: false);
                  
                  // Initialiser les services
                  deepLinkService.initDeepLinks(context);
                  dynamicLinkService.initDynamicLinks(context);
                  
                  return const QRScannerScreen();
                },
              );
            }
            return null;
          },
        ),
      );
    } catch (e) {
      LoggingService.error(
        'Erreur lors de l\'initialisation des services', 
        error: e,
        tag: 'Initialisation'
      );
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text(
              'Erreur lors de l\'initialisation des services. Veuillez réessayer.',
              style: _textStyle,
            ),
          ),
        ),
      );
    }
  }
}
