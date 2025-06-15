import 'package:flutter/material.dart';
import 'package:nutrigen/services/admin_service.dart';
import 'package:nutrigen/screens/admin/admin_dashboard_screen.dart';

class AdminRouteIntegration {
  static const String loginRoute = '/login';
  static const String adminDashboardRoute = '/admin/dashboard';

  // Admin routes map (excluding login since we use regular login)
  static Map<String, WidgetBuilder> get adminRoutes => {
    adminDashboardRoute: (context) => const AdminDashboardScreen(),
  };

  // Check if current route is admin route
  static bool isAdminRoute(String route) {
    return route.startsWith('/admin');
  }

  // Navigate to regular login (admin will be detected automatically)
  static void navigateToLogin(BuildContext context) {
    Navigator.pushNamed(context, loginRoute);
  }

  // Check admin authentication and navigate accordingly
  static Future<void> checkAdminAuthAndNavigate(BuildContext context) async {
    final adminService = AdminService();
    final isAdmin = await adminService.isAdmin();

    if (isAdmin) {
      Navigator.pushNamedAndRemoveUntil(
        context,
        adminDashboardRoute,
        (route) => false,
      );
    } else {
      Navigator.pushNamed(context, loginRoute);
    }
  }
}

// Admin Access Widget - Can be added to any screen
class AdminAccessWidget extends StatefulWidget {
  final bool showInDrawer;
  final bool showAsFloatingButton;
  final VoidCallback? onAdminAccessed;

  const AdminAccessWidget({
    Key? key,
    this.showInDrawer = false,
    this.showAsFloatingButton = false,
    this.onAdminAccessed,
  }) : super(key: key);

  @override
  State<AdminAccessWidget> createState() => _AdminAccessWidgetState();
}

class _AdminAccessWidgetState extends State<AdminAccessWidget> {
  bool _showAdminOption = false;
  int _tapCount = 0;
  DateTime? _lastTapTime;

  @override
  Widget build(BuildContext context) {
    if (widget.showInDrawer) {
      return _buildDrawerItem();
    } else if (widget.showAsFloatingButton) {
      return _buildFloatingButton();
    } else {
      return _buildHiddenTrigger();
    }
  }

  Widget _buildDrawerItem() {
    return ListTile(
      leading: const Icon(Icons.admin_panel_settings, color: Color(0xFFCC1C14)),
      title: const Text('Admin Panel'),
      subtitle: const Text('System administration'),
      onTap: () {
        Navigator.pop(context); // Close drawer
        AdminRouteIntegration.checkAdminAuthAndNavigate(context);
        if (widget.onAdminAccessed != null) {
          widget.onAdminAccessed!();
        }
      },
    );
  }

  Widget _buildFloatingButton() {
    return FloatingActionButton(
      onPressed: () {
        AdminRouteIntegration.checkAdminAuthAndNavigate(context);
        if (widget.onAdminAccessed != null) {
          widget.onAdminAccessed!();
        }
      },
      backgroundColor: const Color(0xFFCC1C14),
      child: const Icon(Icons.admin_panel_settings, color: Colors.white),
    );
  }

  Widget _buildHiddenTrigger() {
    return GestureDetector(
      onTap: _handleSecretTap,
      child: Container(
        width: 50,
        height: 50,
        color: Colors.transparent,
        child:
            _showAdminOption
                ? IconButton(
                  icon: const Icon(
                    Icons.admin_panel_settings,
                    color: Color(0xFFCC1C14),
                  ),
                  onPressed: () {
                    AdminRouteIntegration.checkAdminAuthAndNavigate(context);
                    if (widget.onAdminAccessed != null) {
                      widget.onAdminAccessed!();
                    }
                  },
                )
                : const SizedBox(),
      ),
    );
  }

  void _handleSecretTap() {
    final now = DateTime.now();

    // Reset if more than 5 seconds between taps
    if (_lastTapTime != null && now.difference(_lastTapTime!).inSeconds > 5) {
      _tapCount = 0;
    }

    _lastTapTime = now;
    _tapCount++;

    // Show admin option after 7 taps
    if (_tapCount >= 7) {
      setState(() {
        _showAdminOption = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Admin access unlocked'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFFCC1C14),
        ),
      );

      // Hide again after 10 seconds
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted) {
          setState(() {
            _showAdminOption = false;
            _tapCount = 0;
          });
        }
      });
    }
  }
}

// Admin Guard - Protects admin routes
class AdminGuard extends StatefulWidget {
  final Widget child;
  final String? redirectRoute;

  const AdminGuard({Key? key, required this.child, this.redirectRoute})
    : super(key: key);

  @override
  State<AdminGuard> createState() => _AdminGuardState();
}

class _AdminGuardState extends State<AdminGuard> {
  bool _isLoading = true;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    try {
      final adminService = AdminService();
      final isAdmin = await adminService.isAdmin();

      setState(() {
        _isAuthorized = isAdmin;
        _isLoading = false;
      });

      if (!isAdmin && widget.redirectRoute != null) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.pushReplacementNamed(context, widget.redirectRoute!);
        });
      }
    } catch (e) {
      setState(() {
        _isAuthorized = false;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (!_isAuthorized) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Access Denied'),
          backgroundColor: Colors.red,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock, size: 64, color: Colors.red),
              SizedBox(height: 16),
              Text(
                'Admin Access Required',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text('You need admin privileges to access this area.'),
            ],
          ),
        ),
      );
    }

    return widget.child;
  }
}

// Settings Screen Extension for Admin Access
class AdminSettingsExtension {
  static Widget buildAdminAccessTile(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: ListTile(
        leading: const Icon(Icons.admin_panel_settings, color: Colors.red),
        title: const Text(
          'Admin Panel',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: const Text('System administration access'),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () {
          AdminRouteIntegration.checkAdminAuthAndNavigate(context);
        },
      ),
    );
  }

  static Widget buildDeveloperSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Developer Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
        ),
        buildAdminAccessTile(context),
        const SizedBox(height: 16),
      ],
    );
  }
}

// Utility functions for admin integration
class AdminUtils {
  // Check if current user is admin
  static Future<bool> isCurrentUserAdmin() async {
    final adminService = AdminService();
    return await adminService.isAdmin();
  }

  // Get admin token if available
  static Future<String?> getAdminToken() async {
    final adminService = AdminService();
    return await adminService.getAdminToken();
  }

  // Logout admin user
  static Future<void> logoutAdmin() async {
    final adminService = AdminService();
    await adminService.logout();
  }

  // Show admin login prompt
  static void showAdminLoginPrompt(BuildContext context) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Color(0xFFCC1C14)),
                SizedBox(width: 8),
                Text('Admin Access'),
              ],
            ),
            content: const Text(
              'This area requires administrator privileges. Would you like to login as admin?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  AdminRouteIntegration.navigateToLogin(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFCC1C14),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Login as Admin'),
              ),
            ],
          ),
    );
  }

  // Debug function to create admin access in development
  static Widget buildDebugAdminAccess(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.yellow[100],
      child: Row(
        children: [
          const Icon(Icons.warning, color: Colors.orange),
          const SizedBox(width: 8),
          const Text('DEBUG: '),
          Expanded(
            child: ElevatedButton(
              onPressed: () => AdminRouteIntegration.navigateToLogin(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFCC1C14),
              ),
              child: const Text(
                'Admin Login',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
