import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/result_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inisialisasi AdMob
  await MobileAds.instance.initialize();

  runApp(const MalasNulisApp());
}

class MalasNulisApp extends StatelessWidget {
  const MalasNulisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malas Nulis',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.indigo,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      // Layar pertama: RegisterScreen (wajib registrasi dulu)
      home: const RegisterScreen(),
      routes: {
        '/home': (context) => const HomeScreen(),
        '/result': (context) => const ResultScreen(),
      },
    );
  }
}