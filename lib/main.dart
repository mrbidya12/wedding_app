import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:weddingpro_connect/providers/auth_provider.dart';
import 'package:weddingpro_connect/providers/language_provider.dart';
import 'package:weddingpro_connect/providers/theme_provider.dart';
import 'package:weddingpro_connect/screens/home_screen.dart';
import 'package:weddingpro_connect/services/notification_service.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize Firebase
  await Firebase.initializeApp();
  
  // Initialize Notifications
  await NotificationService.init();
  
  // Set status bar to purple globally
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Color(0xFF6A1B9A), // Primary Purple
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const primaryPurple = Color(0xFF6A1B9A);
    const accentPurple = Color(0xFF9C27B0);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer2<ThemeProvider, LanguageProvider>(
        builder: (context, themeProvider, languageProvider, _) {
          return MaterialApp(
            title: 'Kbidu',
            navigatorKey: navigatorKey,
            debugShowCheckedModeBanner: false,
            locale: languageProvider.currentLocale,
            supportedLocales: const [
              Locale('en', ''),
              Locale('hi', ''),
              Locale('or', ''),
            ],
            localizationsDelegates: [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            themeMode: themeProvider.themeMode,
            theme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryPurple,
                primary: primaryPurple,
                secondary: accentPurple,
                surface: const Color(0xFFF9F7F5),
              ),
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: const Color(0xFFF9F7F5),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: primaryPurple,
                foregroundColor: Colors.white,
                elevation: 0,
                systemOverlayStyle: SystemUiOverlayStyle.light,
              ),
            ),
            darkTheme: ThemeData(
              useMaterial3: true,
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: primaryPurple,
                brightness: Brightness.dark,
                primary: const Color(0xFFE1BEE7),
                secondary: accentPurple,
                surface: const Color(0xFF0F0A1A),
              ),
              fontFamily: 'Poppins',
              scaffoldBackgroundColor: const Color(0xFF0F0A1A),
              appBarTheme: const AppBarTheme(
                centerTitle: true,
                backgroundColor: Color(0xFF1A1425),
                foregroundColor: Colors.white,
                elevation: 0,
              ),
            ),
            home: const HomeScreen(),
          );
        },
      ),
    );
  }
}
