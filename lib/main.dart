import 'package:flutter/material.dart';
import 'package:nutrigen/screens/onboarding_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NutriGen',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFCC1C14)),
        useMaterial3: true,
        fontFamily:
            'SF Pro Display', // If you have this font, otherwise it will use default
      ),
      home: const OnboardingScreen(),
    );
  }
}
