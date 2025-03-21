import 'package:flutter/material.dart';
import 'package:nutrigen/screens/login_screen.dart';
import 'package:nutrigen/screens/contact_support_screen.dart';
import 'package:nutrigen/screens/notification_preferences_screen.dart';
import 'package:nutrigen/screens/terms_conditions_screen.dart';
import 'package:nutrigen/screens/account_information_screen.dart';
import 'package:nutrigen/screens/personal_details_edit.dart';
import 'package:nutrigen/screens/diet_edit.dart';
import 'package:nutrigen/screens/api_settings_screen.dart'; // New import
import 'package:nutrigen/services/profile_service.dart';
import 'package:nutrigen/services/auth_service.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final ProfileService _profileService = ProfileService();
  final AuthService _authService = AuthService();
  bool _isLoading = true;
  Map<String, dynamic>? _userProfile;
  String _errorMessage = '';

  // Base URL for the backend server
  final String _baseUrl = 'http://localhost:5000';

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  // Get the complete profile image URL
  String? _getProfileImageUrl() {
    if (_userProfile == null || _userProfile!['profilePicture'] == null) {
      return null;
    }
    return '$_baseUrl/uploads/profile-pictures/${_userProfile!['profilePicture']}';
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _profileService.getUserProfile();
      setState(() {
        _userProfile = response['data'];
        _isLoading = false;
      });
      debugPrint('User profile loaded: $_userProfile');

      // Debug the profile image URL
      final imageUrl = _getProfileImageUrl();
      debugPrint('Profile Image URL: $imageUrl');
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load profile data. Please try again.';
        _isLoading = false;
      });
      debugPrint('Error loading user profile: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: const Text(
          'Profile Settings',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.black87),
            onPressed: () {
              // Show delete account confirmation
              showDialog(
                context: context,
                builder:
                    (context) => AlertDialog(
                      title: const Text('Delete Account?'),
                      content: const Text(
                        'This action cannot be undone. All your data will be permanently deleted.',
                      ),
                      actions: [
                        TextButton(
                          child: const Text('Cancel'),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        TextButton(
                          child: const Text(
                            'Delete',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            // Delete account logic would go here
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
              );
            },
          ),
        ],
      ),
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFCC1C14)),
              )
              : _errorMessage.isNotEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _errorMessage,
                      style: const TextStyle(color: Colors.red),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _loadUserProfile,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC1C14),
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
              : SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile card
                      Card(
                        elevation: 0,
                        color: Colors.red.shade50,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: Colors.grey.shade200),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              _buildProfileImage(),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _userProfile != null
                                          ? _userProfile!['name'] ?? 'User'
                                          : 'User',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      _userProfile != null &&
                                              _userProfile!['email'] != null
                                          ? _userProfile!['email']
                                          : 'Not specified',
                                      style: TextStyle(
                                        color: Colors.grey.shade600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              TextButton(
                                child: const Text(
                                  'Edit',
                                  style: TextStyle(
                                    color: Color(0xFFCC1C14),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                onPressed: () async {
                                  // Navigate to account information screen
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder:
                                          (context) => AccountInformationScreen(
                                            name: _userProfile!['name'],
                                            email: _userProfile!['email'],
                                            gender: _userProfile!['gender'],
                                            profilePicture:
                                                _getProfileImageUrl(),
                                          ),
                                    ),
                                  );

                                  // Reload user profile if changes were made
                                  if (result == true) {
                                    _loadUserProfile();
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Account Settings section
                      const Text(
                        'Account Settings',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Personal Details
                      _buildSettingItem(
                        context,
                        icon: Icons.person,
                        title: 'Personal Details',
                        subtitle: 'Edit your personal details with ease',
                        onTap: () async {
                          // Navigate to Personal Details Edit screen
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => PersonalDetailsEditScreen(
                                    userProfile: _userProfile,
                                  ),
                            ),
                          );

                          // Reload user profile if changes were made
                          if (result == true) {
                            _loadUserProfile();
                          }
                        },
                      ),

                      // Diet Preferences
                      _buildSettingItem(
                        context,
                        icon: Icons.restaurant_menu,
                        title: 'Diet Preferences',
                        subtitle: 'Manage your dietary preferences securely.',
                        onTap: () async {
                          // Navigate to Diet Edit screen
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => DietEditScreen(
                                    healthGoals:
                                        _userProfile!['healthGoals']
                                            as List<dynamic>? ??
                                        [],
                                    dietPreferences:
                                        _userProfile!['dietPreferences']
                                            as List<dynamic>? ??
                                        [],
                                    allergies:
                                        _userProfile!['allergies']
                                            as List<dynamic>? ??
                                        [],
                                  ),
                            ),
                          );

                          // Reload user profile if changes were made
                          if (result == true) {
                            _loadUserProfile();
                          }
                        },
                      ),

                      // AI API Settings (NEW)
                      _buildSettingItem(
                        context,
                        icon: Icons.api,
                        title: 'AI API Settings',
                        subtitle: 'Configure the AI model connection settings.',
                        onTap: () {
                          // Navigate to API Settings screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const ApiSettingsScreen(),
                            ),
                          );
                        },
                      ),

                      // Notifications Preferences
                      _buildSettingItem(
                        context,
                        icon: Icons.notifications,
                        title: 'Notifications Preferences',
                        subtitle: 'Set your notification preferences.',
                        onTap: () {
                          // Navigate to Notifications Preferences screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) =>
                                      const NotificationPreferencesScreen(),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Help & Support section
                      const Text(
                        'Help & Support',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Contact & Support
                      _buildSettingItem(
                        context,
                        icon: Icons.headset_mic,
                        title: 'Contact & Support',
                        subtitle: 'Reach out for help or feedback.',
                        onTap: () {
                          // Navigate to Contact & Support screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const ContactSupportScreen(),
                            ),
                          );
                        },
                      ),

                      // Terms & Conditions
                      _buildSettingItem(
                        context,
                        icon: Icons.description,
                        title: 'Terms & Conditions',
                        subtitle: 'Learn our community rules.',
                        onTap: () {
                          // Navigate to Terms & Conditions screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => const TermsConditionsScreen(),
                            ),
                          );
                        },
                      ),

                      // Log out
                      _buildSettingItem(
                        context,
                        icon: Icons.logout,
                        title: 'Log out',
                        subtitle: 'Sign out of your account.',
                        onTap: () {
                          // Show logout confirmation
                          showDialog(
                            context: context,
                            builder:
                                (context) => AlertDialog(
                                  title: const Text('Log Out?'),
                                  content: const Text(
                                    'Are you sure you want to log out?',
                                  ),
                                  actions: [
                                    TextButton(
                                      child: const Text('Cancel'),
                                      onPressed:
                                          () => Navigator.of(context).pop(),
                                    ),
                                    TextButton(
                                      child: const Text('Log Out'),
                                      onPressed: () async {
                                        // Log out logic
                                        await _authService.logout();

                                        if (!mounted) return;

                                        // Navigate to login screen and clear all previous routes
                                        Navigator.of(
                                          context,
                                        ).pushAndRemoveUntil(
                                          MaterialPageRoute(
                                            builder:
                                                (context) =>
                                                    const LoginScreen(),
                                          ),
                                          (route) =>
                                              false, // Remove all previous routes
                                        );
                                      },
                                    ),
                                  ],
                                ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
    );
  }

  // Widget to build the profile image with proper error handling
  Widget _buildProfileImage() {
    final imageUrl = _getProfileImageUrl();

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade300,
      ),
      child:
          imageUrl != null
              ? ClipRRect(
                borderRadius: BorderRadius.circular(30),
                child: Image.network(
                  imageUrl,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    debugPrint('Error loading profile image: $error');
                    // Fallback to icon on error
                    return const Icon(
                      Icons.person,
                      size: 30,
                      color: Colors.white,
                    );
                  },
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value:
                            loadingProgress.expectedTotalBytes != null
                                ? loadingProgress.cumulativeBytesLoaded /
                                    loadingProgress.expectedTotalBytes!
                                : null,
                        color: const Color(0xFFCC1C14),
                        strokeWidth: 2,
                      ),
                    );
                  },
                ),
              )
              : const Icon(Icons.person, size: 30, color: Colors.white),
    );
  }

  Widget _buildSettingItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 0,
      color: Colors.red.shade50,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: const Color(0xFFCC1C14), size: 20),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_ios, color: Colors.grey, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
