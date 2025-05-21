import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'view_models/tree_view_model.dart';
import 'view_models/project_view_model.dart';
import 'view_models/user_view_model.dart';
import 'services/connectivity_service.dart';
import 'services/notification_service.dart';
import 'screens/splash_screen.dart';

void main() async {
  // Ensure Flutter is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize user view model to check if user is logged in
  final userViewModel = UserViewModel();
  await userViewModel.initialize();    runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => userViewModel),
        ChangeNotifierProvider(create: (_) => TreeViewModel()),
        ChangeNotifierProvider(create: (_) => ProjectViewModel()),
        ChangeNotifierProvider(create: (_) => ConnectivityService()),
        ChangeNotifierProvider(create: (_) => NotificationService()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PMI Tree Tracker',
      debugShowCheckedModeBanner: false,      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2E7D32),
          primary: const Color(0xFF2E7D32), // Forest Green for primary actions
          secondary: const Color(0xFFF15A29), // Orange-Red for destructive actions
          tertiary: const Color(0xFF00AEEF), // PMI Blue for links and accents
          surface: Colors.white,
          onSurface: const Color(0xFF333333), // Charcoal for headings
          onBackground: Colors.black, // Black for body text
          surfaceVariant: const Color(0xFF662D91), // Purple from PMI-Kenya logo
          error: const Color(0xFFF15A29), // Use Orange-Red for errors too
        ),
        useMaterial3: true,
        fontFamily: 'Segoe UI', // Sans-serif clean font
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Color(0xFF333333),
            fontFamily: 'Segoe UI',
          ),
          headlineMedium: TextStyle(
            fontWeight: FontWeight.bold, 
            color: Color(0xFF333333),
            fontFamily: 'Segoe UI',
          ),
          titleLarge: TextStyle(
            fontWeight: FontWeight.w600, 
            color: Color(0xFF333333),
            fontFamily: 'Segoe UI',
          ),
          bodyLarge: TextStyle(
            color: Color(0xFF333333),
            fontFamily: 'Segoe UI',
          ),
          bodyMedium: TextStyle(
            color: Color(0xFF333333),
            fontFamily: 'Segoe UI',
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
        ),
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        iconTheme: IconThemeData(
          color: const Color(0xFF2E7D32).withOpacity(0.8),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF2E7D32),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color(0xFFF15A29), // Orange-Red for action buttons
          foregroundColor: Colors.white,
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
