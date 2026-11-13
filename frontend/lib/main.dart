import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'generated/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/complaint_provider.dart';
import 'providers/locale_provider.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';
import 'features/splash/splash_screen.dart';
import 'features/auth/login_screen.dart';
import 'features/user/user_main_screen.dart';
import 'features/user/complaint_detail_screen.dart';
import 'features/admin/admin_main_screen.dart';
import 'services/session_manager.dart';
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    // Firebase already initialized (e.g. on hot restart), safe to ignore
  }

  // System UI
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Init notifications
  await NotificationService.initialize();

  final prefs = await SharedPreferences.getInstance();

  // Global navigator key — lets ApiService navigate to /login on session expiry
  final navigatorKey = GlobalKey<NavigatorState>();
  ApiService.navigatorKey = navigatorKey;

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider(prefs)),
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintProvider()),
      ],
      child: SmartGrievanceApp(navigatorKey: navigatorKey),
    ),
  );
}

class SmartGrievanceApp extends StatelessWidget {
  final GlobalKey<NavigatorState> navigatorKey;
  const SmartGrievanceApp({super.key, required this.navigatorKey});

  @override
  Widget build(BuildContext context) {
    final localeProvider = context.watch<LocaleProvider>();
    final authProvider = context.watch<AuthProvider>();

    return MaterialApp(
      navigatorKey: navigatorKey,
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: authProvider.darkMode ? ThemeMode.dark : ThemeMode.light,
      
      builder: (context, child) => SessionManager(child: child!),

      // Localization
      locale: localeProvider.locale,
      supportedLocales: const [
        Locale('en'),
        Locale('hi'),
        Locale('ta'),
        Locale('te'),
        Locale('kn'),
        Locale('ml'),
        Locale('mr'),
        Locale('gu'),
        Locale('pa'),
        Locale('bn'),
        Locale('or'),
        Locale('as'),
        Locale('ur'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/user': (_) => const UserMainScreen(),
        '/admin': (_) => const AdminMainScreen(),
        '/complaint-detail': (ctx) => ComplaintDetailScreen(
          complaintId: ModalRoute.of(ctx)!.settings.arguments as int,
        ),
      },
    );
  }
}
