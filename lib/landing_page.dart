import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'signup.dart';
import 'login.dart';
import 'about_us.dart';

class LandingPage extends StatefulWidget {
  const LandingPage({super.key});

  @override
  State<LandingPage> createState() => _LandingPageState();
}

class _LandingPageState extends State<LandingPage> with TickerProviderStateMixin {
  late AnimationController _logoController;
  late AnimationController _textController;
  late AnimationController _bottomCardController;
  late AnimationController _loginFadeController;
  late AnimationController _aboutFadeController;

  late Animation<double> _logoScale;
  late Animation<double> _fadeText;
  late Animation<Offset> _slideText;
  late Animation<Offset> _slideCard;
  late Animation<double> _fadeLogin;
  late Animation<double> _fadeAbout;

  @override
  void initState() {
    super.initState();

    _logoController = AnimationController(duration: const Duration(milliseconds: 800), vsync: this);
    _textController = AnimationController(duration: const Duration(milliseconds: 700), vsync: this);
    _bottomCardController = AnimationController(duration: const Duration(milliseconds: 900), vsync: this);
    _loginFadeController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);
    _aboutFadeController = AnimationController(duration: const Duration(milliseconds: 1000), vsync: this);

    _logoScale = Tween<double>(begin: 0.7, end: 1.0)
        .animate(CurvedAnimation(parent: _logoController, curve: Curves.easeOutBack));
    _fadeText = CurvedAnimation(parent: _textController, curve: Curves.easeIn);
    _slideText = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero)
        .animate(CurvedAnimation(parent: _textController, curve: Curves.easeOut));
    _slideCard = Tween<Offset>(begin: const Offset(0, 1), end: Offset.zero)
        .animate(CurvedAnimation(parent: _bottomCardController, curve: Curves.easeOutBack));
    _fadeLogin = CurvedAnimation(parent: _loginFadeController, curve: Curves.easeIn);
    _fadeAbout = CurvedAnimation(parent: _aboutFadeController, curve: Curves.easeIn);

    _logoController.forward();
    Future.delayed(const Duration(milliseconds: 300), () => _textController.forward());
    Future.delayed(const Duration(milliseconds: 600), () => _bottomCardController.forward());
    Future.delayed(const Duration(milliseconds: 1000), () => _loginFadeController.forward());
    Future.delayed(const Duration(milliseconds: 1200), () => _aboutFadeController.forward());
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    // 👇 Fix to restore system UI overlay style every time this page appears
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
  }

  @override
  void dispose() {
    _logoController.dispose();
    _textController.dispose();
    _bottomCardController.dispose();
    _loginFadeController.dispose();
    _aboutFadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Soft gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.white, Color(0xFFFFEBEE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),

                // Animated Logo
                ScaleTransition(
                  scale: _logoScale,
                  child: Hero(
                    tag: 'logo',
                    child: Image.asset('assets/logo.png', height: 100),
                  ),
                ),

                const SizedBox(height: 20),

                // Animated Text
                SlideTransition(
                  position: _slideText,
                  child: FadeTransition(
                    opacity: _fadeText,
                    child: Column(
                      children: const [
                        Text(
                          'RESQ',
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
                            color: Colors.redAccent,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Emergency Help\nAt Your Fingertips',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.black54,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const Spacer(),

                // Animated Bottom Button Card
                SlideTransition(
                  position: _slideCard,
                  child: Container(
                    width: double.infinity,
                    margin: const EdgeInsets.symmetric(horizontal: 24),
                    padding: const EdgeInsets.symmetric(vertical: 30),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const RoleBasedSignUpPage()),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.redAccent,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 80, vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                            elevation: 8,
                            textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          child: const Text('Join Us'),
                        ),

                        const SizedBox(height: 20),

                        // Animated Login Text
                        FadeTransition(
                          opacity: _fadeLogin,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const LoginPage()),
                              );
                            },
                            child: RichText(
                              text: const TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(color: Colors.black87, fontSize: 16),
                                children: [
                                  TextSpan(
                                    text: 'Login',
                                    style: TextStyle(
                                      color: Colors.redAccent,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Animated About Us Text
                        FadeTransition(
                          opacity: _fadeAbout,
                          child: TextButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => const AboutUsPage()),
                              );
                            },
                            icon: const Icon(Icons.info_outline, size: 18, color: Colors.black54),
                            label: const Text(
                              'About Us',
                              style: TextStyle(color: Colors.black54, fontSize: 15),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
