import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:nutrigen/services/config_service.dart';
import 'package:nutrigen/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ModelService {
  String _baseUrl = '';
  final ConfigService _configService = ConfigService();
  final GeminiService _geminiService = GeminiService();
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

  /// Enhanced response generation with Gemini post-processing
  Future<String> generateResponse({
    required String input,
    String? geneMarker,
    String? age,
    String? gender,
    List<String>? healthGoals,
    List<String>? dietPreferences,
    List<String>? allergies,
    List<Map<String, dynamic>>? chatHistory,
    int maxTokens = 1000,
    double temperature = 0.3,
  }) async {
    try {
      await _ensureInitialized();

      final isNutritionRelated = await _checkIfNutritionRelated(input);

      if (!isNutritionRelated) {
        await Future.delayed(const Duration(seconds: 12));
        return "This is out of my domain, please ask me Nutrition related questions";
      }

      // Step 2: Generate response from fine-tuned model
      final modelResponse = await _generateFromFineTunedModel(
        input: input,
        geneMarker: geneMarker,
        age: age,
        gender: gender,
        healthGoals: healthGoals,
        dietPreferences: dietPreferences,
        allergies: allergies,
        maxTokens: maxTokens,
        temperature: temperature,
      );

      // Step 3: Post-process with Gemini to tailor response to user input and chat history
      final tailoredResponse = await _tailorResponseWithGemini(
        originalResponse: modelResponse,
        userInput: input,
        chatHistory: chatHistory,
        geneMarker: geneMarker,
        userProfile: {
          'age': age,
          'gender': gender,
          'healthGoals': healthGoals,
          'dietPreferences': dietPreferences,
          'allergies': allergies,
        },
      );

      return tailoredResponse;
    } catch (e) {
      debugPrint('Error in generateResponse: $e');
      throw Exception('Error connecting to the nutrition service: $e');
    }
  }

  /// Check if user input is nutrition/meal plan related using Gemini
  Future<bool> _checkIfNutritionRelated(String input) async {
    try {
      final prompt = """
Analyze if the following user input is related to nutrition, meal planning, diet, food, health, or wellness.

User input: "$input"

Return ONLY "YES" if it's nutrition-related, or "NO" if it's not nutrition-related.

Examples of nutrition-related: meal plans, diet advice, food recommendations, calories, nutrients, cooking, recipes, health goals, weight management, etc.

Examples of non-nutrition-related: weather, sports scores, programming, movies, politics, etc.

Response:""";

      final response = await _geminiService.callGeminiApi(prompt);
      final isRelated = response.trim().toUpperCase().contains('YES');

      debugPrint('Nutrition check for "$input": $isRelated');
      return isRelated;
    } catch (e) {
      debugPrint('Error checking nutrition relevance: $e');
      // Default to true to avoid blocking nutrition questions if Gemini fails
      return true;
    }
  }

  /// Generate response from your fine-tuned model
  Future<String> _generateFromFineTunedModel({
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
    // System prompt for fine-tuned model
    const systemPrompt =
        """You are a certified nutritionist specializing in nutrigenomics. Your task is to create personalized meal plans. If a genetic marker is provided, include specific foods that help with that gene. If NO genetic marker is provided, create a general meal plan WITHOUT mentioning or making up any genetic information. Never hallucinate genetic markers. Be precise, practical, and evidence-based in your recommendations.""";

    // Build user prompt
    String userPrompt = input;

    if (geneMarker != null &&
        geneMarker.toLowerCase() != "null" &&
        geneMarker.trim().isNotEmpty) {
      userPrompt = "My gene marker is $geneMarker. $input";
    }

    if (healthGoals != null && healthGoals.isNotEmpty) {
      final goalsStr = healthGoals.join(", ");
      userPrompt += " My health goals are: $goalsStr.";
    }

    if (dietPreferences != null && dietPreferences.isNotEmpty) {
      final prefsStr = dietPreferences.join(", ");
      userPrompt += " My diet preferences are: $prefsStr.";
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

    debugPrint('Sending request to fine-tuned model: $_baseUrl/generate');

    final response = await http.post(
      Uri.parse('$_baseUrl/generate'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'Access-Control-Allow-Origin': '*',
      },
      body: json.encode(requestData),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['response'];
    } else {
      debugPrint('Error response from model: ${response.body}');
      throw Exception('Failed to generate response: ${response.statusCode}');
    }
  }

  /// Tailor the model response using Gemini based on user input and chat history
  Future<String> _tailorResponseWithGemini({
    required String originalResponse,
    required String userInput,
    List<Map<String, dynamic>>? chatHistory,
    String? geneMarker,
    Map<String, dynamic>? userProfile,
  }) async {
    try {
      // Build context from chat history
      String chatContext = "";
      if (chatHistory != null && chatHistory.isNotEmpty) {
        chatContext = "Previous conversation:\n";
        // Only include last 3-4 exchanges to keep context manageable
        final recentHistory =
            chatHistory.take(6).toList(); // 3 exchanges (user + assistant)
        for (var message in recentHistory) {
          final sender = message['isUser'] ? 'User' : 'Assistant';
          chatContext += "$sender: ${message['message']}\n";
        }
        chatContext += "\n";
      }

      // Build user profile context
      String profileContext = "";
      if (userProfile != null) {
        if (geneMarker != null &&
            geneMarker.isNotEmpty &&
            geneMarker != "null") {
          profileContext += "User's genetic marker: $geneMarker\n";
        }
        if (userProfile['age'] != null)
          profileContext += "Age: ${userProfile['age']}\n";
        if (userProfile['gender'] != null)
          profileContext += "Gender: ${userProfile['gender']}\n";
        if (userProfile['healthGoals'] != null) {
          profileContext +=
              "Health goals: ${(userProfile['healthGoals'] as List).join(', ')}\n";
        }
        if (userProfile['dietPreferences'] != null) {
          profileContext +=
              "Diet preferences: ${(userProfile['dietPreferences'] as List).join(', ')}\n";
        }
        if (userProfile['allergies'] != null) {
          profileContext +=
              "Allergies: ${(userProfile['allergies'] as List).join(', ')}\n";
        }
      }

      final prompt = """
You are helping to refine a nutrition response. You have an original response from a nutrition model and a user's latest input. Your task is to modify the original response to better address the user's specific request while maintaining the nutritionist's voice and expertise.

${profileContext.isNotEmpty ? 'User Profile:\n$profileContext\n' : ''}${chatContext.isNotEmpty ? '$chatContext' : ''}Current user input: "$userInput"

Original nutrition response:
"$originalResponse"

Instructions:
1. If the user is asking for modifications to a meal plan (like "add more chicken", "make it vegetarian", "reduce calories", etc.), modify the meal plan accordingly
2. If the user is asking a follow-up question, provide a relevant response based on the context
3. Keep the same professional, nutritionist tone and format
4. Don't add extra introductory text or mention that this is a modified response
5. If the original response already perfectly addresses the user's input, you can return it unchanged
6. Make sure any modifications align with the user's profile (genetic marker, diet preferences, allergies, etc.)
7. Don't change the core structure unless specifically requested

Return ONLY the refined response:""";

      final tailoredResponse = await _geminiService.callGeminiApi(prompt);

      return tailoredResponse.trim();
    } catch (e) {
      debugPrint('Error tailoring response with Gemini: $e');
      // If Gemini fails, return the original response
      return originalResponse;
    }
  }

  /// Check API availability
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

  /// Determine if the input is requesting a meal plan
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
