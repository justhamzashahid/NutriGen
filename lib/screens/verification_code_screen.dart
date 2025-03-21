import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nutrigen/services/auth_service.dart';
import 'package:nutrigen/screens/reset_password_screen.dart';

class VerificationCodeScreen extends StatefulWidget {
  final String userId;
  final String mode;
  final VoidCallback onVerificationComplete;

  const VerificationCodeScreen({
    Key? key,
    required this.userId,
    this.mode = 'signup',
    required this.onVerificationComplete,
  }) : super(key: key);

  @override
  State<VerificationCodeScreen> createState() => _VerificationCodeScreenState();
}

class _VerificationCodeScreenState extends State<VerificationCodeScreen> {
  final List<TextEditingController> _controllers = List.generate(
    5,
    (index) => TextEditingController(),
  );
  final List<FocusNode> _focusNodes = List.generate(5, (index) => FocusNode());
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    for (var node in _focusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _verifyCode() async {
    String enteredCode =
        _controllers.map((controller) => controller.text).join();

    if (enteredCode.length != 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter the complete verification code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (widget.mode == 'signup') {
        // For signup verification
        await _authService.verifyEmail(widget.userId, enteredCode);
        if (!mounted) return;
        widget.onVerificationComplete();
      } else if (widget.mode == 'reset_password') {
        // For password reset flow, use the new verification method
        await _authService.verifyResetPasswordCode(widget.userId, enteredCode);

        if (!mounted) return;

        // Only proceed to reset password screen if verification was successful
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder:
                (context) => ResetPasswordScreen(
                  userId: widget.userId,
                  verificationCode: enteredCode,
                ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _resendCode() async {
    try {
      setState(() => _isLoading = true);

      final response = await _authService.resendVerificationCode(widget.userId);

      if (!mounted) return;

      // For development: Print the new verification code
      debugPrint('New Verification Code: ${response['verificationCode']}');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Verification code resent successfully'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _handleKeypadInput(String input) {
    for (int i = 0; i < 5; i++) {
      if (_controllers[i].text.isEmpty) {
        _controllers[i].text = input;
        if (i < 4) {
          _focusNodes[i + 1].requestFocus();
        } else {
          _verifyCode();
        }
        break;
      }
    }
  }

  void _handleBackspace() {
    for (int i = 4; i >= 0; i--) {
      if (_controllers[i].text.isNotEmpty) {
        _controllers[i].clear();
        if (i > 0) {
          _focusNodes[i - 1].requestFocus();
        }
        break;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Enter code',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'We have sent a code to your email address. Kindly input that code down below',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 32),

                // Verification code input boxes
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(
                    5,
                    (index) => SizedBox(
                      width: 50,
                      height: 50,
                      child: TextFormField(
                        controller: _controllers[index],
                        focusNode: _focusNodes[index],
                        textAlign: TextAlign.center,
                        keyboardType: TextInputType.number,
                        maxLength: 1,
                        enabled: !_isLoading,
                        decoration: InputDecoration(
                          counterText: '',
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.grey[300]!),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: const BorderSide(
                              color: Color(0xFFCC1C14),
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onChanged: (value) {
                          if (value.isNotEmpty) {
                            if (index < 4) {
                              _focusNodes[index + 1].requestFocus();
                            } else {
                              _verifyCode();
                            }
                          } else if (value.isEmpty && index > 0) {
                            _focusNodes[index - 1].requestFocus();
                          }
                        },
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (_isLoading)
                  const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Color(0xFFCC1C14),
                      ),
                    ),
                  ),

                // Resend code option
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Didn\'t receive the code?',
                      style: TextStyle(color: Colors.black.withOpacity(0.7)),
                    ),
                    TextButton(
                      onPressed: _isLoading ? null : _resendCode,
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFCC1C14),
                      ),
                      child: const Text(
                        'Resend',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Spacer(),

          // Keypad
          Container(
            color: Colors.grey[200],
            width: double.infinity,
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKeypadButton('1'),
                    _buildKeypadButton('2', subtitle: 'ABC'),
                    _buildKeypadButton('3', subtitle: 'DEF'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('4', subtitle: 'GHI'),
                    _buildKeypadButton('5', subtitle: 'JKL'),
                    _buildKeypadButton('6', subtitle: 'MNO'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('7', subtitle: 'PQRS'),
                    _buildKeypadButton('8', subtitle: 'TUV'),
                    _buildKeypadButton('9', subtitle: 'WXYZ'),
                  ],
                ),
                Row(
                  children: [
                    _buildKeypadButton('+ * #'),
                    _buildKeypadButton('0'),
                    _buildKeypadButton('⌫', isBackspace: true),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeypadButton(
    String text, {
    String? subtitle,
    bool isBackspace = false,
  }) {
    return Expanded(
      child: SizedBox(
        height: 60,
        child: TextButton(
          onPressed:
              _isLoading
                  ? null
                  : () {
                    if (isBackspace) {
                      _handleBackspace();
                    } else if (text.length == 1) {
                      _handleKeypadInput(text);
                    }
                  },
          child:
              isBackspace
                  ? const Icon(Icons.backspace_outlined, color: Colors.black)
                  : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        text,
                        style: const TextStyle(
                          fontSize: 20,
                          color: Colors.black,
                        ),
                      ),
                      if (subtitle != null)
                        Text(
                          subtitle,
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.black.withOpacity(0.6),
                          ),
                        ),
                    ],
                  ),
        ),
      ),
    );
  }
}
