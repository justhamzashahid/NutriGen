import 'package:flutter/material.dart';
import 'package:nutrigen/services/gemini_service.dart';
import 'package:nutrigen/screens/chatbot.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealPlansScreen extends StatefulWidget {
  const MealPlansScreen({Key? key}) : super(key: key);

  @override
  State<MealPlansScreen> createState() => _MealPlansScreenState();
}

class _MealPlansScreenState extends State<MealPlansScreen> {
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _foodController = TextEditingController();
  bool _isLoading = true;
  bool _isAnalyzingFood = false;
  Map<String, dynamic>? _mealPlanData;
  String? _userId;
  Map<String, bool> _eatenMeals = {};

  // Meal recommendations from meal plan
  List<Map<String, dynamic>> breakfastRecommendations = [];
  List<Map<String, dynamic>> lunchRecommendations = [];
  List<Map<String, dynamic>> dinnerRecommendations = [];
  List<Map<String, dynamic>> snacksRecommendations = []; // Added snacks

  @override
  void initState() {
    super.initState();
    _getUserId();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
    debugPrint('User ID loaded: $_userId');
    _loadMealPlanData();
  }

  Future<void> _loadMealPlanData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      if (_userId == null) {
        setState(() {
          _isLoading = false;
          _mealPlanData = null;
        });
        return;
      }

      final mealPlanData = await _geminiService.getTodaysMealPlan(_userId!);

      if (mealPlanData != null) {
        setState(() {
          _mealPlanData = mealPlanData;

          // Get eaten status from backend data
          _eatenMeals = {
            'breakfast': mealPlanData['breakfast']?['eaten'] ?? false,
            'lunch': mealPlanData['lunch']?['eaten'] ?? false,
            'dinner': mealPlanData['dinner']?['eaten'] ?? false,
            'snacks': mealPlanData['snacks']?['eaten'] ?? false, // Added snacks
          };

          // Create meal recommendations
          if (mealPlanData['breakfast'] != null) {
            breakfastRecommendations = [
              {
                'name': mealPlanData['breakfast']['title'],
                'description':
                    'Personalized breakfast based on your genetic profile',
                'calories': mealPlanData['breakfast']['calories'],
                'protein': mealPlanData['breakfast']['protein'],
                'carbs': mealPlanData['breakfast']['carbs'],
                'fat': mealPlanData['breakfast']['fat'],
                'selected': true,
                'icon': Icons.breakfast_dining,
              },
            ];
          }

          if (mealPlanData['lunch'] != null) {
            lunchRecommendations = [
              {
                'name': mealPlanData['lunch']['title'],
                'description':
                    'Personalized lunch based on your genetic profile',
                'calories': mealPlanData['lunch']['calories'],
                'protein': mealPlanData['lunch']['protein'],
                'carbs': mealPlanData['lunch']['carbs'],
                'fat': mealPlanData['lunch']['fat'],
                'selected': true,
                'icon': Icons.lunch_dining,
              },
            ];
          }

          if (mealPlanData['dinner'] != null) {
            dinnerRecommendations = [
              {
                'name': mealPlanData['dinner']['title'],
                'description':
                    'Personalized dinner based on your genetic profile',
                'calories': mealPlanData['dinner']['calories'],
                'protein': mealPlanData['dinner']['protein'],
                'carbs': mealPlanData['dinner']['carbs'],
                'fat': mealPlanData['dinner']['fat'],
                'selected': true,
                'icon': Icons.dinner_dining,
              },
            ];
          }

          // Add snacks if they exist
          if (mealPlanData['snacks'] != null) {
            snacksRecommendations = [
              {
                'name': mealPlanData['snacks']['title'],
                'description':
                    'Personalized snacks based on your genetic profile',
                'calories': mealPlanData['snacks']['calories'],
                'protein': mealPlanData['snacks']['protein'],
                'carbs': mealPlanData['snacks']['carbs'],
                'fat': mealPlanData['snacks']['fat'],
                'selected': true,
                'icon': Icons.icecream,
              },
            ];
          } else {
            snacksRecommendations = [];
          }

          _isLoading = false;
        });
      } else {
        setState(() {
          _mealPlanData = null;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading meal plan data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Toggle meal eaten status and update in backend
  void _toggleMealEaten(String mealType) async {
    // Update UI immediately for better user experience
    setState(() {
      _eatenMeals[mealType] = !(_eatenMeals[mealType] ?? false);
    });

    try {
      // Update in backend
      final success = await _geminiService.updateMealEatenStatus(
        mealType,
        _eatenMeals[mealType] ?? false,
      );

      if (!success) {
        // Revert UI change if backend update failed
        setState(() {
          _eatenMeals[mealType] = !(_eatenMeals[mealType] ?? false);
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Failed to update meal status')),
          );
        }
      } else {
        // Check if all meals have been eaten and show congratulation message
        _checkAllMealsEaten();
      }
    } catch (e) {
      // Revert UI change on error
      setState(() {
        _eatenMeals[mealType] = !(_eatenMeals[mealType] ?? false);
      });

      debugPrint('Error updating meal eaten status: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating meal status: $e')),
        );
      }
    }
  }

  // Check if all meals are eaten and show a congratulation message
  void _checkAllMealsEaten() {
    if (_mealPlanData == null) return;

    bool allEaten = true;

    // Check breakfast
    if (_mealPlanData!.containsKey('breakfast') &&
        _mealPlanData!['breakfast'] != null) {
      allEaten = allEaten && (_eatenMeals['breakfast'] ?? false);
    }

    // Check lunch
    if (_mealPlanData!.containsKey('lunch') &&
        _mealPlanData!['lunch'] != null) {
      allEaten = allEaten && (_eatenMeals['lunch'] ?? false);
    }

    // Check dinner
    if (_mealPlanData!.containsKey('dinner') &&
        _mealPlanData!['dinner'] != null) {
      allEaten = allEaten && (_eatenMeals['dinner'] ?? false);
    }

    // Check snacks
    if (_mealPlanData!.containsKey('snacks') &&
        _mealPlanData!['snacks'] != null) {
      allEaten = allEaten && (_eatenMeals['snacks'] ?? false);
    }

    if (allEaten) {
      _showCongratulationsDialog();
    }
  }

  // Show congratulations dialog
  void _showCongratulationsDialog() {
    if (!mounted) return;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.celebration, color: Colors.green),
                SizedBox(width: 8),
                Text('Congratulations!'),
              ],
            ),
            content: Text(
              'You have completed your target calories for today! Try to maintain this routine and avoid additional snacking for best results.',
              style: TextStyle(fontSize: 16),
            ),
            actions: [
              TextButton(
                child: Text('OK'),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  // Show dialog to add additional food
  void _showAddFoodDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.food_bank, color: const Color(0xFFCC1C14)),
                SizedBox(width: 8),
                Text('Add Additional Food'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'What did you eat outside your meal plan?',
                  style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _foodController,
                  decoration: InputDecoration(
                    hintText: 'E.g., 2 slices of pizza with cheese',
                    filled: true,
                    fillColor: Colors.grey[100],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
            actions: [
              TextButton(
                child: Text('Cancel'),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC1C14),
                  foregroundColor: Colors.white,
                ),
                onPressed:
                    _isAnalyzingFood
                        ? null
                        : () {
                          if (_foodController.text.trim().isNotEmpty) {
                            _analyzeAndAddFood(_foodController.text);
                            Navigator.of(context).pop();
                          }
                        },
                child:
                    _isAnalyzingFood
                        ? SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                            strokeWidth: 2,
                          ),
                        )
                        : Text('Add Food'),
              ),
            ],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
    );
  }

  // Analyze and add the food to the daily total
  Future<void> _analyzeAndAddFood(String foodDescription) async {
    if (_mealPlanData == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please generate a meal plan first')),
      );
      return;
    }

    setState(() {
      _isAnalyzingFood = true;
    });

    try {
      // Analyze the food using Gemini
      final foodData = await _geminiService.analyzeFoodItem(foodDescription);

      // Add the food to the backend
      final success = await _geminiService.addAdditionalFood({
        'title': foodData['title'],
        'calories': foodData['calories'],
        'protein': foodData['protein'],
        'carbs': foodData['carbs'],
        'fat': foodData['fat'],
      });

      if (success) {
        // Reload meal plan data to reflect changes
        await _loadMealPlanData();

        // Show health message
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              foodData['isHealthy'] == true
                  ? 'Good choice! ${foodData['message']}'
                  : 'It\'s okay to indulge occasionally, but try to stick to your meal plan for better results.',
            ),
            backgroundColor:
                foodData['isHealthy'] == true ? Colors.green : Colors.orange,
            duration: Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      debugPrint('Error analyzing food: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error analyzing food: $e')));
      }
    } finally {
      setState(() {
        _isAnalyzingFood = false;
        _foodController.clear();
      });
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
        title: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.restaurant_menu, color: Colors.black87, size: 20),
            SizedBox(width: 8),
            Text(
              'Meal Schedule',
              style: TextStyle(
                color: Colors.black87,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton:
          _mealPlanData != null
              ? FloatingActionButton(
                onPressed: _showAddFoodDialog,
                backgroundColor: const Color(0xFFCC1C14),
                child: Icon(Icons.add, color: Colors.white),
              )
              : null,
      body:
          _isLoading
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFCC1C14)),
              )
              : SafeArea(
                child:
                    _mealPlanData == null
                        ? _buildNoMealPlanView()
                        : SingleChildScrollView(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Header with date
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    const Text(
                                      'Your Meals Today',
                                      style: TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        border: Border.all(
                                          color: const Color(0xFFCC1C14),
                                          width: 1,
                                        ),
                                        borderRadius: BorderRadius.circular(16),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(
                                            Icons.calendar_today,
                                            size: 16,
                                            color: Color(0xFFCC1C14),
                                          ),
                                          const SizedBox(width: 4),
                                          Text(
                                            DateFormat(
                                              'MMM d',
                                            ).format(DateTime.now()),
                                            style: const TextStyle(
                                              color: Color(0xFFCC1C14),
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 16),

                                // Total daily nutrition
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'Daily Nutrition',
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceAround,
                                        children: [
                                          _buildNutrientInfo(
                                            'Calories',
                                            '${_mealPlanData!['totalCalories']}',
                                            'kcal',
                                            Icons.local_fire_department,
                                            Colors.red,
                                          ),
                                          _buildNutrientInfo(
                                            'Protein',
                                            '${_mealPlanData!['totalProtein']}',
                                            'g',
                                            Icons.fitness_center,
                                            Colors.blue,
                                          ),
                                          _buildNutrientInfo(
                                            'Carbs',
                                            '${_mealPlanData!['totalCarbs']}',
                                            'g',
                                            Icons.grain,
                                            Colors.amber,
                                          ),
                                          _buildNutrientInfo(
                                            'Fat',
                                            '${_mealPlanData!['totalFat']}',
                                            'g',
                                            Icons.opacity,
                                            Colors.green,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),

                                const SizedBox(height: 24),

                                // Breakfast Recommendations
                                if (breakfastRecommendations.isNotEmpty)
                                  _buildMealSection(
                                    'Breakfast',
                                    breakfastRecommendations,
                                  ),

                                // Lunch Recommendations
                                if (lunchRecommendations.isNotEmpty)
                                  _buildMealSection(
                                    'Lunch',
                                    lunchRecommendations,
                                  ),

                                // Dinner Recommendations
                                if (dinnerRecommendations.isNotEmpty)
                                  _buildMealSection(
                                    'Dinner',
                                    dinnerRecommendations,
                                  ),

                                // Snacks Recommendations
                                if (snacksRecommendations.isNotEmpty)
                                  _buildMealSection(
                                    'Snacks',
                                    snacksRecommendations,
                                  ),

                                // Additional foods section
                                if (_mealPlanData!.containsKey(
                                      'additionalFoods',
                                    ) &&
                                    _mealPlanData!['additionalFoods'] != null &&
                                    _mealPlanData!['additionalFoods'].length >
                                        0)
                                  _buildAdditionalFoodsSection(),

                                const SizedBox(
                                  height: 80,
                                ), // Space for bottom navigation
                              ],
                            ),
                          ),
                        ),
              ),
    );
  }

  Widget _buildAdditionalFoodsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Additional Foods',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...(_mealPlanData!['additionalFoods'] as List)
            .map(
              (food) => Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade100,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.amber.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.fastfood,
                          color: Colors.amber.shade600,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              food['title'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildNutritionChip(
                                  '${food['calories']} kcal',
                                  Colors.red.shade100,
                                ),
                                const SizedBox(width: 4),
                                _buildNutritionChip(
                                  'P: ${food['protein']}g',
                                  Colors.blue.shade100,
                                ),
                                const SizedBox(width: 4),
                                _buildNutritionChip(
                                  'C: ${food['carbs']}g',
                                  Colors.amber.shade100,
                                ),
                                const SizedBox(width: 4),
                                _buildNutritionChip(
                                  'F: ${food['fat']}g',
                                  Colors.green.shade100,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
            .toList(),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildNutritionChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildNoMealPlanView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.restaurant_menu, size: 80, color: Colors.grey),
            const SizedBox(height: 24),
            const Text(
              'No Meal Plan Yet',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            const Text(
              'You don\'t have a meal plan for today. Generate one using the AI chatbot to see your personalized nutrition recommendations.',
              style: TextStyle(fontSize: 16, color: Colors.grey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const AIChatbotScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.chat),
              label: const Text('Generate Meal Plan'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC1C14),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNutrientInfo(
    String label,
    String value,
    String unit,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildMealSection(String title, List<Map<String, dynamic>> meals) {
    String mealType = title.toLowerCase(); // "Breakfast" → "breakfast"

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        ...meals.map((meal) => _buildDetailedMealCard(meal, mealType)).toList(),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildDetailedMealCard(Map<String, dynamic> meal, String mealType) {
    bool isEaten = _eatenMeals[mealType] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade100,
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meal header
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    meal['icon'] ?? Icons.restaurant,
                    color: const Color(0xFFCC1C14),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        meal['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        meal['description'],
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                // Eat status toggle button
                ElevatedButton.icon(
                  onPressed: () => _toggleMealEaten(mealType),
                  icon: Icon(
                    isEaten ? Icons.check_circle : Icons.circle_outlined,
                  ),
                  label: Text(isEaten ? 'Eaten' : 'Mark eaten'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        isEaten ? Colors.green : Colors.grey.shade200,
                    foregroundColor: isEaten ? Colors.white : Colors.black87,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    minimumSize: const Size(80, 30),
                  ),
                ),
              ],
            ),
          ),

          // Divider
          Divider(color: Colors.grey.shade200),

          // Nutrition info
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNutritionItem('Calories', '${meal['calories']}', 'kcal'),
                _buildNutritionItem('Protein', '${meal['protein']}', 'g'),
                _buildNutritionItem('Carbs', '${meal['carbs']}', 'g'),
                _buildNutritionItem('Fat', '${meal['fat']}', 'g'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem(String label, String value, String unit) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        Text(
          '$label ($unit)',
          style: TextStyle(color: Colors.grey[600], fontSize: 12),
        ),
      ],
    );
  }
}
