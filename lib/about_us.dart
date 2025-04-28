import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // Add in pubspec.yaml

class AboutUsPage extends StatelessWidget {
  const AboutUsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.redAccent,
      body: SafeArea(
        child: Column(
          children: [
            // Top Red Section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                  // Top Row (Back Button + Fire Icon)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      const Icon(
                        Icons.local_fire_department,
                        color: Colors.yellow,
                        size: 30,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'About ResQ',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Your Lifeline in Emergency Moments',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // White Rounded Container
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(30),
                    topRight: Radius.circular(30),
                  ),
                ),
                child: ListView(
                  children: [
                    const Text(
                      'WHO WE ARE',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'At ResQ, we believe that every second counts during an emergency. '
                      'Our mission is to empower people to get immediate help when they need it most — fast, reliable, and at their fingertips.',
                      style: TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 30),
                    
                    const Text(
                      'OUR MISSION',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.redAccent),
                        const SizedBox(width: 10),
                        Expanded(
                          child: const Text(
                            'To save lives by providing fast, reliable, and accessible emergency assistance when it\'s needed most. '
                            'We are committed to empowering individuals to connect with help instantly — anytime, anywhere.',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),

                    const Text(
                      'HOW RESQ WORKS',
                      style: TextStyle(
                        color: Colors.redAccent,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Icons Row
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        buildFeatureCard(
                          icon: Icons.phone_in_talk,
                          label: 'Tap ResQ',
                          description: 'Start your emergency request',
                        ),
                        buildFeatureCard(
                          icon: Icons.connect_without_contact,
                          label: 'Get Connected',
                          description: 'Reach responders instantly',
                        ),
                        buildFeatureCard(
                          icon: Icons.security,
                          label: 'Stay Safe',
                          description: 'Help is on the way',
                        ),
                      ],
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

  Widget buildFeatureCard({
    required IconData icon,
    required String label,
    required String description,
  }) {
    return Expanded(
      child: Column(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.redAccent,
            child: Icon(icon, color: Colors.white, size: 30),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 5),
          Text(
            description,
            style: const TextStyle(fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
