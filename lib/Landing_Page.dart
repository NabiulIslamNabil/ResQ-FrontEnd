import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import 'dart:async';
import 'signup.dart';
import 'login.dart';
import 'AboutUs.dart'; // Import the AboutUs page

void main() {
  runApp(const ResqEmergencyApp());
}

class ResqEmergencyApp extends StatelessWidget {
  const ResqEmergencyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'RESQ Emergency',
      theme: ThemeData(
        primarySwatch: Colors.red,
        fontFamily: 'Roboto',
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const LandingPage(),
    );
  }
}

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    // Fix for phone top info
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    _controller = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );

    _controller.repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: Brightness.dark,
        ),
      ),
      body: Container(
        width: screenSize.width,
        height: screenSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.red.shade50,
              Colors.grey.shade100,
              Colors.red.shade50.withOpacity(0.6),
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Enhanced background elements
            Positioned.fill(
              child: EnhancedBackgroundElements(controller: _controller),
            ),

            // Background obstacles with improved aesthetics
            Positioned.fill(child: EnhancedBackgroundObstacles()),

            // Logo at top center (moved down significantly)
            Positioned(
              top:
                  screenSize.height *
                  0.18, // Moved further down (about 18% from top)
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EnhancedLogo(controller: _controller),
                  const SizedBox(height: 16),
                  const Text(
                    'ResQ',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                      letterSpacing: 1.8,
                    ),
                  ),
                ],
              ),
            ),

            // Welcome message in center (also moved down)
            Positioned(
              top: screenSize.height * 0.40, // Adjusted to be lower
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'Welcome to ResQ',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Emergency Assistance Platform',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w500,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.8),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 10,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: const Text(
                        'Professional emergency response when needed most',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w400,
                          color: Colors.black45,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Action Button with smooth animation (no blinking)
            Positioned(
              bottom: 120, // Changed from 80 to 120 to move it higher up
              left: 0,
              right: 0,
              child: Center(
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTapDown: (_) => setState(() => _isPressed = true),
                    onTapUp:
                        (_) => setState(() {
                          _isPressed = false;
                          // Add visual feedback for click
                          Future.delayed(const Duration(milliseconds: 50), () {
                            if (mounted) setState(() {});
                          });
                        }),
                    onTapCancel: () => setState(() => _isPressed = false),
                    onTap: () {
                      // Show options dialog instead of direct navigation
                      HapticFeedback.mediumImpact(); // Add haptic feedback
                      _showAuthOptions(context);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOutCubic,
                      width: 220,
                      height: 56,
                      decoration: BoxDecoration(
                        color: _isHovered ? Colors.white : Colors.red,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(
                              _isPressed ? 0.4 : (_isHovered ? 0.3 : 0.2),
                            ),
                            blurRadius: _isPressed ? 6 : (_isHovered ? 12 : 8),
                            spreadRadius: _isPressed ? 0 : (_isHovered ? 2 : 0),
                            offset:
                                _isPressed
                                    ? const Offset(0, 2)
                                    : const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(
                          color: _isHovered ? Colors.red : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.translationValues(
                                _isPressed ? -2 : 0,
                                0,
                                0,
                              ),
                              child: Icon(
                                Icons
                                    .login_rounded, // Changed icon to login_rounded
                                color: _isHovered ? Colors.red : Colors.white,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 10),
                            AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: _isHovered ? Colors.red : Colors.white,
                                letterSpacing: 0.5,
                              ),
                              child: const Text('Get Started'), // Updated text
                            ),
                            const SizedBox(width: 8),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              transform: Matrix4.translationValues(
                                _isPressed ? 0 : (_isHovered ? 3 : 0),
                                0,
                                0,
                              ),
                              child: Icon(
                                Icons.arrow_forward,
                                color: _isHovered ? Colors.red : Colors.white,
                                size: 20,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Enhanced footer with subtle gradient
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.red.shade50.withOpacity(0.3),
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // About Us button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const AboutUsPage()),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 16,
                              color: Colors.red,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'About Us',
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    // Copyright text
                    Text(
                      '© ${DateTime.now().year} ResQ Emergency Services',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black38,
                        fontWeight: FontWeight.w400,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Update the navigation in _buildAuthOptionButton method
  Widget _buildAuthOptionButton({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  // In the _showAuthOptions method, update the navigation to signup page
  void _showAuthOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(24),
                topRight: Radius.circular(24),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 50,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Join ResQ Emergency Services',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose how you want to continue',
                  style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 32),

                // Sign Up Button
                _buildAuthOptionButton(
                  context: context,
                  icon: Icons.person_add,
                  title: 'Create a New Account',
                  subtitle: 'Sign up to access emergency services',
                  color: Colors.red,
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (context) => const RoleBasedSignUpPageWrapper(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                // Login Button
                _buildAuthOptionButton(
                  context: context,
                  icon: Icons.login_rounded,
                  title: 'Login to Your Account',
                  subtitle: 'Access your existing ResQ account',
                  color: Colors.blue.shade700,
                  onTap: () {
                    Navigator.pop(context); // Close the bottom sheet
                    // Use LoginPageWrapper instead of LoginPage directly
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const LoginPageWrapper(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
    );
  }
}

// Enhanced logo with smoother animation
class EnhancedLogo extends StatelessWidget {
  final AnimationController controller;

  const EnhancedLogo({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Create an even smoother pulsing effect
        final pulseValue = math.sin(controller.value * math.pi);

        // Reduced opacity range for subtler effect
        final opacityValue = 0.9 + (pulseValue * 0.1);

        // Minimal scale change for a professional look
        final scaleValue = 1.0 + (pulseValue * 0.02);

        // More subtle glow effect
        final shadowIntensity = 0.3 + (pulseValue * 0.1);

        return Transform.scale(
          scale: scaleValue,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.red.shade600,
                  Colors.red.shade700.withOpacity(opacityValue),
                ],
                radius: 0.9,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(shadowIntensity * 0.5),
                  blurRadius: 8 + (pulseValue * 3),
                  spreadRadius: 1 + (pulseValue * 0.5),
                  offset: const Offset(0, 3),
                ),
              ],
              shape: BoxShape.circle,
            ),
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 48,
              ),
            ),
          ),
        );
      },
    );
  }
}

// Enhanced background elements with better aesthetics
class EnhancedBackgroundObstacles extends StatefulWidget {
  const EnhancedBackgroundObstacles({super.key});

  @override
  _EnhancedBackgroundObstaclesState createState() =>
      _EnhancedBackgroundObstaclesState();
}

class _EnhancedBackgroundObstaclesState
    extends State<EnhancedBackgroundObstacles>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();

    // Slower animation for subtle professional movement
    _animationController = AnimationController(
      duration: const Duration(seconds: 20),
      vsync: this,
    );

    _animationController.repeat(reverse: true);
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Stack(
          children: [
            // Top-right diagonal element with gradient
            Positioned(
              top: -30 + (_animationController.value * 8),
              right: -20,
              child: Transform.rotate(
                angle: -math.pi / 4,
                child: Opacity(
                  opacity: 0.03,
                  child: Container(
                    width: 120,
                    height: 300,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade900, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(60),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade900.withOpacity(0.1),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Left side circular element - softer
            Positioned(
              left: -50 + (_animationController.value * 5),
              top: size.height * 0.3,
              child: Opacity(
                opacity: 0.04,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      colors: [
                        Colors.red.shade400,
                        Colors.red.shade700.withOpacity(0.8),
                      ],
                      radius: 0.8,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.03),
                        blurRadius: 18,
                        spreadRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Right side professional element
            Positioned(
              right: -30 - (_animationController.value * 8),
              top: size.height * 0.6 + (_animationController.value * 15),
              child: Opacity(
                opacity: 0.05,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.red.shade600, Colors.red.shade900],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                    borderRadius: BorderRadius.circular(40),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade800.withOpacity(0.06),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Bottom obstacle with rotation animation
            Positioned(
              bottom: 120 - (_animationController.value * 10),
              left: size.width * 0.15,
              child: Opacity(
                opacity: 0.035,
                child: Transform.rotate(
                  angle: math.pi / 6 + (_animationController.value * 0.1),
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade500, Colors.red.shade800],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade700.withOpacity(0.06),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Additional floating geometric element
            Positioned(
              top: size.height * 0.4,
              right: size.width * 0.3 + (_animationController.value * 20),
              child: Opacity(
                opacity: 0.03,
                child: Transform.rotate(
                  angle: -math.pi / 12 + (_animationController.value * 0.2),
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Colors.red.shade400, Colors.red.shade700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(15),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.shade500.withOpacity(0.06),
                          blurRadius: 12,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class EnhancedBackgroundElements extends StatelessWidget {
  final AnimationController controller;

  const EnhancedBackgroundElements({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Stack(
      children: [
        // Subtle pattern background with gradient overlay
        Positioned.fill(
          child: Opacity(
            opacity: 0.03,
            child: Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                    'https://placehold.co/100x100/FF0000/FFFFFF?text=+',
                  ),
                  repeat: ImageRepeat.repeat,
                ),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.red.shade100.withOpacity(0.05),
                    Colors.red.shade200.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),

        // Bottom left corner enhanced wave pattern
        Positioned(
          bottom: -50,
          left: -50,
          child: Opacity(
            opacity: 0.05,
            child: CustomPaint(
              size: const Size(250, 250),
              painter: EnhancedWavePainter(Colors.red),
            ),
          ),
        ),

        // Animated subtle diagonal lines
        for (int i = 0; i < 3; i++)
          AnimatedBuilder(
            animation: controller,
            builder: (context, child) {
              return Positioned(
                top: size.height * 0.25 * i,
                left: -100 + (200 * controller.value),
                child: Transform.rotate(
                  angle: math.pi / 4,
                  child: Opacity(
                    opacity: 0.02,
                    child: Container(
                      width: size.width * 1.5,
                      height: 2,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.red.withOpacity(0),
                            Colors.red.withOpacity(0.5),
                            Colors.red,
                            Colors.red.withOpacity(0.5),
                            Colors.red.withOpacity(0),
                          ],
                          stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

        // Floating medical symbols (more subtle)
        for (int i = 0; i < 6; i++)
          Positioned(
            top: size.height * (0.18 + (i * 0.12)),
            left: size.width * ((i % 3) * 0.3 + 0.1),
            child: Opacity(
              opacity: 0.06,
              child: EnhancedEmergencySymbol(
                size: 40 + (i % 3) * 10,
                type:
                    EmergencySymbolType.values[i %
                        EmergencySymbolType.values.length],
                controller: controller,
              ),
            ),
          ),
      ],
    );
  }
}

enum EmergencySymbolType { cross, phoneRing, shield, heart }

class EnhancedEmergencySymbol extends StatelessWidget {
  final double size;
  final EmergencySymbolType type;
  final AnimationController controller;

  const EnhancedEmergencySymbol({
    super.key,
    required this.size,
    required this.type,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final icon = _getIconForType();

    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        // Calculate a more subtle floating effect based on the animation value
        final offset = math.sin(controller.value * math.pi * 2) * 2;

        return Transform.translate(
          offset: Offset(0, offset),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.03),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.red.withOpacity(0.02),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Center(
              child: Icon(
                icon,
                size: size * 0.6,
                color: Colors.red.withOpacity(0.3),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getIconForType() {
    switch (type) {
      case EmergencySymbolType.cross:
        return Icons.local_hospital;
      case EmergencySymbolType.phoneRing:
        return Icons.phone_in_talk;
      case EmergencySymbolType.shield:
        return Icons.shield;
      case EmergencySymbolType.heart:
        return Icons.favorite;
    }
  }
}

class EnhancedWavePainter extends CustomPainter {
  final Color color;

  EnhancedWavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final gradient = LinearGradient(
      colors: [color.withOpacity(0.6), color.withOpacity(0.3)],
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
    );

    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final paint =
        Paint()
          ..shader = gradient.createShader(rect)
          ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height * 0.7);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.5,
      size.width * 0.5,
      size.height * 0.7,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.9,
      size.width,
      size.height * 0.8,
    );
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
