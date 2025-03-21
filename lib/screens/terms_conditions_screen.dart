import 'package:flutter/material.dart';

class TermsConditionsScreen extends StatelessWidget {
  const TermsConditionsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Terms & Conditions',
          style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Terms and Conditions for NutriGen',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Last Updated: March 13, 2025',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              const Text(
                'Please read these terms and conditions carefully before using the NutriGen application.',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 24),

              _buildSection(
                '1. Acceptance of Terms',
                'By accessing or using NutriGen, you agree to be bound by these Terms and Conditions and our Privacy Policy. If you disagree with any part of the terms, you may not access the service.',
              ),

              _buildSection(
                '2. Description of Service',
                'NutriGen is a mobile application that provides personalized nutrition recommendations based on genetic data analysis. Our service includes meal planning, health tracking, and nutritional guidance.',
              ),

              _buildSection(
                '3. Use of Genetic Data',
                'When you upload your genetic data to NutriGen:\n\n'
                    '• We process this data to provide personalized nutrition recommendations\n'
                    '• Your genetic data is securely stored using AES-256 encryption\n'
                    '• We do not share your raw genetic data with third parties without your explicit consent\n'
                    '• We analyze specific genetic markers related to nutrition and metabolism only',
              ),

              _buildSection(
                '4. User Account and Security',
                'You are responsible for safeguarding your account credentials and for all activities that occur under your account. You must immediately notify NutriGen of any unauthorized use of your account.',
              ),

              _buildSection(
                '5. User Content',
                'Any information you provide to NutriGen, including genetic data, health information, and food logs, is considered User Content. You retain ownership of your User Content, but grant NutriGen a license to use, process, and analyze this data to provide and improve our services.',
              ),

              _buildSection(
                '6. Medical Disclaimer',
                'NutriGen is not a medical device and the information provided is not intended to diagnose, treat, cure, or prevent any disease. The nutrition recommendations are based on genetic markers and scientific research but should not replace professional medical advice. Always consult with a healthcare provider before making significant changes to your diet.',
              ),

              _buildSection(
                '7. Privacy',
                'Our Privacy Policy, available in the app, explains how we collect, use, and protect your personal information, including genetic data. By using NutriGen, you consent to the data practices described in our Privacy Policy.',
              ),

              _buildSection(
                '8. Subscription and Payments',
                'Some features of NutriGen may require a paid subscription. Payment terms will be clearly indicated before purchase. Subscriptions automatically renew unless canceled at least 24 hours before the end of the current period. Cancellation policy and refund requests are handled according to the platform\'s (App Store/Google Play) terms.',
              ),

              _buildSection(
                '9. Intellectual Property',
                'NutriGen, including its logo, content, features, and functionality, is protected by copyright, trademark, and other intellectual property laws. You may not reproduce, distribute, modify, create derivative works of, publicly display, or use any content from NutriGen without written permission.',
              ),

              _buildSection(
                '10. Limitation of Liability',
                'To the maximum extent permitted by law, NutriGen and its affiliates, officers, employees, agents, partners, and licensors shall not be liable for any indirect, incidental, special, consequential, or punitive damages, including without limitation, loss of profits, data, use, goodwill, or other intangible losses.',
              ),

              _buildSection(
                '11. Changes to Terms',
                'We reserve the right to modify these Terms at any time. We will provide notification of significant changes through the app or by email. Your continued use of NutriGen after such modifications constitutes your acceptance of the revised Terms.',
              ),

              _buildSection(
                '12. Termination',
                'We may terminate or suspend your account and access to NutriGen immediately, without prior notice or liability, for any reason, including if you breach the Terms. Upon termination, your right to use NutriGen will cease immediately.',
              ),

              _buildSection(
                '13. Governing Law',
                'These Terms shall be governed by the laws of the jurisdiction in which NutriGen operates, without regard to its conflict of law provisions.',
              ),

              _buildSection(
                '14. Contact Us',
                'If you have any questions about these Terms, please contact us at legal@nutrigen.com',
              ),

              const SizedBox(height: 32),

              Center(
                child: Text(
                  '© 2025 NutriGen. All rights reserved.',
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _buildSection(String title, String content) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Color(0xFFCC1C14),
        ),
      ),
      const SizedBox(height: 8),
      Text(content, style: const TextStyle(fontSize: 15, height: 1.5)),
      const SizedBox(height: 24),
    ],
  );
}
