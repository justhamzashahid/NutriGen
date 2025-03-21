import 'package:shared_preferences/shared_preferences.dart';

class ConfigService {
  static const String _apiUrlKey = 'api_url';
  static const String _defaultApiUrl =
      'https://b069-34-27-202-50.ngrok-free.app'; 

   
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

   
  Future<String> getApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_apiUrlKey) ?? _defaultApiUrl;
  }

   
  Future<void> setApiUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, url);
  }

   
  Future<void> resetApiUrl() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_apiUrlKey, _defaultApiUrl);
  }
}
