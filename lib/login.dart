import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'HomePage.dart';
import 'signup.dart';
import 'providers/auth_provider.dart';
import 'widgets/connection_error_widget.dart';
import 'utils/provider_wrapper.dart';
import 'PoliceStationDashboard.dart';
import 'FireStationDashboard.dart';
import 'VolunteerDashboard.dart';
import 'services/location_service.dart';

// Create a wrapper for LoginPage with the required provider
class LoginPageWrapper extends StatelessWidget {
  const LoginPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use our utility wrapper to ensure the provider is available
    return ProviderWrapper(child: const LoginPage());
  }
}

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  bool showPassword = false;
  bool rememberMe = false;

  // Admin mode tracking
  bool _isAdminMode = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  int _adminTapCount = 0;
  final String _adminUsername = "admin";
  final String _adminPassword = "admin123";

  // Keys for storing credentials in SharedPreferences
  static const String _rememberMeKey = 'remember_me';
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';

  // Animation controllers
  late AnimationController _mainController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _pulseAnimation;

  // Loading state
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    // Main animations
    _mainController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _mainController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _mainController,
        curve: const Interval(0.1, 0.6, curve: Curves.easeOutQuint),
      ),
    );

    // Pulse animation for emergency icon
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _mainController.forward();

    // Load saved credentials if they exist
    _loadSavedCredentials();
  }

  // Load saved credentials from SharedPreferences
  Future<void> _loadSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final savedRememberMe = prefs.getBool(_rememberMeKey) ?? false;
    
    if (savedRememberMe) {
      final savedUsername = prefs.getString(_usernameKey) ?? '';
      final savedPassword = prefs.getString(_passwordKey) ?? '';
      
      setState(() {
        rememberMe = savedRememberMe;
        _usernameController.text = savedUsername;
        _passwordController.text = savedPassword;
      });
    }
  }

  // Save credentials to SharedPreferences
  Future<void> _saveCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setBool(_rememberMeKey, true);
      await prefs.setString(_usernameKey, _usernameController.text);
      await prefs.setString(_passwordKey, _passwordController.text);
    } else {
      // Clear saved credentials if "Remember Me" is unchecked
      await prefs.setBool(_rememberMeKey, false);
      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
    }
  }

  @override
  void dispose() {
    _mainController.dispose();
    _pulseController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // Admin function to handle privileged operations
  void _runAsAdmin() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            backgroundColor: Colors.white,
            titleTextStyle: const TextStyle(color: Colors.black),
            contentTextStyle: const TextStyle(color: Colors.black87),
            title: const Row(
              children: [
                Icon(Icons.admin_panel_settings, color: Color(0xFFE53935)),
                SizedBox(width: 10),
                Text("Admin Control Center"),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Welcome, ResQ Administrator",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  const Text("Emergency Management System Controls:"),
                  const SizedBox(height: 12),
                  _buildAdminActionButton(
                    "Dispatch Management",
                    Icons.location_on,
                    const Color(0xFFE53935),
                    () => _handleAdminAction("Dispatch Management"),
                  ),
                  _buildAdminActionButton(
                    "Resource Allocation",
                    Icons.people_alt,
                    const Color(0xFFE53935),
                    () => _handleAdminAction("Resource Allocation"),
                  ),
                  _buildAdminActionButton(
                    "Emergency Analytics",
                    Icons.analytics,
                    const Color(0xFFE53935),
                    () => _handleAdminAction("Emergency Analytics"),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFE53935),
                ),
                child: const Text("CLOSE"),
              ),
            ],
          ),
    );
  }

  // Handle admin action selection
  void _handleAdminAction(String action) {
    Navigator.of(context).pop(); // Close admin panel dialog

    // Show action confirmation
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.admin_panel_settings, color: Colors.white),
            const SizedBox(width: 10),
            Text("Admin: $action"),
          ],
        ),
        backgroundColor: const Color(0xFFE53935),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // Admin action button widget
  Widget _buildAdminActionButton(
    String title,
    IconData icon,
    Color color,
    VoidCallback onPressed,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.5), width: 1),
        ),
        child: ElevatedButton.icon(
          icon: Icon(icon, size: 20, color: color),
          label: Text(title, style: TextStyle(fontSize: 14, color: color)),
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            foregroundColor: color,
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            alignment: Alignment.centerLeft,
          ),
        ),
      ),
    );
  }

  // Check if admin credentials are entered
  void _checkAdminAccess() {
    if (_usernameController.text == _adminUsername &&
        _passwordController.text == _adminPassword) {
      setState(() {
        _isAdminMode = true;
      });
      _runAsAdmin();
    }
  }

  // Admin trigger on logo tap
  void _incrementAdminTapCount() {
    setState(() {
      _adminTapCount++;
      if (_adminTapCount >= 5) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "Admin mode available. Enter admin credentials to access.",
            ),
            duration: Duration(seconds: 2),
          ),
        );
        _adminTapCount = 0; // Reset count
      }
    });
  }

  // Handle login submission
  Future<void> _handleLogin() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      // Save credentials based on "Remember Me" checkbox
      await _saveCredentials();

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Check for admin login
      if (_usernameController.text == _adminUsername &&
          _passwordController.text == _adminPassword) {
        setState(() {
          _isAdminMode = true;
          _isLoading = false;
        });
        _runAsAdmin();
        return;
      }

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Using the login method from AuthProvider
        final success = await authProvider.login(
          _usernameController.text,
          _passwordController.text,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.white),
                  SizedBox(width: 10),
                  Text("Login successful - Welcome to ResQ"),
                ],
              ),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );

          // Request location permission after successful login
          final locationService = LocationService();
          await locationService.requestLocationPermission(context);

          // Navigate based on user role
          final userRole = authProvider.user?.role;
          _navigateBasedOnRole(userRole);
        } else if (authProvider.status == AuthStatus.connectionError) {
          // Show connection error dialog
          _showConnectionErrorDialog(
            context,
            authProvider.errorMessage ?? "Connection error",
          );
        } else {
          setState(() {
            _errorMessage = authProvider.errorMessage;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  // New method to handle role-based navigation
  void _navigateBasedOnRole(String? role) {
    if (role == null) {
      // Default to citizen dashboard if role is not specified
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const HomePageWrapper()),
      );
      return;
    }

    // Navigate based on role - using role constants from the API docs
    switch (role) {
      case 'CITIZEN':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageWrapper()),
        );
        break;
      case 'FIRE_STATION':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const FireStationDashboard()),
        );
        break;
      case 'POLICE':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const PoliceDashboard()),
        );
        break;
      case 'RED_CRESCENT':
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const VolunteerDashboard()),
        );
        break;
      default:
        // Default to citizen dashboard for unknown roles
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const HomePageWrapper()),
        );
    }
  }

  void _showAuthenticationErrorDialog(
    BuildContext context,
    String errorMessage,
  ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(Icons.error_outline, color: Colors.red[700]),
                const SizedBox(width: 10),
                const Text('Authentication Failed'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(errorMessage),
                const SizedBox(height: 16),
                const Text(
                  'Possible solutions:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text('• Check that your username is correct'),
                const Text('• Make sure your password is correct'),
                const Text(
                  '• If you\'ve forgotten your password, use the forgot password option',
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('OK'),
              ),
            ],
          ),
    );
  }

  void _showConnectionErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ConnectionErrorWidget(
                errorMessage: errorMessage,
                onRetry: () {
                  Navigator.pop(context);
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  authProvider.retryConnection();
                },
              ),
            ),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // App color scheme - Red and White
    final primaryRed = const Color(0xFFE53935);
    final redGradientDark = const Color(0xFFC62828);
    final redGradientLight = const Color(0xFFEF5350);

    return Scaffold(
      body: Container(
        color: Colors.white,
        child: Stack(
          children: [
            // Background design elements
            Positioned(
              top: -MediaQuery.of(context).size.height * 0.05,
              right: -MediaQuery.of(context).size.width * 0.3,
              child: Transform.rotate(
                angle: -math.pi / 8,
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: MediaQuery.of(context).size.height * 0.4,
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(100),
                  ),
                ),
              ),
            ),

            Positioned(
              bottom: -MediaQuery.of(context).size.height * 0.1,
              left: -MediaQuery.of(context).size.width * 0.2,
              child: Container(
                width: MediaQuery.of(context).size.width * 0.7,
                height: MediaQuery.of(context).size.height * 0.3,
                decoration: BoxDecoration(
                  color: primaryRed.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(100),
                ),
              ),
            ),

            // Main content
            SafeArea(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Center(
                      child: SingleChildScrollView(
                        child: Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              const SizedBox(height: 30),

                              // Logo area - tappable for admin mode
                              GestureDetector(
                                onTap: _incrementAdminTapCount,
                                child: Column(
                                  children: [
                                    ScaleTransition(
                                      scale: _pulseAnimation,
                                      child: Container(
                                        padding: const EdgeInsets.all(20),
                                        decoration: BoxDecoration(
                                          color: primaryRed,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color: primaryRed.withOpacity(
                                                0.5,
                                              ),
                                              blurRadius: 20,
                                              spreadRadius: 5,
                                            ),
                                          ],
                                        ),
                                        child: const Icon(
                                          Icons.local_fire_department_rounded,
                                          size: 48,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      "ResQ",
                                      style: TextStyle(
                                        fontSize: 36,
                                        fontWeight: FontWeight.bold,
                                        color: primaryRed,
                                        letterSpacing: 1.2,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Welcome text
                              Text(
                                "Emergency Response System",
                                style: TextStyle(
                                  fontSize: 18,
                                  color: primaryRed.withOpacity(0.8),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                "Login with your username",
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 40),

                              // Error message
                              if (_errorMessage != null)
                                Container(
                                  margin: const EdgeInsets.only(bottom: 20),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.red.shade50,
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.red.shade200,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.error_outline,
                                        color: Colors.red.shade700,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _errorMessage!,
                                          style: TextStyle(
                                            color: Colors.red.shade700,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                              // Username field
                              buildTextField(
                                "Username",
                                Icons.person_outline,
                                primaryRed,
                                controller: _usernameController,
                              ),
                              const SizedBox(height: 16),

                              // Password field
                              buildPasswordField(
                                "Password",
                                primaryRed,
                                controller: _passwordController,
                              ),

                              const SizedBox(height: 8),

                              // Remember me & Forgot password
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: Checkbox(
                                          value: rememberMe,
                                          activeColor: primaryRed,
                                          checkColor: Colors.white,
                                          fillColor:
                                              WidgetStateProperty.resolveWith<
                                                Color
                                              >((Set<WidgetState> states) {
                                                if (states.contains(
                                                  WidgetState.selected,
                                                )) {
                                                  return primaryRed;
                                                }
                                                return Colors.grey[300]!;
                                              }),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              4,
                                            ),
                                          ),
                                          onChanged: (val) {
                                            setState(() => rememberMe = val!);
                                          },
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      GestureDetector(
                                        onTap: () {
                                          setState(() => rememberMe = !rememberMe);
                                        },
                                        child: Text(
                                          "Remember me",
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryRed,
                                      padding: EdgeInsets.zero,
                                      minimumSize: const Size(0, 36),
                                      tapTargetSize:
                                          MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      "Forgot Password?",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 40),

                              // Login button with animation and loading state
                              Container(
                                width: double.infinity,
                                height: 56,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(14),
                                  gradient: LinearGradient(
                                    colors: [redGradientDark, redGradientLight],
                                    begin: Alignment.centerLeft,
                                    end: Alignment.centerRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryRed.withOpacity(0.4),
                                      blurRadius: 12,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    disabledBackgroundColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14),
                                    ),
                                  ),
                                  child:
                                      _isLoading
                                          ? const SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                          : const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                "SIGN IN",
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w600,
                                                  letterSpacing: 1.2,
                                                ),
                                              ),
                                              SizedBox(width: 8),
                                              Icon(
                                                Icons.arrow_forward_rounded,
                                                size: 20,
                                              ),
                                            ],
                                          ),
                                ),
                              ),

                              const SizedBox(height: 40),

                              // Feature highlights
                              Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: primaryRed.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: primaryRed.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.verified_user,
                                          color: primaryRed,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          "EMERGENCY FEATURES",
                                          style: TextStyle(
                                            color: primaryRed,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    buildFeatureItem(
                                      "Live Emergency Response",
                                      Icons.emergency_rounded,
                                      primaryRed,
                                    ),
                                    buildFeatureItem(
                                      "24/7 Medical Assistance",
                                      Icons.medical_services_rounded,
                                      primaryRed,
                                    ),
                                    buildFeatureItem(
                                      "Location Tracking & Sharing",
                                      Icons.location_on_rounded,
                                      primaryRed,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 30),

                              // Sign up option
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Don't have an account?",
                                    style: TextStyle(color: Colors.grey[700]),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      // Navigate to signup page with proper provider wrapper
                                      Navigator.pushReplacement(
                                        context,
                                        MaterialPageRoute(
                                          builder:
                                              (context) =>
                                                  const RoleBasedSignUpPageWrapper(),
                                        ),
                                      );
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: primaryRed,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 8,
                                      ),
                                    ),
                                    child: const Text(
                                      "Register",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 16),

                              // Copyright text
                              Text(
                                "© ${DateTime.now().year} ResQ Emergency Services",
                                style: TextStyle(
                                  color: Colors.grey[500],
                                  fontSize: 12,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget buildTextField(
    String label,
    IconData icon,
    Color accentColor, {
    TextEditingController? controller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: 22),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          floatingLabelStyle: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        keyboardType: TextInputType.text, // Always text for username
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Please enter $label";
          }
          return null;
        },
      ),
    );
  }

  Widget buildPasswordField(
    String label,
    Color accentColor, {
    TextEditingController? controller,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        style: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          labelText: label,
          floatingLabelBehavior: FloatingLabelBehavior.auto,
          prefixIcon: Container(
            margin: const EdgeInsets.only(left: 12, right: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.lock_outline_rounded,
              color: accentColor,
              size: 22,
            ),
          ),
          suffixIcon: Container(
            margin: const EdgeInsets.only(right: 8),
            child: InkWell(
              borderRadius: BorderRadius.circular(30),
              onTap: () => setState(() => showPassword = !showPassword),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color:
                      showPassword
                          ? accentColor.withOpacity(0.1)
                          : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  showPassword
                      ? Icons.visibility_rounded
                      : Icons.visibility_off_rounded,
                  color: accentColor,
                  size: 20,
                ),
              ),
            ),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: accentColor.withOpacity(0.3),
              width: 1,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: accentColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 12,
          ),
          labelStyle: TextStyle(color: Colors.grey[600], fontSize: 15),
          floatingLabelStyle: TextStyle(
            color: accentColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        validator:
            (value) =>
                value == null || value.isEmpty ? "Please enter $label" : null,
      ),
    );
  }

  Widget buildFeatureItem(String text, IconData icon, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(text, style: TextStyle(color: Colors.grey[800], fontSize: 13)),
        ],
      ),
    );
  }
}
