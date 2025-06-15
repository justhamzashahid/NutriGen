import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminService {
  static const String baseUrl = 'http://localhost:5000/api';
  static const String _adminTokenKey = 'admin_token';
  static const String _adminKey = 'is_admin';

  // Singleton pattern
  static final AdminService _instance = AdminService._internal();
  factory AdminService() => _instance;
  AdminService._internal();

  // Get admin token (same as auth token for admin users)
  Future<String?> getAdminToken() async {
    final prefs = await SharedPreferences.getInstance();
    // Try admin token first, fallback to regular auth token
    return prefs.getString(_adminTokenKey) ?? prefs.getString('auth_token');
  }

  // Check if user is admin
  Future<bool> isAdmin() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_adminKey) ?? false;
  }

  // Get headers with admin token
  Future<Map<String, String>> _getHeaders() async {
    final token = await getAdminToken();
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Handle API errors
  void _handleError(http.Response response) {
    final responseData = json.decode(response.body);
    final message = responseData['message'] ?? 'An error occurred';

    if (response.statusCode == 401) {
      throw Exception('Unauthorized: $message');
    } else if (response.statusCode == 403) {
      throw Exception('Forbidden: $message');
    } else {
      throw Exception(message);
    }
  }

  // Logout admin
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_adminTokenKey);
    await prefs.remove(_adminKey);
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
    debugPrint('Admin logout successful');
  }

  // Get Dashboard Stats
  Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/stats'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        _handleError(response);
        return {};
      }
    } catch (e) {
      debugPrint('Get dashboard stats error: $e');
      rethrow;
    }
  }

  // Get System Health
  Future<Map<String, dynamic>> getSystemHealth() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/health'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        _handleError(response);
        return {};
      }
    } catch (e) {
      debugPrint('Get system health error: $e');
      rethrow;
    }
  }

  // Get Recent Activity
  Future<Map<String, dynamic>> getRecentActivity() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/activity'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        _handleError(response);
        return {};
      }
    } catch (e) {
      debugPrint('Get recent activity error: $e');
      rethrow;
    }
  }

  // Get Chart Data
  Future<Map<String, dynamic>> getChartData() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/chart-data'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        _handleError(response);
        return {};
      }
    } catch (e) {
      debugPrint('Get chart data error: $e');
      rethrow;
    }
  }

  // Get All Users
  Future<Map<String, dynamic>> getAllUsers({
    int page = 1,
    int limit = 10,
    String search = '',
    String status = 'all',
    String sortBy = 'createdAt',
    String sortOrder = 'desc',
  }) async {
    try {
      final headers = await _getHeaders();

      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        'search': search,
        'status': status,
        'sortBy': sortBy,
        'sortOrder': sortOrder,
      };

      final uri = Uri.parse(
        '$baseUrl/admin/users',
      ).replace(queryParameters: queryParams);

      final response = await http.get(uri, headers: headers);

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        _handleError(response);
        return {};
      }
    } catch (e) {
      debugPrint('Get all users error: $e');
      rethrow;
    }
  }

  // Get User Details
  Future<Map<String, dynamic>> getUserDetails(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data'];
      } else {
        _handleError(response);
        return {};
      }
    } catch (e) {
      debugPrint('Get user details error: $e');
      rethrow;
    }
  }

  // Delete User
  Future<void> deleteUser(String userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } catch (e) {
      debugPrint('Delete user error: $e');
      rethrow;
    }
  }

  // Get Ngrok URL
  Future<String> getNgrokUrl() async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/admin/ngrok-url'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['data']['ngrokUrl'] ?? '';
      } else {
        _handleError(response);
        return '';
      }
    } catch (e) {
      debugPrint('Get ngrok URL error: $e');
      rethrow;
    }
  }

  // Update Ngrok URL
  Future<void> updateNgrokUrl(String ngrokUrl) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/admin/ngrok-url'),
        headers: headers,
        body: json.encode({'ngrokUrl': ngrokUrl}),
      );

      if (response.statusCode != 200) {
        _handleError(response);
      }
    } catch (e) {
      debugPrint('Update ngrok URL error: $e');
      rethrow;
    }
  }

  // Search Users
  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    try {
      final usersData = await getAllUsers(
        search: query,
        limit: 50, // Higher limit for search
      );

      return List<Map<String, dynamic>>.from(usersData['users'] ?? []);
    } catch (e) {
      debugPrint('Search users error: $e');
      rethrow;
    }
  }

  // Get Users by Status
  Future<Map<String, dynamic>> getUsersByStatus(String status) async {
    try {
      return await getAllUsers(status: status, limit: 50);
    } catch (e) {
      debugPrint('Get users by status error: $e');
      rethrow;
    }
  }

  // Check connection
  Future<bool> checkConnection() async {
    try {
      final response = await http
          .get(
            Uri.parse('$baseUrl/../'),
            headers: {'Accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 5));

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('Connection check error: $e');
      return false;
    }
  }
}
