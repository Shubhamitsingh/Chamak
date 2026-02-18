import 'dart:ui' show PlatformDispatcher;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// Using Google Fonts API instead of local bundled fonts
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'firebase_options.dart';
import 'screens/intro_logo_screen.dart';
import 'screens/login_screen.dart';
import 'providers/language_provider.dart';
import 'services/notification_service.dart';
import 'services/update_service.dart';
import 'services/crashlytics_service.dart';
import 'services/in_app_update_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:facebook_app_events/facebook_app_events.dart';
import 'package:Chamak/generated/l10n/app_localizations.dart';

// ⚠️ CRITICAL FIX: Global navigator key for deep linking from notifications
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

/// Track app session count (for review trigger strategy)
Future<void> _trackAppSession() async {
  try {
    final prefs = await SharedPreferences.getInstance();
    final sessionCount = prefs.getInt('app_session_count') ?? 0;
    await prefs.setInt('app_session_count', sessionCount + 1);
    
    // Mark first use date if not set
    if (prefs.getString('first_use_date') == null) {
      await prefs.setString('first_use_date', DateTime.now().toIso8601String());
    }
    
    debugPrint('📊 App session tracked: ${sessionCount + 1}');
  } catch (e) {
    debugPrint('⚠️ Error tracking app session: $e');
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Facebook SDK BEFORE runApp()
  try {
    final facebookAppEvents = FacebookAppEvents();
    await facebookAppEvents.setAutoLogAppEventsEnabled(true);
    await facebookAppEvents.setAdvertiserTracking(enabled: true);
    
    // Log test event to verify SDK is working
    await facebookAppEvents.logEvent(name: 'app_activate');
    debugPrint('✅ Facebook SDK initialized successfully');
    debugPrint('✅ Test event "app_activate" logged');
  } catch (e) {
    debugPrint('❌ Facebook SDK initialization error: $e');
    // Don't block app startup if SDK init fails
  }
  
  // Initialize Firebase (required before app starts)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  // Initialize Crashlytics Error Handlers
  // Pass all uncaught "fatal" errors from the framework to Crashlytics
  FlutterError.onError = (errorDetails) {
    // Log to console in debug mode
    FlutterError.presentError(errorDetails);
    
    // Send to Crashlytics
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  
  // Pass all uncaught asynchronous errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
  
  // Set app version info in Crashlytics
  try {
    final packageInfo = await PackageInfo.fromPlatform();
    await CrashlyticsService.setCustomKeys({
      'app_version': packageInfo.version,
      'build_number': packageInfo.buildNumber,
      'package_name': packageInfo.packageName,
    });
  } catch (e) {
    debugPrint('⚠️ Failed to set app version in Crashlytics: $e');
  }
  
  // Initialize Firebase Cloud Messaging - Background handler
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  
  // Initialize Update Service (for checking app updates)
  UpdateService().initialize().catchError((error) {
    debugPrint('⚠️ Update service initialization error: $error');
    // Log to Crashlytics
    CrashlyticsService.logError(
      error,
      StackTrace.current,
      context: 'Update service initialization failed',
      fatal: false,
    );
  });
  
  // Set system UI overlay style (non-blocking)
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white, // Match app background
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent, // Remove divider
    ),
  );
  
  // Lock orientation to portrait
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  
  // Track app session (for review trigger strategy)
  _trackAppSession().catchError((e) {
    debugPrint('⚠️ Error tracking app session: $e');
  });
  
  // Start the app immediately - don't wait for notification service
  runApp(
    ChangeNotifierProvider(
      create: (_) => LanguageProvider(),
      child: const LiveVibeApp(),
    ),
  );
  
  // Listen to auth state changes to handle logout scenarios and FCM token updates
  FirebaseAuth.instance.authStateChanges().listen((User? user) {
    if (user == null) {
      // User logged out - this will be handled by navigation in screens
      debugPrint('🔐 Auth state changed: User logged out');
      // Clear user ID in Crashlytics
      CrashlyticsService.clearUserId();
    } else {
      debugPrint('🔐 Auth state changed: User logged in - ${user.uid}');
      // Set user ID in Crashlytics
      CrashlyticsService.setUserId(user.uid);
      
      // ✅ CRITICAL FIX: Ensure FCM token is saved when user logs in
      // This handles new users and users who login after app restart
      // Re-initialize notification service to get and save FCM token
      NotificationService().initialize().catchError((error) {
        debugPrint('⚠️ Error re-initializing notification service after login: $error');
        CrashlyticsService.logError(
          error,
          StackTrace.current,
          context: 'Notification service re-initialization failed after login',
          fatal: false,
        );
      });
    }
  });
  
  // Initialize Notification Service in background (non-blocking)
  // This allows the app to show UI immediately while notifications initialize
  // Note: This will also run when user is already logged in (app restart)
  NotificationService().initialize().catchError((error) {
    debugPrint('⚠️ Notification service initialization error: $error');
    // Log to Crashlytics
    CrashlyticsService.logError(
      error,
      StackTrace.current,
      context: 'Notification service initialization failed',
      fatal: false,
    );
  });
  
  // Check for app updates after app starts (non-blocking)
  _checkForInAppUpdates();
}

/// Check for Google Play In-App Updates (non-blocking)
/// This runs after app startup to check for available updates
void _checkForInAppUpdates() {
  // Wait a bit for app to fully load before checking for updates
  Future.delayed(const Duration(seconds: 3), () async {
    try {
      final updateService = InAppUpdateService();
      await updateService.checkForUpdate(
        showFlexible: true,
        showImmediate: true,
      );
    } catch (e) {
      debugPrint('⚠️ In-app update check failed: $e');
      // Don't log to Crashlytics - this is expected to fail in debug mode
      // (In-app updates only work with Play Store builds)
    }
  });
}

class LiveVibeApp extends StatelessWidget {
  const LiveVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageProvider>(
      builder: (context, languageProvider, child) {
        return MaterialApp(
          navigatorKey: navigatorKey, // ⚠️ CRITICAL FIX: Enable deep linking
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
    // Use Google Fonts API for Poppins font
    final baseTextTheme = ThemeData.light().textTheme;
    
    debugPrint('🔤 Using Google Fonts API for Poppins font');
    
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF6C63FF),
        brightness: Brightness.light,
      ),
      // Use Google Fonts API for Poppins font
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


