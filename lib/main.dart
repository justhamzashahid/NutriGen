import 'package:flutter/material.dart';
import 'package:nutrigen/screens/onboarding_screen.dart';
import 'package:nutrigen/screens/login_screen.dart';
import 'package:nutrigen/screens/signup_screen.dart';
import 'package:nutrigen/screens/home_screen.dart';
import 'package:nutrigen/screens/personal_details_screen.dart';
import 'package:nutrigen/screens/main_navigation.dart';

// Import Admin Screens
import 'package:nutrigen/screens/admin/admin_dashboard_screen.dart';
import 'package:nutrigen/screens/admin/admin_users_screen.dart';
import 'package:nutrigen/screens/admin/admin_settings_screen.dart';
import 'package:nutrigen/screens/admin/admin_analytics_screen.dart';
import 'package:nutrigen/screens/admin/admin_user_details_screen.dart';

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
        fontFamily: 'SF Pro Display',
      ),

      // Define routes
      routes: {
        // Main App Routes
        '/': (context) => const OnboardingScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/home': (context) => const HomeScreen(),
        '/personal-details': (context) => const PersonalDetailsScreen(),
        '/main-navigation': (context) => const MainNavigation(),

        // Admin Dashboard Routes (accessed after login)
        '/admin/dashboard': (context) => const AdminDashboardScreen(),
        '/admin/users': (context) => const AdminUsersScreen(),
        '/admin/settings': (context) => const AdminSettingsScreen(),
        '/admin/analytics': (context) => const AdminAnalyticsScreen(),
      },

      // Handle dynamic routes (like user details with ID parameter)
      onGenerateRoute: (settings) {
        // Handle admin user details route with user ID parameter
        if (settings.name?.startsWith('/admin/users/') == true) {
          final userId = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => AdminUserDetailsScreen(userId: userId),
            settings: settings,
          );
        }

        return null;
      },
    );
  }
}
