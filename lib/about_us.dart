import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeIn;
  late Animation<Offset> _slideHeader;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _fadeIn = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _slideHeader = Tween<Offset>(begin: const Offset(0, -0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          SlideTransition(
            position: _slideHeader,
            child: Container(
              padding: const EdgeInsets.only(top: 50, left: 20, right: 20, bottom: 30),
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.redAccent, Colors.red],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Icon(Icons.local_fire_department, color: Colors.yellow, size: 30),
                    ],
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'About ResQ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 1,
                    ),
                  ),
                  const Text(
                    'Your Lifeline in Emergency Moments',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: FadeTransition(
              opacity: _fadeIn,
              child: Container(
                width: double.infinity,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(40),
                    topRight: Radius.circular(40),
                  ),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 30),
                child: ListView(
                  children: [
                    buildSection(
                      'WHO WE ARE',
                      'At ResQ, we believe that every second counts during an emergency. Our mission is to empower people to get immediate help when they need it most — fast, reliable, and at their fingertips.',
                    ),
                    buildSection(
                      'OUR MISSION',
                      'To save lives by providing fast, reliable, and accessible emergency assistance when it\'s needed most. We are committed to empowering individuals to connect with help instantly — anytime, anywhere.',
                      icon: Icons.favorite_rounded,
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'HOW RESQ WORKS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Wrap(
                      spacing: 20,
                      runSpacing: 20,
                      alignment: WrapAlignment.center,
                      children: [
                        buildFeatureTile(Icons.phone_android, 'Tap ResQ', 'Start your emergency request'),
                        buildFeatureTile(Icons.connect_without_contact, 'Get Connected', 'Reach responders instantly'),
                        buildFeatureTile(Icons.verified_user, 'Stay Safe', 'Help is on the way'),
                      ].map((tile) => SizedBox(width: 100, child: tile)).toList(),
                    ),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildSection(String title, String description, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Colors.redAccent,
              fontSize: 20,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (icon != null)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Icon(icon, color: Colors.redAccent, size: 22),
                ),
              Expanded(
                child: Text(
                  description,
                  style: const TextStyle(
                    fontSize: 15.5,
                    color: Colors.black87,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget buildFeatureTile(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.redAccent,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        const SizedBox(height: 4),
        Text(subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12.5, color: Colors.black54))
      ],
    );
  }
}
