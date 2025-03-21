import 'package:flutter/material.dart';
import 'package:nutrigen/services/model_service.dart';
import 'package:nutrigen/services/profile_service.dart';
import 'package:nutrigen/services/gemini_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({Key? key}) : super(key: key);

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final ModelService _modelService = ModelService();
  final ProfileService _profileService = ProfileService();
  final GeminiService _geminiService = GeminiService();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _isApiAvailable = false;
  String? _geneMarker;
  String? _age;
  String? _gender;
  List<String>? _healthGoals;
  List<String>? _dietPreferences;
  List<String>? _allergies;
  String? _userId;

  // Track if we're showing the meal plan acceptance UI
  bool _showMealPlanAcceptance = false;
  String _currentMealPlanResponse = '';

  @override
  void initState() {
    super.initState();
    _getUserId();
    _checkApiAvailability();
    _loadUserProfile();
  }

  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userId = prefs.getString('user_id');
    });
    debugPrint('User ID loaded: $_userId');
    _loadChatHistory();
  }

  Future<void> _checkApiAvailability() async {
    try {
      final isAvailable = await _modelService.checkApiAvailability();
      setState(() {
        _isApiAvailable = isAvailable;
      });

      if (!isAvailable) {
        _showApiUnavailableMessage();
      }
    } catch (e) {
      setState(() {
        _isApiAvailable = false;
      });
      _showApiUnavailableMessage();
    }
  }

  void _showApiUnavailableMessage() {
    setState(() {
      _messages.add({
        'isUser': false,
        'message':
            'The AI service is currently unavailable. We are working to restore service as soon as possible.',
      });
    });
  }

  Future<void> _loadUserProfile() async {
    try {
      final response = await _profileService.getUserProfile();

      if (response['success'] == true) {
        final data = response['data'];
        setState(() {
          _geneMarker = data['geneMarker'];
          _age = data['age']?.toString();
          _gender = data['gender'];

          // Convert lists from dynamic to String
          if (data['healthGoals'] != null) {
            _healthGoals = List<String>.from(
              data['healthGoals'].map((item) => item.toString()),
            );
          }

          if (data['dietPreferences'] != null) {
            _dietPreferences = List<String>.from(
              data['dietPreferences'].map((item) => item.toString()),
            );
          }

          if (data['allergies'] != null) {
            _allergies = List<String>.from(
              data['allergies'].map((item) => item.toString()),
            );
          }
        });

        // Add initial messages only if we don't have chat history
        if (_messages.isEmpty) {
          // Add a message about the genetic marker if available
          if (_geneMarker != null) {
            _messages.add({
              'isUser': false,
              'message':
                  'I see that you have the $_geneMarker genetic marker in your profile. I\'ll use this to provide personalized nutrition recommendations.',
            });
          } else {
            _messages.add({
              'isUser': false,
              'message':
                  'Hello! I\'m your NutriGen assistant. I can help you with personalized nutrition advice based on your genetic profile. How can I help you today?',
            });
          }

          // Check if there's a meal plan for today
          if (_userId != null) {
            final todaysMealPlan = await _geminiService.getTodaysMealPlan(
              _userId!,
            );
            if (todaysMealPlan == null) {
              // No meal plan for today
              _messages.add({
                'isUser': false,
                'message':
                    'I notice you don\'t have a meal plan for today. Would you like me to generate one for you? Just ask for a meal plan.',
              });
            } else {
              // There's a meal plan for today
              _messages.add({
                'isUser': false,
                'message':
                    'I see you already have a meal plan for today. You can view it on your dashboard. Let me know if you have any questions about it!',
              });
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  // Save chat history to local storage
  Future<void> _saveChatHistory() async {
    try {
      if (_userId == null) return; // Don't save if no user ID

      final prefs = await SharedPreferences.getInstance();
      final chatHistory = jsonEncode(_messages);
      await prefs.setString('chat_history_$_userId', chatHistory);
      debugPrint('Chat history saved for user: $_userId');
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  // Load chat history from local storage
  Future<void> _loadChatHistory() async {
    try {
      if (_userId == null) return; // Don't load if no user ID

      final prefs = await SharedPreferences.getInstance();
      final chatHistory = prefs.getString('chat_history_$_userId');

      if (chatHistory != null) {
        final List<dynamic> decoded = jsonDecode(chatHistory);
        setState(() {
          _messages =
              decoded.map((item) => Map<String, dynamic>.from(item)).toList();
        });
        debugPrint('Chat history loaded for user: $_userId');
      } else {
        // Initialize with welcome message if no history
        setState(() {
          _messages = [
            {
              'isUser': false,
              'message':
                  'Hello! I\'m your NutriGen assistant. I can help you with personalized nutrition advice based on your genetic profile. How can I help you today?',
            },
          ];
        });
        debugPrint(
          'No chat history found for user $_userId, initialized with welcome message',
        );
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
    }
  }

  void _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'isUser': true, 'message': message});
      _isLoading = true;
      _messageController.clear();
    });

    // Save chat history
    _saveChatHistory();

    // Scroll to bottom after message is added
    _scrollToBottom();

    if (!_isApiAvailable) {
      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'Sorry, the AI service is currently unavailable. Please try again later.',
        });
        _isLoading = false;
      });
      _scrollToBottom();
      return;
    }

    try {
      // Check if this is a meal plan request
      final isMealPlanRequest = _modelService.isMealPlanRequest(message);

      // Get AI response from the model service
      final modelResponse = await _modelService.generateResponse(
        input: message,
        geneMarker: _geneMarker,
        age: _age,
        gender: _gender,
        healthGoals: _healthGoals,
        dietPreferences: _dietPreferences,
        allergies: _allergies,
      );

      if (isMealPlanRequest) {
        // Store the response for the meal plan acceptance UI
        _currentMealPlanResponse = modelResponse;

        setState(() {
          _messages.add({'isUser': false, 'message': modelResponse});
          _showMealPlanAcceptance = true;
          _isLoading = false;
        });
      } else {
        setState(() {
          _messages.add({'isUser': false, 'message': modelResponse});
          _isLoading = false;
        });
      }

      // Save chat history after receiving response
      _saveChatHistory();

      // Scroll to bottom after response is added
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'Sorry, I encountered an error while generating a response. Please try again later.',
        });
        _isLoading = false;
      });

      // Scroll to bottom after error message is added
      _scrollToBottom();
    }
  }

  // Accept the current meal plan
  Future<void> _acceptMealPlan() async {
    try {
      if (_userId == null) {
        // Can't save without user ID
        setState(() {
          _showMealPlanAcceptance = false;
          _messages.add({
            'isUser': false,
            'message':
                'Sorry, there was an error saving your meal plan. Please try again after logging in.',
          });
        });
        return;
      }

      setState(() {
        _isLoading = true;
        _showMealPlanAcceptance = false;
      });

      // Refine the meal plan for the dashboard using Gemini
      final refinedMealPlan = await _geminiService.refineMealPlanForDashboard(
        _currentMealPlanResponse,
      );

      // Save the refined meal plan to the backend API
      try {
        await _geminiService.saveTodaysMealPlan(refinedMealPlan, _userId!);

        // Add confirmation message
        setState(() {
          _messages.add({
            'isUser': false,
            'message':
                'Great! I\'ve saved your meal plan. You can view it on your dashboard and meals page. Let me know if you have any questions about it!',
          });
          _isLoading = false;
        });
      } catch (e) {
        debugPrint('Error saving meal plan to backend: $e');

        // Show error message
        setState(() {
          _messages.add({
            'isUser': false,
            'message':
                'Sorry, I encountered an error while saving your meal plan to the database. Please try again.',
          });
          _isLoading = false;
        });
      }

      // Save chat history
      _saveChatHistory();

      // Scroll to bottom
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error accepting meal plan: $e');
      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'Sorry, I encountered an error while processing your meal plan. Please try again.',
        });
        _isLoading = false;
        _showMealPlanAcceptance = false;
      });

      _scrollToBottom();
    }
  }

  // Reject the current meal plan
  void _rejectMealPlan() {
    setState(() {
      _showMealPlanAcceptance = false;
      _messages.add({
        'isUser': false,
        'message':
            'No problem! Let me know what changes you\'d like, and I can generate a new meal plan for you.',
      });
    });

    // Save chat history
    _saveChatHistory();

    // Scroll to bottom
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _clearChat() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Clear Chat History'),
            content: const Text('Are you sure you want to clear all messages?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () async {
                  Navigator.pop(context);

                  // Keep only the welcome message
                  setState(() {
                    _messages = [
                      {
                        'isUser': false,
                        'message':
                            'Hello! I\'m your NutriGen assistant. I can help you with personalized nutrition advice based on your genetic profile. How can I help you today?',
                      },
                    ];

                    // Add the gene marker message if available
                    if (_geneMarker != null) {
                      _messages.add({
                        'isUser': false,
                        'message':
                            'I see that you have the $_geneMarker genetic marker in your profile. I\'ll use this to provide personalized nutrition recommendations.',
                      });
                    }
                  });

                  // Save the cleared chat history
                  await _saveChatHistory();
                },
                child: const Text('Clear', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI Nutrition Assistant',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.grey),
            onPressed: _clearChat,
          ),
        ],
      ),
      body: Column(
        children: [
          // Gene marker banner
          if (_geneMarker != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.red.shade50,
              width: double.infinity,
              child: Row(
                children: [
                  const Icon(Icons.science, color: Color(0xFFCC1C14), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Using genetic marker: $_geneMarker',
                      style: const TextStyle(
                        color: Color(0xFFCC1C14),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // API availability banner
          if (!_isApiAvailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.amber.shade100,
              width: double.infinity,
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.amber.shade900,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'AI service is currently unavailable',
                      style: TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: _checkApiAvailability,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),

          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(
                  message['message'],
                  message['isUser'],
                );
              },
            ),
          ),

          // Meal plan acceptance UI
          if (_showMealPlanAcceptance && !_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                border: Border(top: BorderSide(color: Colors.red.shade200)),
              ),
              child: Column(
                children: [
                  const Text(
                    'Would you like to add this meal plan to your dashboard?',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: _rejectMealPlan,
                        icon: const Icon(Icons.close),
                        label: const Text('Reject'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey,
                          foregroundColor: Colors.white,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: _acceptMealPlan,
                        icon: const Icon(Icons.check),
                        label: const Text('Accept'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFCC1C14),
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Color(0xFFCC1C14),
                    ),
                  ),
                  SizedBox(width: 8),
                  Text('Thinking...'),
                ],
              ),
            ),

          // Input area
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  offset: const Offset(0, -2),
                  blurRadius: 3,
                  color: Colors.black.withOpacity(0.1),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Ask about nutrition or meal plans...',
                      filled: true,
                      fillColor: Colors.grey[100],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFCC1C14),
                  child: IconButton(
                    onPressed: _sendMessage,
                    icon: const Icon(Icons.send, color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(String message, bool isUser) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isUser ? const Color(0xFFCC1C14) : Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        child: Text(
          message,
          style: TextStyle(color: isUser ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}
