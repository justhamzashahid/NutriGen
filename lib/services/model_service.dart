import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:nutrigen/services/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelService {
   
  String _baseUrl = '';
  final ConfigService _configService = ConfigService();
  bool _isInitialized = false;

   
  ModelService() {
    _initializeBaseUrl();
  }

   
  Future<void> _initializeBaseUrl() async {
    try {
      _baseUrl = await _configService.getApiUrl();

       
      if (_baseUrl.endsWith('/')) {
        _baseUrl = _baseUrl.substring(0, _baseUrl.length - 1);
      }

      _isInitialized = true;
      debugPrint('ModelService initialized with URL: $_baseUrl');
    } catch (e) {
      debugPrint('Error initializing ModelService: $e');
       
      _baseUrl = 'https://example.com';
      _isInitialized = false;
    }
  }

   
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await _initializeBaseUrl();
    }
  }

   
   
  Future<String> generateResponse({
    required String input,
    String? geneMarker,
    String? age,
    String? gender,
    List<String>? healthGoals,
    List<String>? dietPreferences,
    List<String>? allergies,
    int maxTokens = 1000,
    double temperature = 0.3,
  }) async {
    try {
       
      await _ensureInitialized();

       
       
      const systemPrompt =
          """You are a certified nutritionist specializing in nutrigenomics. Your task is to create personalized meal plans. If a genetic marker is provided, include specific foods that help with that gene. If NO genetic marker is provided, create a general meal plan WITHOUT mentioning or making up any genetic information. Never hallucinate genetic markers. Be precise, practical, and evidence-based in your recommendations.""";

       
      String userPrompt = input;

       
      if (geneMarker != null &&
          geneMarker.toLowerCase() != "null" &&
          geneMarker.trim().isNotEmpty) {
        debugPrint('Including gene marker: $geneMarker');
        userPrompt = "My gene marker is $geneMarker. $userPrompt";
      } else {
        debugPrint('No gene marker provided or marker is null');
        userPrompt =
            "I do not have any gene marker information. Please provide a general nutrition plan without mentioning genetics. $userPrompt";
      }

       
      if (age != null && age.isNotEmpty) {
        userPrompt += " My age is $age.";
      }

      if (gender != null && gender.isNotEmpty) {
        userPrompt += " My gender is $gender.";
      }

      if (healthGoals != null && healthGoals.isNotEmpty) {
        final goalsStr = healthGoals.join(", ");
        userPrompt += " My health goals are: $goalsStr.";
      }

      if (dietPreferences != null && dietPreferences.isNotEmpty) {
        final prefsStr = dietPreferences.join(", ");
        userPrompt += " My dietary preferences are: $prefsStr.";
      }

      if (allergies != null && allergies.isNotEmpty) {
        final allergiesStr = allergies.join(", ");
        userPrompt += " My allergies/food sensitivities are: $allergiesStr.";
      }

       
      final prompt =
          "<|system|>\n$systemPrompt\n<|user|>\n$userPrompt\n<|assistant|>";

       
      final Map<String, dynamic> requestData = {
        'input': input,
        'gene_marker': geneMarker ?? "null",
        'age': age,
        'gender': gender,
        'health_goals': healthGoals,
        'diet_preferences': dietPreferences,
        'allergies': allergies,
        'max_tokens': maxTokens,
        'temperature': temperature,
        'prompt': prompt,  
      };

      debugPrint('Sending request to: $_baseUrl/generate');
      debugPrint('Request data: ${json.encode(requestData)}');

      final response = await http.post(
        Uri.parse('$_baseUrl/generate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Access-Control-Allow-Origin': '*',
        },
        body: json.encode(requestData),
      );

      debugPrint('Response status code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final modelResponse = data['response'];
        return modelResponse;
      } else {
        debugPrint('Error response body: ${response.body}');
        throw Exception('Failed to generate response: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error generating response: $e');
      throw Exception('Error connecting to the model service: $e');
    }
  }

   
  Future<bool> checkApiAvailability() async {
    try {
       
      await _ensureInitialized();

      debugPrint('Checking API availability at: $_baseUrl');

      final response = await http
          .get(
            Uri.parse('$_baseUrl/'),
            headers: {
              'Accept': 'application/json',
              'Access-Control-Allow-Origin': '*',
            },
          )
          .timeout(const Duration(seconds: 10));

      debugPrint('API check response: ${response.statusCode}');

      return response.statusCode == 200;
    } catch (e) {
      debugPrint('API availability check failed: $e');
      return false;
    }
  }

   
  bool isMealPlanRequest(String input) {
    final lowercaseInput = input.toLowerCase();
    final mealPlanKeywords = [
      'meal plan',
      'diet plan',
      'eating plan',
      'nutrition plan',
      'food plan',
      'generate meal',
      'create meal',
      'suggest meal',
      'what should i eat',
      'recommend meal',
    ];

    return mealPlanKeywords.any((keyword) => lowercaseInput.contains(keyword));
  }
}
