import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ Emergency App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.red,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: const AboutUsPage(),
    );
  }
}

class AboutUsPage extends StatefulWidget {
  const AboutUsPage({super.key});

  @override
  State<AboutUsPage> createState() => _AboutUsPageState();
}

class _AboutUsPageState extends State<AboutUsPage> {
  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Header Section
          Container(
            padding: const EdgeInsets.only(
              top: 40, // Reduced top padding
              left: 20,
              right: 20,
              bottom: 50, // Adjusted for overlap
            ),
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFFE53935), Color(0xFFD32F2F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              image: DecorationImage(
                image: const AssetImage(
                  'assets/images/firefighter_silhouette.png',
                ),
                fit: BoxFit.cover,
                colorFilter: ColorFilter.mode(
                  Colors.red.withOpacity(0.7),
                  BlendMode.srcATop,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Icon(
                      Icons.local_fire_department,
                      color: Colors.yellow,
                      size: 30,
                    ),
                  ],
                ),
                const SizedBox(height: 10), // Reduced spacing here
                const Padding(
                  padding: EdgeInsets.only(left: 15.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'About ResQ',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
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
                const SizedBox(height: 5), // Reduced spacing here
              ],
            ),
          ),

          // Content - Now in a Stack to create overlap effect
          Column(
            children: [
              // Spacer to push content down
              SizedBox(
                height: MediaQuery.of(context).padding.top + 170,
              ), // Reduced to move content up
              // Content Container with radius that overlaps the red part
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                    // Add a shadow for better depth effect
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -4),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 30,
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView(
                          children: [
                            buildSection(
                              'WHO WE ARE',
                              'At ResQ, we believe that every second counts during an emergency. Our mission is to empower people to get immediate help when they need it most — fast, reliable, and at their fingertips.',
                              textColor: Colors.red.shade800,
                            ),
                            buildSection(
                              'OUR MISSION',
                              'To save lives by providing fast, reliable, and accessible emergency assistance when it\'s needed most. We are committed to empowering individuals to connect with help instantly — anytime, anywhere.',
                              icon: Icons.favorite_rounded,
                              textColor: Colors.red.shade800,
                            ),
                            const SizedBox(height: 20),
                            Text(
                              'HOW RESQ WORKS',
                              style: TextStyle(
                                color: Colors.red.shade800,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 20),
                            buildFeatureTiles(),
                            const SizedBox(height: 28),
                            buildSection(
                              'EMERGENCY SERVICES',
                              'ResQ provides access to critical emergency services including Medical, Fire, Police, and Roadside assistance. Our network ensures you get the right help, right away.',
                              icon: Icons.health_and_safety_outlined,
                              textColor: Colors.red.shade800,
                            ),
                            const SizedBox(height: 10),
                            buildEmergencyServices(),
                          ],
                        ),
                      ),
                      // Copyright section
                      const Divider(height: 40),
                      Column(
                        children: [
                          Text(
                            '© ${DateTime.now().year} ResQ Emergency Services',
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your Safety is Our Priority',
                            style: TextStyle(
                              color: Colors.grey.shade500,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSection(
    String title,
    String description, {
    IconData? icon,
    Color? textColor,
  }) {
    final Color titleColor = textColor ?? Colors.redAccent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: titleColor,
              fontSize: 20,
              fontWeight: FontWeight.bold,
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
                  child: Icon(icon, color: titleColor, size: 22),
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
          ),
        ],
      ),
    );
  }

  Widget buildFeatureTiles() {
    return Wrap(
      spacing: 20,
      runSpacing: 20,
      alignment: WrapAlignment.center,
      children: [
        SizedBox(
          width: 100,
          child: buildFeatureTile(
            Icons.phone_android,
            'Tap ResQ',
            'Start your emergency request',
          ),
        ),
        SizedBox(
          width: 100,
          child: buildFeatureTile(
            Icons.connect_without_contact,
            'Get Connected',
            'Reach responders instantly',
          ),
        ),
        SizedBox(
          width: 100,
          child: buildFeatureTile(
            Icons.verified_user,
            'Stay Safe',
            'Help is on the way',
          ),
        ),
      ],
    );
  }

  Widget buildFeatureTile(IconData icon, String title, String subtitle) {
    return Column(
      children: [
        CircleAvatar(
          radius: 26,
          backgroundColor: Colors.red.shade700,
          child: Icon(icon, color: Colors.white, size: 26),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12.5, color: Colors.black54),
        ),
      ],
    );
  }

  Widget buildEmergencyServices() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        buildServiceIcon(
          Icons.medical_services,
          'Medical',
          Colors.red.shade100,
        ),
        buildServiceIcon(
          Icons.local_fire_department,
          'Fire',
          Colors.orange.shade100,
        ),
        buildServiceIcon(Icons.local_police, 'Police', Colors.blue.shade100),
        buildServiceIcon(Icons.car_repair, 'Roadside', Colors.green.shade100),
      ],
    );
  }

  Widget buildServiceIcon(IconData icon, String label, Color bgColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: bgColor,
          child: Icon(icon, color: Colors.grey.shade800, size: 22),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade800,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
