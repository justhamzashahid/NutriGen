import 'package:nutrigen/services/api_client.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  final ApiClient _apiClient = ApiClient();

  static String? _tempVerificationCode;

  static void setVerificationCode(String code) {
    _tempVerificationCode = code;
  }

  static String? getVerificationCode() {
    final code = _tempVerificationCode;
    _tempVerificationCode = null;  
    return code;
  }

  Future<Map<String, dynamic>> signup(
    String name,
    String email,
    String password,
  ) async {
    final response = await _apiClient.post('/auth/signup', {
      'name': name,
      'email': email,
      'password': password,
    }, requiresAuth: false);

    if (response['token'] != null) {
      await _apiClient.setToken(response['token']);

       
      if (response['user'] != null && response['user']['id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', response['user']['id']);
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> login(String email, String password) async {
    final response = await _apiClient.post('/auth/login', {
      'email': email,
      'password': password,
    }, requiresAuth: false);

    if (response['token'] != null) {
      await _apiClient.setToken(response['token']);

       
      if (response['user'] != null && response['user']['id'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_id', response['user']['id']);
      }
    }

    return response;
  }

  Future<Map<String, dynamic>> verifyEmail(String userId, String code) async {
    return await _apiClient.post('/auth/verify-email', {
      'userId': userId,
      'code': code,
    });
  }

  Future<Map<String, dynamic>> resendVerificationCode(String userId) async {
    return await _apiClient.post('/auth/resend-verification', {
      'userId': userId,
    });
  }

  Future<Map<String, dynamic>> forgotPassword(String email) async {
    return await _apiClient.post('/auth/forgot-password', {
      'email': email,
    }, requiresAuth: false);
  }

  Future<Map<String, dynamic>> resetPassword(
    String userId,
    String code,
    String newPassword,
  ) async {
    return await _apiClient.post('/auth/reset-password', {
      'userId': userId,
      'code': code,
      'newPassword': newPassword,
    }, requiresAuth: false);
  }

  Future<Map<String, dynamic>> verifyResetPasswordCode(
    String userId,
    String code,
  ) async {
    return await _apiClient.post('/auth/verify-reset-code', {
      'userId': userId,
      'code': code,
    }, requiresAuth: false);
  }

  Future<void> logout() async {
     
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');

     
    await _apiClient.clearToken();

     
    if (userId != null) {
      await prefs.remove('chat_history_$userId');
       
    }

     
    await prefs.remove('user_id');
  }
}
