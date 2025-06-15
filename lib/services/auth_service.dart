import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String _tokenKey = 'auth_token';
  static const String _adminTokenKey = 'admin_token';
  static const String _userDataKey = 'user_data';
  static const String _adminKey = 'is_admin';

  // Get auth token
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  // Set auth token
  Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  // Get admin token
  Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adminTokenKey);
  }

  // Set admin token
  Future<void> setAdminToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adminTokenKey, token);
    await prefs.setBool(_adminKey, true);
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminKey) ?? false;
  }

  // Save user data
  Future<void> saveUserData(Map<String, dynamic> userData) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userDataKey, json.encode(userData));

    // Save user ID separately for easy access
    if (userData['id'] != null) {
      await prefs.setString('user_id', userData['id'].toString());
    }
  }

  // Get user data
  Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString(_userDataKey);
    if (userDataString != null) {
      return json.decode(userDataString);
    }
    return null;
  }

  // Signup method
  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/signup'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'name': name, 'email': email, 'password': password}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 201) {
        if (responseData['success'] == true) {
          final userData = responseData['data']['user'];
          final token = responseData['data']['token'];

          await setToken(token);
          await saveUserData(userData);

          return responseData; // Return the full response structure
        } else {
          throw Exception(responseData['message'] ?? 'Signup failed');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Signup failed');
      }
    } catch (e) {
      print('Signup error: $e');
      rethrow;
    }
  }

  // Login method that handles both regular users and admin
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      print('Attempting login for: $email');

      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email, 'password': password}),
      );

      print('Login response status: ${response.statusCode}');
      print('Login response body: ${response.body}');

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        if (responseData['success'] == true) {
          final userData = responseData['data']['user'];
          final token = responseData['data']['token'];

          // Check if user is admin
          if (userData['role'] == 'admin') {
            print('Admin user detected');
            await setAdminToken(token);
            await saveUserData(userData);

            // Return admin-specific response with correct structure
            return {
              'success': true,
              'data': {
                'user': {
                  'id': userData['id'],
                  'name': userData['name'],
                  'email': userData['email'],
                  'role': userData['role'],
                  'isEmailVerified': true, // Admin is always verified
                  'isOnboardingCompleted':
                      true, // Admin doesn't need onboarding
                  'lastLogin': userData['lastLogin'],
                },
                'token': token,
              },
            };
          } else {
            // Regular user
            print('Regular user detected');
            await setToken(token);
            await saveUserData(userData);

            return responseData; // Return the full response structure
          }
        } else {
          throw Exception(responseData['message'] ?? 'Login failed');
        }
      } else {
        throw Exception(responseData['message'] ?? 'Login failed');
      }
    } catch (e) {
      print('Login error: $e');
      rethrow;
    }
  }

  // Email verification
  Future<Map<String, dynamic>> verifyEmail(String userId, String code) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-email'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'code': code}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Email verification failed');
      }
    } catch (e) {
      print('Email verification error: $e');
      rethrow;
    }
  }

  // Resend verification code
  Future<Map<String, dynamic>> resendVerificationCode(String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/resend-verification'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(
          responseData['message'] ?? 'Failed to resend verification code',
        );
      }
    } catch (e) {
      print('Resend verification error: $e');
      rethrow;
    }
  }

  // Forgot password
  Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to send reset code');
      }
    } catch (e) {
      print('Forgot password error: $e');
      rethrow;
    }
  }

  // Reset password
  Future<Map<String, dynamic>> resetPassword(
    String userId,
    String code,
    String newPassword,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'userId': userId,
          'code': code,
          'newPassword': newPassword,
        }),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      print('Reset password error: $e');
      rethrow;
    }
  }

  // Verify reset password code
  Future<Map<String, dynamic>> verifyResetPasswordCode(
    String userId,
    String code,
  ) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-reset-code'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'userId': userId, 'code': code}),
      );

      final responseData = json.decode(response.body);

      if (response.statusCode == 200) {
        return responseData;
      } else {
        throw Exception(responseData['message'] ?? 'Invalid verification code');
      }
    } catch (e) {
      print('Verify reset code error: $e');
      rethrow;
    }
  }

  // Logout method
  Future<void> logout() async {
    // Get user ID before clearing the token
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

    // Clear all auth data
    await prefs.remove(_tokenKey);
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_userDataKey);
    await prefs.remove(_adminKey);

    // Also clear chat history from shared preferences
    if (userId != null) {
      await prefs.remove('chat_history_$userId');
      // Don't remove meal plans as they should persist
    }

    // Clear user ID from local storage
    await prefs.remove('user_id');
  }
}
