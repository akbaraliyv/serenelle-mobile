import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'screens/enchanted_orb_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Configure edge-to-edge transparent system navigation & status bars
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF030104),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const SerenelleDirectApp());
}

class SerenelleDirectApp extends StatelessWidget {
  const SerenelleDirectApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Instagram Direct',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF030104),
        primaryColor: const Color(0xFFE91E63),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFE91E63),
          secondary: Color(0xFFFF2A6D),
          surface: Color(0xFF140E1B),
          background: Color(0xFF030104),
        ),
        fontFamily: 'Roboto',
      ),
      home: const EnchantedOrbScreen(),
    );
  }
}
