import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'splash_screen.dart';
import 'firebase_options.dart';

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
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EduHub',

      // Routes can still exist, but dashboard now expects username dynamically
      routes: {
        // "/dashboard": (context) => const StudentDashboardPage(username: 'user'),
        // It's better to navigate to dashboard after login with username
      },

      home: const SplashScreen(),
    );
  }
}
