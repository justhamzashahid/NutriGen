import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:nutrigen/models/nutritionist_model.dart';

class NutritionistService {
  static Future<List<Nutritionist>> getNutritionists() async {
    try {
      // Load the JSON file
      final String jsonString = await rootBundle.loadString(
        'assets/data/nutritionists.json',
      );
      final Map<String, dynamic> jsonData = json.decode(jsonString);

      // Convert JSON to Nutritionist objects
      final List<Nutritionist> nutritionists =
          (jsonData['nutritionists'] as List)
              .map((json) => Nutritionist.fromMap(json))
              .toList();

      return nutritionists;
    } catch (e) {
      print('Error loading nutritionists: $e');
      return [];
    }
  }
}
