import 'package:flutter/material.dart';
import 'package:nutrigen/services/config_service.dart';
import 'package:nutrigen/services/model_service.dart';

class ApiSettingsScreen extends StatefulWidget {
  const ApiSettingsScreen({Key? key}) : super(key: key);

  @override
  State<ApiSettingsScreen> createState() => _ApiSettingsScreenState();
}

class _ApiSettingsScreenState extends State<ApiSettingsScreen> {
  final TextEditingController _apiUrlController = TextEditingController();
  final ConfigService _configService = ConfigService();
  final ModelService _modelService = ModelService();
  bool _isLoading = false;
  bool _isApiAvailable = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadApiUrl();
  }

  @override
  void dispose() {
    _apiUrlController.dispose();
    super.dispose();
  }

  Future<void> _loadApiUrl() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiUrl = await _configService.getApiUrl();
      setState(() {
        _apiUrlController.text = apiUrl;
        _isLoading = false;
      });

      // Check if API is available
      _checkApiAvailability();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error loading API URL: $e';
      });
    }
  }

  Future<void> _saveApiUrl() async {
    if (_apiUrlController.text.isEmpty) {
      setState(() {
        _statusMessage = 'API URL cannot be empty';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Saving API URL...';
    });

    try {
      await _configService.setApiUrl(_apiUrlController.text);

      // Check if the new API is available
      await _checkApiAvailability();

      setState(() {
        _isLoading = false;
        _statusMessage = 'API URL saved successfully';
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error saving API URL: $e';
      });
    }
  }

  Future<void> _resetApiUrl() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Resetting to default API URL...';
    });

    try {
      await _configService.resetApiUrl();
      final defaultUrl = await _configService.getApiUrl();

      setState(() {
        _apiUrlController.text = defaultUrl;
        _isLoading = false;
        _statusMessage = 'Reset to default API URL';
      });

      // Check if the default API is available
      await _checkApiAvailability();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _statusMessage = 'Error resetting API URL: $e';
      });
    }
  }

  Future<void> _checkApiAvailability() async {
    setState(() {
      _statusMessage = 'Checking API availability...';
      _isLoading = true;
    });

    try {
      final isAvailable = await _modelService.checkApiAvailability();

      setState(() {
        _isApiAvailable = isAvailable;
        _isLoading = false;
        _statusMessage =
            isAvailable
                ? 'API is available'
                : 'API is not available. Make sure the URL is correct and the server is running.';
      });
    } catch (e) {
      setState(() {
        _isApiAvailable = false;
        _isLoading = false;
        _statusMessage = 'Error checking API availability: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'AI API Settings',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body:
          _isLoading && _apiUrlController.text.isEmpty
              ? const Center(
                child: CircularProgressIndicator(color: Color(0xFFCC1C14)),
              )
              : SingleChildScrollView(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // API URL Field
                    const Text(
                      'AI API URL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Enter the URL for the AI API (ngrok URL for Kaggle notebook)',
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _apiUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://example.ngrok-free.app',
                        filled: true,
                        fillColor: Colors.grey[100],
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Status indicator
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            _isApiAvailable
                                ? Colors.green.shade50
                                : Colors.red.shade50,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _isApiAvailable ? Icons.check_circle : Icons.error,
                            color: _isApiAvailable ? Colors.green : Colors.red,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _statusMessage,
                              style: TextStyle(
                                color:
                                    _isApiAvailable
                                        ? Colors.green.shade800
                                        : Colors.red.shade800,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed:
                                _isLoading ? null : _checkApiAvailability,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child:
                                _isLoading &&
                                        _statusMessage ==
                                            'Checking API availability...'
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Check'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _resetApiUrl,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child:
                                _isLoading &&
                                        _statusMessage ==
                                            'Resetting to default API URL...'
                                    ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        valueColor:
                                            AlwaysStoppedAnimation<Color>(
                                              Colors.white,
                                            ),
                                        strokeWidth: 2,
                                      ),
                                    )
                                    : const Text('Reset'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveApiUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFCC1C14),
                        foregroundColor: Colors.white,
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child:
                          _isLoading && _statusMessage == 'Saving API URL...'
                              ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white,
                                  ),
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                'Save',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                    ),
                    const SizedBox(height: 24),

                    // Instructions
                    const Text(
                      'How to set up the API:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '1. Run the Kaggle notebook to start the API server',
                          ),
                          SizedBox(height: 8),
                          Text(
                            '2. Copy the ngrok URL from the notebook output (e.g., https://example.ngrok-free.app)',
                          ),
                          SizedBox(height: 8),
                          Text(
                            '3. Paste the URL in the field above and click "Save"',
                          ),
                          SizedBox(height: 8),
                          Text(
                            '4. Click "Check" to verify that the API is available',
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
    );
  }
}
