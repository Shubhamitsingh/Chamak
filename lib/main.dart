import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';
import 'screens/intro_logo_screen.dart';
import 'screens/login_screen.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase (required before app starts)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Firebase Cloud Messaging - Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Set system UI overlay style (non-blocking)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Start the app immediately - don't wait for notification service
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const LiveVibeApp(),
    ),
  );
  
  // Listen to auth state changes to handle logout scenarios
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      // User logged out - this will be handled by navigation in screens
      debugPrint('🔐 Auth state changed: User logged out');
    } else {
      debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
    }
  });
  
  // Initialize Notification Service in background (non-blocking)
  // This allows the app to show UI immediately while notifications initialize
  NotificationService().initialize().catchError((error) {
    debugPrint('⚠️ Notification service initialization error: $error');
    // Don't block app startup if notifications fail
  });
}

class LiveVibeApp extends StatelessWidget {
  const LiveVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          title: 'Chamak',
          debugShowCheckedModeBanner: false,
          theme: _buildTheme(),
          locale: languageProvider.locale,
          builder: (context, child) {
            // Wrap with white background to prevent any flash
            return Container(
              color: Colors.white,
              child: child ?? const SizedBox(),
            );
          },
          localizationsDelegates: const [
            AppLocalizations.delegate,
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('en'), // English
            Locale('hi'), // Hindi
            Locale('ta'), // Tamil
            Locale('te'), // Telugu
            Locale('ml'), // Malayalam
            Locale('mr'), // Marathi
            Locale('kn'), // Kannada
          ],
          localeResolutionCallback: (locale, supportedLocales) {
            if (locale != null) {
              for (var supportedLocale in supportedLocales) {
                if (supportedLocale.languageCode == locale.languageCode) {
                  return supportedLocale;
                }
              }
            }
            return supportedLocales.first; // Default to English
          },
          home: const IntroLogoScreen(),
          routes: {
            '/login': (context) => const LoginScreen(),
          },
        );
      },
    );
  }

  ThemeData _buildTheme() {
    // Use default text theme first, then load Google Fonts asynchronously
    // This prevents blocking the app startup
    final baseTextTheme = ThemeData.light().textTheme;
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      // Load Google Fonts asynchronously to prevent blocking startup
      textTheme: GoogleFonts.poppinsTextTheme(baseTextTheme),
      scaffoldBackgroundColor: Colors.white, // White background to prevent cream flash
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Color(0xFF6C63FF), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(30),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
      ),
    );
  }
}


