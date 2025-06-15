// import 'package:flutter/material.dart';
// import 'package:nutrigen/services/admin_service.dart';
// import 'package:nutrigen/screens/admin/admin_dashboard_screen.dart';

// class AdminLoginScreen extends StatefulWidget {
//   const AdminLoginScreen({Key? key}) : super(key: key);

//   @override
//   State<AdminLoginScreen> createState() => _AdminLoginScreenState();
// }

// class _AdminLoginScreenState extends State<AdminLoginScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _isLoading = false;
//   final _adminService = AdminService();

//   @override
//   void dispose() {
//     _emailController.dispose();
//     _passwordController.dispose();
//     super.dispose();
//   }

//   void _adminLogin() async {
//     if (_formKey.currentState!.validate()) {
//       try {
//         setState(() => _isLoading = true);

//         await _adminService.adminLogin(
//           _emailController.text,
//           _passwordController.text,
//         );

//         if (!mounted) return;

//         // Navigate to admin dashboard
//         Navigator.pushReplacement(
//           context,
//           MaterialPageRoute(builder: (context) => const AdminDashboardScreen()),
//         );
//       } catch (e) {
//         if (!mounted) return;

//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
//         );
//       } finally {
//         if (mounted) {
//           setState(() => _isLoading = false);
//         }
//       }
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       body: SafeArea(
//         child: Center(
//           child: SingleChildScrollView(
//             padding: const EdgeInsets.all(24.0),
//             child: Container(
//               constraints: const BoxConstraints(maxWidth: 400),
//               child: Form(
//                 key: _formKey,
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.stretch,
//                   children: [
//                     // Admin logo/title
//                     const Icon(
//                       Icons.admin_panel_settings,
//                       size: 80,
//                       color: Color(0xFFCC1C14),
//                     ),
//                     const SizedBox(height: 24),

//                     Text(
//                       'Admin Panel',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(
//                         fontSize: 32,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.grey[800],
//                       ),
//                     ),

//                     const SizedBox(height: 8),

//                     Text(
//                       'NutriGen Administration',
//                       textAlign: TextAlign.center,
//                       style: TextStyle(fontSize: 16, color: Colors.grey[600]),
//                     ),

//                     const SizedBox(height: 48),

//                     // Email field
//                     TextFormField(
//                       controller: _emailController,
//                       keyboardType: TextInputType.emailAddress,
//                       decoration: InputDecoration(
//                         labelText: 'Admin Email',
//                         hintText: 'admin@nutrigen.com',
//                         prefixIcon: const Icon(Icons.email_outlined),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(
//                             color: Color(0xFFCC1C14),
//                           ),
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter admin email';
//                         }
//                         if (!value.contains('@')) {
//                           return 'Please enter a valid email';
//                         }
//                         return null;
//                       },
//                     ),

//                     const SizedBox(height: 20),

//                     // Password field
//                     TextFormField(
//                       controller: _passwordController,
//                       obscureText: _obscurePassword,
//                       decoration: InputDecoration(
//                         labelText: 'Admin Password',
//                         prefixIcon: const Icon(Icons.lock_outline),
//                         suffixIcon: IconButton(
//                           icon: Icon(
//                             _obscurePassword
//                                 ? Icons.visibility_off
//                                 : Icons.visibility,
//                           ),
//                           onPressed: () {
//                             setState(() {
//                               _obscurePassword = !_obscurePassword;
//                             });
//                           },
//                         ),
//                         border: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         enabledBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: BorderSide(color: Colors.grey[300]!),
//                         ),
//                         focusedBorder: OutlineInputBorder(
//                           borderRadius: BorderRadius.circular(8),
//                           borderSide: const BorderSide(
//                             color: Color(0xFFCC1C14),
//                           ),
//                         ),
//                       ),
//                       validator: (value) {
//                         if (value == null || value.isEmpty) {
//                           return 'Please enter admin password';
//                         }
//                         return null;
//                       },
//                     ),

//                     const SizedBox(height: 32),

//                     // Login button
//                     ElevatedButton(
//                       onPressed: _isLoading ? null : _adminLogin,
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: const Color(0xFFCC1C14),
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 16),
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         elevation: 2,
//                       ),
//                       child:
//                           _isLoading
//                               ? const SizedBox(
//                                 height: 20,
//                                 width: 20,
//                                 child: CircularProgressIndicator(
//                                   strokeWidth: 2,
//                                   valueColor: AlwaysStoppedAnimation<Color>(
//                                     Colors.white,
//                                   ),
//                                 ),
//                               )
//                               : const Text(
//                                 'Login to Admin Panel',
//                                 style: TextStyle(
//                                   fontSize: 16,
//                                   fontWeight: FontWeight.bold,
//                                 ),
//                               ),
//                     ),

//                     const SizedBox(height: 32),

//                     // Security notice
//                     Container(
//                       padding: const EdgeInsets.all(16),
//                       decoration: BoxDecoration(
//                         color: Colors.amber[50],
//                         border: Border.all(color: Colors.amber[200]!),
//                         borderRadius: BorderRadius.circular(8),
//                       ),
//                       child: Row(
//                         children: [
//                           Icon(
//                             Icons.security,
//                             color: Colors.amber[700],
//                             size: 20,
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Text(
//                               'This is a secure admin area. Unauthorized access is prohibited.',
//                               style: TextStyle(
//                                 color: Colors.amber[800],
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ),
//                         ],
//                       ),
//                     ),

//                     const SizedBox(height: 20),

//                     // Back to app button
//                     TextButton(
//                       onPressed: () {
//                         Navigator.pop(context);
//                       },
//                       style: TextButton.styleFrom(
//                         foregroundColor: Colors.grey[600],
//                       ),
//                       child: const Text('← Back to App'),
//                     ),
//                   ],
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
