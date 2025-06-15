import 'package:flutter/material.dart';
import 'package:nutrigen/services/model_service.dart';
import 'package:nutrigen/services/gemini_service.dart';
import 'package:nutrigen/services/profile_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class AIChatbotScreen extends StatefulWidget {
  const AIChatbotScreen({Key? key}) : super(key: key);

  @override
  State<AIChatbotScreen> createState() => _AIChatbotScreenState();
}

class _AIChatbotScreenState extends State<AIChatbotScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ModelService _modelService = ModelService();
  final GeminiService _geminiService = GeminiService();
  final ProfileService _profileService = ProfileService();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;
  bool _showMealPlanAcceptance = false;
  String? _pendingMealPlan;
  String? _userId;
  String? _geneMarker;
  Map<String, dynamic>? _userProfile;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initializeChat() async {
    await _loadUserProfile();
    await _loadChatHistory();
    await _checkApiAvailability();
  }

  Future<void> _loadUserProfile() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _userId = prefs.getString('user_id');
      debugPrint('User ID loaded: $_userId');

      if (_userId != null) {
        final response = await _profileService.getUserProfile();
        setState(() {
          _userProfile = response['data'];
          _geneMarker = _userProfile?['geneMarker'];
        });
        debugPrint('User profile loaded: $_userProfile');
      }
    } catch (e) {
      debugPrint('Error loading user profile: $e');
    }
  }

  Future<void> _loadChatHistory() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryString = prefs.getString('chat_history_$_userId');

      if (chatHistoryString != null) {
        final List<dynamic> chatHistoryJson = json.decode(chatHistoryString);
        setState(() {
          _messages = chatHistoryJson.cast<Map<String, dynamic>>();
        });
        debugPrint('Chat history loaded: ${_messages.length} messages');
      } else {
        debugPrint(
          'No chat history found for user $_userId, initialized with welcome message',
        );
        _initializeWelcomeMessage();
      }
    } catch (e) {
      debugPrint('Error loading chat history: $e');
      _initializeWelcomeMessage();
    }
  }

  void _initializeWelcomeMessage() {
    setState(() {
      _messages = [
        {
          'isUser': false,
          'message':
              'Hello! I\'m your NutriGen assistant. I can help you with personalized nutrition advice based on your genetic profile. How can I help you today?',
        },
      ];

      // Add gene marker info if available
      if (_geneMarker != null) {
        _messages.add({
          'isUser': false,
          'message':
              'I see that you have the $_geneMarker genetic marker in your profile. I can provide personalized nutrition recommendations based on this information.',
        });
      }
    });

    _saveChatHistory();
  }

  Future<void> _saveChatHistory() async {
    if (_userId == null) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryString = json.encode(_messages);
      await prefs.setString('chat_history_$_userId', chatHistoryString);
    } catch (e) {
      debugPrint('Error saving chat history: $e');
    }
  }

  Future<void> _checkApiAvailability() async {
    try {
      final isAvailable = await _modelService.checkApiAvailability();
      if (!isAvailable && mounted) {
        setState(() {
          _messages.add({
            'isUser': false,
            'message':
                'I\'m currently having trouble connecting to my nutrition database. Please try again in a moment, or contact support if the issue persists.',
          });
        });
        _saveChatHistory();
      }
    } catch (e) {
      debugPrint('Error checking API availability: $e');
    }
  }

  Future<void> _sendMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty || _isLoading) return;

    setState(() {
      _messages.add({'isUser': true, 'message': message});
      _isLoading = true;
      _showMealPlanAcceptance = false;
    });

    _messageController.clear();
    _scrollToBottom();

    try {
      // Prepare chat history for context (reverse and limit to recent messages)
      final chatHistory = _messages.reversed.take(10).toList();

      // Generate enhanced response with Gemini post-processing
      final response = await _modelService.generateResponse(
        input: message,
        geneMarker: _geneMarker,
        age: _userProfile?['age']?.toString(),
        gender: _userProfile?['gender'],
        healthGoals: _userProfile?['healthGoals']?.cast<String>(),
        dietPreferences: _userProfile?['dietPreferences']?.cast<String>(),
        allergies: _userProfile?['allergies']?.cast<String>(),
        chatHistory: chatHistory,
      );

      if (!mounted) return;

      setState(() {
        _messages.add({'isUser': false, 'message': response});
        _isLoading = false;
      });

      // Check if response contains a meal plan
      if (_containsMealPlan(response)) {
        setState(() {
          _showMealPlanAcceptance = true;
          _pendingMealPlan = response;
        });
      }

      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'I apologize, but I\'m having trouble processing your request right now. Could you please try rephrasing your question?',
        });
        _isLoading = false;
        _showMealPlanAcceptance = false;
      });

      _saveChatHistory();
      _scrollToBottom();
      debugPrint('Error generating response: $e');
    }
  }

  bool _containsMealPlan(String response) {
    final mealPlanIndicators = [
      'breakfast',
      'lunch',
      'dinner',
      'meal plan',
      'calories',
      'protein',
      'snack',
    ];

    final lowercaseResponse = response.toLowerCase();
    return mealPlanIndicators.any(
      (indicator) => lowercaseResponse.contains(indicator),
    );
  }

  Future<void> _acceptMealPlan() async {
    if (_pendingMealPlan == null) return;

    try {
      setState(() => _isLoading = true);

      // Process meal plan for dashboard
      final structuredMealPlan = await _geminiService
          .refineMealPlanForDashboard(_pendingMealPlan!);

      // Save to backend
      await _geminiService.saveTodaysMealPlan(structuredMealPlan, _userId!);

      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'Great! I\'ve saved your meal plan. You can view it on your dashboard and meals page. Let me know if you have any questions about it!',
        });
        _isLoading = false;
        _showMealPlanAcceptance = false;
      });

      _saveChatHistory();
      _scrollToBottom();
    } catch (e) {
      debugPrint('Error accepting meal plan: $e');
      setState(() {
        _messages.add({
          'isUser': false,
          'message':
              'Sorry, I encountered an error while saving your meal plan. Please try again.',
        });
        _isLoading = false;
        _showMealPlanAcceptance = false;
      });
      _scrollToBottom();
    }
  }

  void _rejectMealPlan() {
    setState(() {
      _showMealPlanAcceptance = false;
      _messages.add({
        'isUser': false,
        'message':
            'No problem! Let me know what changes you\'d like, and I can generate a new meal plan for you.',
      });
    });

    _saveChatHistory();
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

                  setState(() {
                    _messages = [
                      {
                        'isUser': false,
                        'message':
                            'Hello! I\'m your NutriGen assistant. I can help you with personalized nutrition advice based on your genetic profile. How can I help you today?',
                      },
                    ];

                    if (_geneMarker != null) {
                      _messages.add({
                        'isUser': false,
                        'message':
                            'I see that you have the $_geneMarker genetic marker in your profile. I can provide personalized nutrition recommendations based on this information.',
                      });
                    }

                    _showMealPlanAcceptance = false;
                  });

                  await _saveChatHistory();
                },
                child: const Text('Clear'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('AI Nutrition Assistant'),
        backgroundColor: const Color(0xFFCC1C14),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.clear_all),
            onPressed: _clearChat,
            tooltip: 'Clear Chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Chat messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return _buildMessageBubble(message);
              },
            ),
          ),

          // Meal plan acceptance section
          if (_showMealPlanAcceptance) _buildMealPlanAcceptance(),

          // Loading indicator
          if (_isLoading)
            Container(
              padding: const EdgeInsets.all(16),
              child: const Row(
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFCC1C14),
                    ),
                  ),
                  SizedBox(width: 16),
                  Text('Thinking...'),
                ],
              ),
            ),

          // Message input
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  blurRadius: 4,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    enabled: !_isLoading,
                    decoration: InputDecoration(
                      hintText: 'Ask about nutrition or meal plans...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: Colors.grey[300]!),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: const BorderSide(color: Color(0xFFCC1C14)),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: 3,
                    minLines: 1,
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoading ? null : _sendMessage,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey : const Color(0xFFCC1C14),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> message) {
    final isUser = message['isUser'] == true;
    final messageText = message['message'] as String;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            CircleAvatar(
              backgroundColor: const Color(0xFFCC1C14),
              radius: 16,
              child: const Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFCC1C14) : Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                messageText,
                style: TextStyle(
                  color: isUser ? Colors.white : Colors.black87,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: Colors.grey[300],
              radius: 16,
              child: Icon(Icons.person, color: Colors.grey[600], size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMealPlanAcceptance() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Would you like me to save this meal plan to your dashboard?',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _acceptMealPlan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Yes, Save It'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : _rejectMealPlan,
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('No, Thanks'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
