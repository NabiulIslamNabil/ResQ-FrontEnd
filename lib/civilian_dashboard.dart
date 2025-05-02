import 'dart:async';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:app_settings/app_settings.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:fl_chart/fl_chart.dart';

class CivilianDashboard extends StatefulWidget {
  const CivilianDashboard({super.key});

  @override
  State<CivilianDashboard> createState() => _CivilianDashboardState();
}

class _CivilianDashboardState extends State<CivilianDashboard> with TickerProviderStateMixin {
  String _location = 'Fetching location...';
  late Timer _timer;
  final String _userFullName = 'Jonathan Wilson';
  bool _showLocation = false;
  late AnimationController _sosController;

  final List<Map<String, dynamic>> incidents = [
    {
      "area": "Sector 5",
      "type": "Fire",
      "victims": 3,
      "status": "Rescued",
      "image": "assets/firefighter.png",
    },
    {
      "area": "Zone 9",
      "type": "Flood",
      "victims": 5,
      "status": "Ongoing",
      "image": "assets/logo.png",
    },
    {
      "area": "Area X",
      "type": "Gas Leak",
      "victims": 2,
      "status": "Rescued",
      "image": "assets/logo.png",
    },
  ];

  @override
  void initState() {
    super.initState();
    _initializeLocationUpdates();
    _sosController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  Future<void> _initializeLocationUpdates() async {
    await _handleLocationPermission();
    _fetchLocation();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _fetchLocation());
  }

  Future<void> _handleLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      await _showLocationSettingsDialog();
      return;
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      await _showLocationSettingsDialog();
    }
  }

  Future<void> _showLocationSettingsDialog() async {
    return showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Location Required"),
        content: const Text("Please enable location services to continue."),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              AppSettings.openAppSettings();
            },
            child: const Text("Open Settings"),
          ),
        ],
      ),
    );
  }

  Future<void> _fetchLocation() async {
    try {
      Position pos = await Geolocator.getCurrentPosition();
      setState(() {
        _location = '${pos.latitude.toStringAsFixed(4)}, ${pos.longitude.toStringAsFixed(4)}';
        _showLocation = true;
      });
    } catch (e) {
      setState(() => _location = 'Unable to get location');
    }
  }

  List<PieChartSectionData> buildChartData() {
    final Map<String, int> typeCounts = {};
    for (var i in incidents) {
      typeCounts[i["type"]] = (typeCounts[i["type"]] ?? 0) + 1;
    }
    final colors = [Colors.redAccent, Colors.blueAccent, Colors.orange];
    int index = 0;

    return typeCounts.entries.map((entry) {
      final color = colors[index++ % colors.length];
      return PieChartSectionData(
        color: color,
        value: entry.value.toDouble(),
        title: '',
        radius: 30,
      );
    }).toList();
  }

  @override
  void dispose() {
    _timer.cancel();
    _sosController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDECEC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(radius: 30, backgroundColor: Colors.white, child: Icon(Icons.person, size: 30)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_userFullName, style: GoogleFonts.lato(fontSize: 20, fontWeight: FontWeight.bold)),
                        if (_showLocation)
                          Text("📍 $_location",
                              style: GoogleFonts.lato(fontSize: 13, color: Colors.black87)),
                      ],
                    ),
                  ),
                  IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
                ],
              ),
              const SizedBox(height: 20),

              // Incident Widget
              const Text("📢 Live Incident Feed", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              CarouselSlider(
                items: incidents.map((i) {
                  final bgColor = i["type"] == "Fire"
                      ? Colors.red.shade100
                      : i["type"] == "Flood"
                          ? Colors.blue.shade100
                          : Colors.orange.shade100;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 5),
                    decoration: BoxDecoration(
                      color: bgColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(10),
                          child: Image.asset(i["image"], width: 60),
                        ),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("Area: ${i["area"]}", style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text("Type: ${i["type"]}"),
                              Text("Victims: ${i["victims"]}"),
                              Text("Status: ${i["status"]}"),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                options: CarouselOptions(autoPlay: true, height: 130),
              ),

              const SizedBox(height: 20),

              // Donut Chart
              const Text("🧭 Today's Incident Summary", style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              Center(
                child: SizedBox(
                  height: 160,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      PieChart(PieChartData(
                        sections: buildChartData(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                      )),
                      Text("${incidents.length}",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 24)),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Buttons
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _buildActionButton(Icons.map, "View Map", () {}),
                  _buildActionButton(Icons.local_hospital, "Ambulance", () {}),
                  _buildActionButton(Icons.local_police, "Call Police", () {}),
                  _buildActionButton(Icons.refresh, "Refresh Location", _fetchLocation),
                ],
              ),

              const SizedBox(height: 30),

              // Emergency Button
              Center(
                child: ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.1)
                      .animate(CurvedAnimation(parent: _sosController, curve: Curves.easeInOut)),
                  child: GestureDetector(
                    onTap: () => _showEmergencyPopup(),
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          colors: [Colors.redAccent, Colors.deepOrange],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        boxShadow: [
                          BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 30, spreadRadius: 5),
                        ],
                      ),
                      child: const Center(
                        child: Text('EMERGENCY\nREPORTING',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onPressed) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        elevation: 6,
      ),
    );
  }

  void _showEmergencyPopup() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Text('Report Emergency As:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            icon: const Icon(Icons.remove_red_eye),
            label: const Text('Spectator'),
            onPressed: () {}, // TODO
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            icon: const Icon(Icons.person),
            label: const Text('Victim'),
            onPressed: () {}, // TODO
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
          ),
        ]),
      ),
    );
  }
}
