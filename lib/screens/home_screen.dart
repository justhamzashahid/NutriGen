import 'package:flutter/material.dart';
import 'package:nutrigen/screens/main_navigation.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // This will make sure navigation happens after the widget is built
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const MainNavigation()),
      );
    });

    // Just a placeholder while redirecting
    return const Scaffold(
      body: Center(child: CircularProgressIndicator(color: Color(0xFFCC1C14))),
    );
  }
}
