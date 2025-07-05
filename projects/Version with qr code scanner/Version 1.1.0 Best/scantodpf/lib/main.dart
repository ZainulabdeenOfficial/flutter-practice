// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'services/storage_service.dart';
// import 'providers/theme_provider.dart';
// import 'providers/navigation_provider.dart';
// import 'screens/main_navigation_screen.dart';
// import 'screens/splash_screen.dart';
// import 'screens/onboarding_screen.dart';
// import 'screens/camera_screen.dart';
// import 'screens/pdf_list_screen.dart';
// import 'screens/gallery_import_screen.dart';
//
// import 'screens/settings_screen.dart';
// import 'screens/about_screen.dart';
// import 'screens/help_screen.dart';
//
// void main() async {
//   WidgetsFlutterBinding.ensureInitialized();
//
//   // Initialize storage service
//   await StorageService.initialize();
//
//   runApp(const MyApp());
// }
//
// class MyApp extends StatelessWidget {
//   const MyApp({super.key});
//
//   @override
//   Widget build(BuildContext context) {
//     return MultiProvider(
//       providers: [
//         ChangeNotifierProvider(create: (_) => ThemeProvider()),
//         ChangeNotifierProvider(create: (_) => NavigationProvider()),
//       ],
//       child: Consumer<ThemeProvider>(
//         builder: (context, themeProvider, child) {
//           return MaterialApp(
//             title: 'Scan2PDF Pro',
//             debugShowCheckedModeBanner: false,
//             theme: ThemeData(
//               primarySwatch: Colors.blue,
//               primaryColor: const Color(0xFF1E88E5),
//               visualDensity: VisualDensity.adaptivePlatformDensity,
//               fontFamily: 'Roboto',
//             ),
//             darkTheme: ThemeData.dark().copyWith(
//               primaryColor: const Color(0xFF1E88E5),
//             ),
//             themeMode: themeProvider.themeMode,
//             home: const SplashScreen(),
//             routes: {
//               '/main': (context) => const MainNavigationScreen(),
//               '/onboarding': (context) => const OnboardingScreen(),
//               '/camera': (context) => const CameraScreen(),
//               '/pdf-list': (context) => const PDFListScreen(),
//               '/gallery-import': (context) => const GalleryImportScreen(),
//
//               '/settings': (context) => const SettingsScreen(),
//               '/about': (context) => const AboutScreen(),
//               '/help': (context) => const HelpScreen(),
//             },
//           );
//         },
//       ),
//     );
//   }
// }
//

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/storage_service.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/home_screen.dart';
import 'screens/camera_screen.dart';
import 'screens/document_scanner_screen.dart';
import 'screens/gallery_import_screen.dart';
import 'screens/pdf_list_screen.dart';
import 'screens/qr_scanner_screen.dart';

import 'screens/settings_screen.dart';
import 'screens/about_screen.dart';
import 'screens/help_screen.dart';
import 'screens/main_navigation_screen.dart';
import 'providers/theme_provider.dart';
import 'providers/navigation_provider.dart';
import 'providers/image_provider.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize storage service
  await StorageService.initialize();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => NavigationProvider()),
        ChangeNotifierProvider(create: (_) => ImageProviderModel()),

      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            title: 'Scan2PDF Pro',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF1E88E5),
              scaffoldBackgroundColor: const Color(0xFFF8FAFC),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
              cardTheme: CardThemeData(
                color: Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1E88E5),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF1E88E5),
                foregroundColor: Colors.white,
                elevation: 8,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Colors.white,
                selectedItemColor: Color(0xFF1E88E5),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                elevation: 8,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              primarySwatch: Colors.blue,
              primaryColor: const Color(0xFF2196F3),
              scaffoldBackgroundColor: const Color(0xFF121212),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1E1E1E),
                foregroundColor: Colors.white,
                elevation: 0,
                centerTitle: true,
              ),
              cardTheme: CardThemeData(
                color: const Color(0xFF1E1E1E),
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2196F3),
                  foregroundColor: Colors.white,
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
              floatingActionButtonTheme: const FloatingActionButtonThemeData(
                backgroundColor: Color(0xFF2196F3),
                foregroundColor: Colors.white,
                elevation: 8,
              ),
              bottomNavigationBarTheme: const BottomNavigationBarThemeData(
                backgroundColor: Color(0xFF1E1E1E),
                selectedItemColor: Color(0xFF2196F3),
                unselectedItemColor: Colors.grey,
                type: BottomNavigationBarType.fixed,
                elevation: 8,
              ),
            ),
            themeMode: themeProvider.themeMode,
            initialRoute: '/splash',
            routes: {

              '/splash': (context) => const SplashScreen(),
              '/onboarding': (context) => const OnboardingScreen(),
              '/home': (context) => const HomeScreen(),
              '/main': (context) => const MainNavigationScreen(),
              '/camera': (context) => const CameraScreen(),
              '/document-scanner': (context) => const DocumentScannerScreen(),
              '/gallery-import': (context) => const GalleryImportScreen(),
              '/pdf-list': (context) => const PDFListScreen(),
              '/qr-scanner': (context) => const QRScannerScreen(),

              '/settings': (context) => const SettingsScreen(),
              '/about': (context) => const AboutScreen(),
              '/help': (context) => const HelpScreen(),
            },
          );
        },
      ),
    );
  }
}
