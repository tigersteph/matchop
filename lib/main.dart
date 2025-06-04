import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/qr_scanner_screen.dart';
import 'screens/order_management_screen.dart';
import 'screens/admin_screen.dart';
import 'services/order_service.dart';
import 'services/dynamic_links_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<OrderService>(create: (_) => OrderService()),
        Provider<DynamicLinksService>(create: (_) => DynamicLinksService()),
      ],
      child: MaterialApp(
        title: 'Restaurant QR',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
          textTheme: GoogleFonts.poppinsTextTheme(),
          useMaterial3: true,
        ),
        home: Builder(
          builder: (context) {
            // Initialize Dynamic Links
            Provider.of<DynamicLinksService>(context, listen: false)
                .initDynamicLinks(context);
            return const QRScannerScreen();
          },
        ),
        routes: {
          '/admin': (context) => const OrderManagementScreen(),
          '/admin/setup': (context) => const AdminScreen(),
        },
      ),
    );
  }
}
