import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:nutrigen/services/api_client.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyBwUS1iSnIJ3d64zJCoQL2G0iA42AMs-HE';
  static const String _baseApiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models';
  static const String _modelName = 'gemini-2.0-flash';

  final ApiClient _apiClient = ApiClient();

  static final GeminiService _instance = GeminiService._internal();
  factory GeminiService() => _instance;
  GeminiService._internal();

  /// Direct call to Gemini API for general text processing
  Future<String> callGeminiApi(String prompt) async {
    try {
      final url = '$_baseApiUrl/$_modelName:generateContent?key=$_apiKey';

      final requestBody = {
        'contents': [
          {
            'parts': [
              {'text': prompt},
            ],
          },
        ],
        'generationConfig': {
          'temperature': 0.1,
          'topK': 1,
          'topP': 1,
          'maxOutputTokens': 2048,
          'stopSequences': [],
        },
        'safetySettings': [
          {
            'category': 'HARM_CATEGORY_HARASSMENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_HATE_SPEECH',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
          {
            'category': 'HARM_CATEGORY_DANGEROUS_CONTENT',
            'threshold': 'BLOCK_MEDIUM_AND_ABOVE',
          },
        ],
      };

      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: json.encode(requestBody),
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['candidates'] != null &&
            responseData['candidates'].isNotEmpty &&
            responseData['candidates'][0]['content'] != null &&
            responseData['candidates'][0]['content']['parts'] != null &&
            responseData['candidates'][0]['content']['parts'].isNotEmpty) {
          return responseData['candidates'][0]['content']['parts'][0]['text'];
        } else {
          throw Exception('Invalid response structure from Gemini API');
        }
      } else {
        debugPrint(
          'Gemini API error: ${response.statusCode} - ${response.body}',
        );
        throw Exception('Gemini API request failed: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error calling Gemini API: $e');
      throw Exception('Failed to process with Gemini: $e');
    }
  }

  Future<Map<String, dynamic>> refineMealPlanForDashboard(
    String mealPlanResponse,
  ) async {
    try {
      final prompt = """
Extract from the following meal plan the breakfast, lunch, dinner, and any snacks or additional meals. Provide a one-liner summary for each with nutritional information (calories, protein, carbs, fat). Return in JSON format as:
{
  "breakfast": {
    "title": "One-line summary of breakfast",
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number
  },
  "lunch": {
    "title": "One-line summary of lunch",
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number
  },
  "dinner": {
    "title": "One-line summary of dinner",
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number
  },
  "snacks": {
    "title": "One-line summary of snacks or additional meals",
    "calories": number,
    "protein": number,
    "carbs": number,
    "fat": number
  },
  "totalCalories": number,
  "totalProtein": number,
  "totalCarbs": number,
  "totalFat": number
}

Include any additional food items, mid-morning snacks, afternoon snacks, pre-workout meals, or post-workout meals as part of the "snacks" section. If no snacks are explicitly mentioned, set snacks to null.

If nutritional information is not explicitly stated, make a reasonable estimate based on the meal components.

Here's the meal plan:
$mealPlanResponse
""";

      final response = await callGeminiApi(prompt);
      String jsonStr = _extractJsonFromResponse(response);

      try {
        Map<String, dynamic> mealData = json.decode(jsonStr);
        return mealData;
      } catch (e) {
        debugPrint('Error parsing JSON from Gemini API: $e');
        throw Exception('Failed to parse meal plan data: $e');
      }
    } catch (e) {
      debugPrint('Error refining meal plan: $e');
      throw Exception('Error processing meal plan with Gemini API: $e');
    }
  }

  Future<String> beautifyMealPlanForChatbot(String mealPlanResponse) async {
    try {
      final prompt = """
Beautify the following meal plan for display in a chatbot. Remove any markdown or HTML tags, format it nicely with emojis for food items, and maintain all the nutritional information.

Keep the structure clear with proper headings for Breakfast, Lunch, Dinner, and Snacks.
Add appropriate food emojis (🥗 🍗 🥕 🍎 etc.) to make it visually appealing.
Keep all nutritional details and explanations.

Original meal plan:
$mealPlanResponse

Return the beautified version:
""";

      final response = await callGeminiApi(prompt);
      return response.trim();
    } catch (e) {
      debugPrint('Error beautifying meal plan: $e');
      // Return original if beautification fails
      return mealPlanResponse;
    }
  }

  String _extractJsonFromResponse(String response) {
    // Try to find JSON content in the response
    final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }

    // If no JSON found, try to extract content between code blocks
    final codeBlockMatch = RegExp(
      r'```(?:json)?\s*(\{[\s\S]*?\})\s*```',
      caseSensitive: false,
    ).firstMatch(response);
    if (codeBlockMatch != null) {
      return codeBlockMatch.group(1)!;
    }

    // If still no JSON, return the response as-is and let json.decode handle the error
    return response;
  }

  Future<void> saveTodaysMealPlan(
    Map<String, dynamic> mealPlan,
    String userId,
  ) async {
    try {
      await _apiClient.post('/meal-plans/today', mealPlan);
      debugPrint('Meal plan saved to backend successfully for user: $userId');
    } catch (e) {
      debugPrint('Error saving meal plan to backend: $e');
      throw Exception('Failed to save meal plan to backend: $e');
    }
  }

  Future<Map<String, dynamic>?> getTodaysMealPlan(String userId) async {
    try {
      final response = await _apiClient.get('/meal-plans/today');

      if (response['success'] == true && response['data'] != null) {
        return response['data'];
      }

      return null;
    } catch (e) {
      debugPrint('Error getting meal plan from backend: $e');
      return null;
    }
  }

  Future<bool> updateMealEatenStatus(String mealType, bool eaten) async {
    try {
      final response = await _apiClient.post('/meal-plans/meal-status', {
        'mealType': mealType,
        'eaten': eaten,
      });

      return response['success'] == true;
    } catch (e) {
      debugPrint('Error updating meal eaten status: $e');
      throw Exception('Failed to update meal status: $e');
    }
  }

  Future<Map<String, dynamic>> analyzeFoodItem(String foodDescription) async {
    try {
      final prompt = """
Analyze the following food item and estimate its nutritional content. 
Return ONLY a JSON object with the following structure:
{
  "title": "Brief description of the food",
  "calories": number (integer),
  "protein": number (integer, grams),
  "carbs": number (integer, grams),
  "fat": number (integer, grams),
  "isHealthy": boolean,
  "message": "Brief health message about this food"
}

Food item: $foodDescription
""";

      final response = await callGeminiApi(prompt);
      debugPrint('Gemini food analysis response: $response');

      String jsonStr = _extractJsonFromResponse(response);

      try {
        Map<String, dynamic> foodData = json.decode(jsonStr);
        return foodData;
      } catch (e) {
        debugPrint('Error parsing JSON from Gemini API: $e');
        throw Exception('Failed to parse food analysis data: $e');
      }
    } catch (e) {
      debugPrint('Error analyzing food item: $e');
      throw Exception('Error processing food analysis with Gemini API: $e');
    }
  }

  Future<bool> addAdditionalFood(Map<String, dynamic> foodData) async {
    try {
      final response = await _apiClient.post(
        '/meal-plans/additional-food',
        foodData,
      );
      return response['success'] == true;
    } catch (e) {
      debugPrint('Error adding additional food: $e');
      throw Exception('Failed to record additional food: $e');
    }
  }
}
