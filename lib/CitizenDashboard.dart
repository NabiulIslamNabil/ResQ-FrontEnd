import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

void main() {
  runApp(ResQApp());
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ResQ Emergency',
      theme: ThemeData(
        primarySwatch: MaterialColor(0xFFE53E3E, {
          50: Color(0xFFFFF5F5),
          100: Color(0xFFFED7D7),
          200: Color(0xFFFEB2B2),
          300: Color(0xFFFC8181),
          400: Color(0xFFF56565),
          500: Color(0xFFE53E3E),
          600: Color(0xFFDD1A1A),
          700: Color(0xFFB91C1C),
          800: Color(0xFF991B1B),
          900: Color(0xFF7F1D1D),
        }),
        scaffoldBackgroundColor: Color(0xFFF7FAFC),
        fontFamily: 'SF Pro Display',
        cardTheme: CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      home: ResQDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}

class ResQDashboard extends StatefulWidget {
  const ResQDashboard({super.key});

  @override
  _ResQDashboardState createState() => _ResQDashboardState();
}

class _ResQDashboardState extends State<ResQDashboard>
    with TickerProviderStateMixin {
  bool _emergencyActive = false;
  bool _showEmergencyDialog = false;
  bool _showReporterTypeDialog = false;
  bool _showLocationDialog = false;
  bool _showFirstAidDialog = false;
  bool _showReportDialog = false;
  int _selectedTab = 0;
  String _userLocation = "Fetching location..."; // Changed to be dynamic
  final String _userName = "Tarneem Zaman";
  String _emergencyStatus = "Safe";
  String _selectedReporterType = "";
  List<Map<String, dynamic>> _activeAlerts = [];
  Timer? _alertTimer;
  bool _isLoadingLocation = true;

  late AnimationController _pulseController;
  late AnimationController _glowController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _glowAnimation;

  // BDRCS Color Palette
  static const Color bdrcsPrimary = Color(0xFFE53E3E);
  static const Color bdrcsSecondary = Color(0xFF2B6CB0);
  static const Color bdrcsSuccess = Color(0xFF38A169);
  static const Color bdrcsWarning = Color(0xFFD69E2E);
  static const Color bdrcsGray = Color(0xFF718096);
  static const Color bdrcsLightGray = Color(0xFFF7FAFC);
  static const Color bdrcsBackground = Color(0xFFFFFFFF);

  final List<Map<String, dynamic>> _emergencyTypes = [
    {
      'icon': Icons.local_fire_department,
      'title': 'Fire',
      'color': bdrcsPrimary,
    },
    {
      'icon': Icons.medical_services,
      'title': 'Medical',
      'color': Color(0xFFDD1A1A),
    },
    {'icon': Icons.security, 'title': 'Security', 'color': bdrcsSecondary},
    {'icon': Icons.warning_amber, 'title': 'Hazard', 'color': bdrcsWarning},
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      duration: Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _glowController = AnimationController(
      duration: Duration(seconds: 3),
      vsync: this,
    )..repeat();
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_glowController);
    _generateMockAlerts();
    _startAlertTimer();

    // Add this to fetch the user location when the dashboard initializes
    _getCurrentLocation();
  }

  // Updated method to get the current location with better error handling and emulator detection
  Future<void> _getCurrentLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _userLocation = "Fetching location...";
    });
    
    try {
      // Check for location permissions first
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() {
            _userLocation = 'Location access denied';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _userLocation = 'Location permission denied';
          _isLoadingLocation = false;
        });
        return;
      }

      // Get the current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high
      );
      
      // Check if this is an emulator with default position (common emulator location is Mountain View)
      bool isEmulatorDefault = position.latitude == 37.4219983 && 
                              position.longitude == -122.084;
      
      if (isEmulatorDefault) {
        // For emulators, we'll use a more relevant default location or get it from the auth provider
        final authProvider = Provider.of<AuthProvider>(context, listen: false);
        if (authProvider.city != null && authProvider.city!.isNotEmpty) {
          setState(() {
            _userLocation = authProvider.city!;
          });
        } else {
          // Use a default location that makes more sense for your app context
          setState(() {
            _userLocation = 'Dhaka'; // Or any other default city relevant to your users
          });
        }
      } else {
        // Real device with real coordinates - get actual location
        List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, 
          position.longitude
        );

        if (placemarks.isNotEmpty) {
          Placemark place = placemarks[0];
          // Build location string based on available data
          String locationName = "";
          
          // Prioritize locality (city)
          if (place.locality != null && place.locality!.isNotEmpty) {
            locationName = place.locality!;
          } 
          // Fall back to sublocality or administrative area if locality is empty
          else if (place.subLocality != null && place.subLocality!.isNotEmpty) {
            locationName = place.subLocality!;
          }
          else if (place.administrativeArea != null && place.administrativeArea!.isNotEmpty) {
            locationName = place.administrativeArea!;
          }
          // Use country as a last resort
          else if (place.country != null && place.country!.isNotEmpty) {
            locationName = place.country!;
          } else {
            locationName = 'Unknown Location';
          }
          
          // Update UI with location name
          setState(() {
            _userLocation = locationName;
            
            // Update the provider with location data
            final authProvider = Provider.of<AuthProvider>(context, listen: false);
            authProvider.setUserLocation(
              locationName,
              position.latitude,
              position.longitude
            );
          });
        } else {
          setState(() {
            _userLocation = 'Location unavailable';
          });
        }
      }
    } catch (e) {
      print('Error getting location: $e');
      setState(() {
        _userLocation = 'Location error';
      });
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  void _generateMockAlerts() {
    _activeAlerts = [
      {
        'icon': Icons.local_fire_department,
        'title': 'Fire Emergency - Building fire on 3rd floor',
        'time': '3 min ago',
        'severity': 'HIGH',
        'location': 'House #45, Road 12, Banani, Dhaka',
        'reporter': 'Rasel Alom, 36 years old',
      },
      {
        'icon': Icons.traffic,
        'title': 'Traffic Incident - Highway 95',
        'time': '8 min ago',
        'severity': 'MEDIUM',
        'location': 'Highway 95, Dhaka',
        'reporter': 'Traffic Police',
      },
      {
        'icon': Icons.water_damage,
        'title': 'Flood Warning - Riverside Area',
        'time': '15 min ago',
        'severity': 'HIGH',
        'location': 'Riverside, Dhaka',
        'reporter': 'Local Authority',
      },
    ];
  }

  void _startAlertTimer() {
    _alertTimer = Timer.periodic(Duration(seconds: 30), (timer) {
      if (mounted) {
        setState(() {
          _generateMockAlerts();
        });
      }
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _glowController.dispose();
    _alertTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Remove this line as we're not using it and directly using _userLocation
    // final authProvider = Provider.of<AuthProvider>(context, listen: false);
    // final displayLocation = authProvider.city ?? _userLocation;

    return Scaffold(
      backgroundColor: bdrcsLightGray,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(
                  child: IndexedStack(
                    index: _selectedTab,
                    children: [
                      _buildMainDashboard(),
                      _buildAlertsPage(),
                      _buildContactsPage(),
                      _buildProfilePage(),
                    ],
                  ),
                ),
                _buildBottomNav(),
              ],
            ),
          ),
          if (_showReporterTypeDialog) _buildReporterTypeDialog(),
          if (_showEmergencyDialog) _buildEmergencyDialog(),
          if (_showLocationDialog) _buildLocationDialog(),
          if (_showFirstAidDialog) _buildFirstAidDialog(),
          if (_showReportDialog) _buildReportDialog(),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [bdrcsLightGray, bdrcsBackground, bdrcsLightGray],
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [bdrcsPrimary, Color(0xFFDD1A1A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: bdrcsPrimary.withOpacity(0.25),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Icon(Icons.favorite, color: Colors.white, size: 32),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ResQ Citizen DashBoard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2D3748),
                    letterSpacing: -0.5,
                  ),
                ),
                Text(
                  'Emergency Response System',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: bdrcsGray,
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _emergencyActive ? bdrcsPrimary : bdrcsSuccess,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: (_emergencyActive
                                    ? bdrcsPrimary
                                    : bdrcsSuccess)
                                .withOpacity(0.4),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      _emergencyStatus,
                      style: TextStyle(
                        color: bdrcsGray,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 8),
                    GestureDetector(
                      onTap: _isLoadingLocation ? null : _getCurrentLocation,
                      child: Row(
                        children: [
                          _isLoadingLocation 
                              ? SizedBox(
                                  width: 14, 
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: bdrcsPrimary,
                                  ),
                                )
                              : Icon(
                                  Icons.location_on,
                                  color: bdrcsPrimary,
                                  size: 14,
                                ),
                          SizedBox(width: 4),
                          Text(
                            _userLocation,
                            style: TextStyle(
                              color: bdrcsGray,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          _buildNotificationBadge(),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge() {
    return Stack(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Icon(Icons.notifications, color: bdrcsPrimary, size: 24),
        ),
        if (_activeAlerts.isNotEmpty)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: bdrcsPrimary,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
              child: Center(
                child: Text(
                  '${_activeAlerts.length}',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMainDashboard() {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Column(
        children: [
          SizedBox(height: 24),
          _buildStatsCards(),
          SizedBox(height: 24),
          _buildEmergencyButton(),
          SizedBox(height: 32),
          _buildQuickActions(),
          SizedBox(height: 32),
          _buildLiveMap(),
          SizedBox(height: 24),
          _buildRecentActivity(),
          SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            '12',
            'Active Emergencies',
            '+3 from yesterday',
            Icons.local_fire_department,
            bdrcsPrimary,
            Colors.red.shade50,
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildStatCard(
            '24',
            'Available Volunteers',
            '+2 online now',
            Icons.group,
            bdrcsSecondary,
            Colors.blue.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String number,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    Color backgroundColor,
  ) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: backgroundColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 16),
          Text(
            number,
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              color: bdrcsGray,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyButton() {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _emergencyActive ? _pulseAnimation.value : 1.0,
          child: GestureDetector(
            onTap: () {
              setState(() => _showReporterTypeDialog = true);
              HapticFeedback.heavyImpact();
            },
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  colors: [bdrcsPrimary, Color(0xFFDD1A1A), Color(0xFFB91C1C)],
                  stops: [0.0, 0.7, 1.0],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: bdrcsPrimary.withOpacity(0.4),
                    blurRadius: 32,
                    spreadRadius: 8,
                  ),
                  BoxShadow(
                    color: bdrcsPrimary.withOpacity(0.2),
                    blurRadius: 64,
                    spreadRadius: 16,
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber, size: 64, color: Colors.white),
                  SizedBox(height: 12),
                  Text(
                    'EMERGENCY',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    'Tap to Report',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQuickActions() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Actions',
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  Icons.phone,
                  'Call 911',
                  bdrcsPrimary,
                  () => _makeEmergencyCall(),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  Icons.medical_services,
                  'First Aid',
                  Color(0xFFDD1A1A),
                  () => setState(() => _showFirstAidDialog = true),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionCard(
                  Icons.location_on,
                  'Share Location',
                  bdrcsSecondary,
                  () => _shareLocation(),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildActionCard(
                  Icons.report,
                  'Report Incident',
                  bdrcsWarning,
                  () => setState(() => _showReportDialog = true),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard(
    IconData icon,
    String title,
    Color color,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                color: Color(0xFF2D3748),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLiveMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [bdrcsLightGray, Colors.blue.shade50],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.map, color: bdrcsSecondary, size: 56),
                    SizedBox(height: 12),
                    Text(
                      'Live Map',
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'Real-time emergency tracking',
                      style: TextStyle(color: bdrcsGray, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            Positioned(
              top: 16,
              left: 16,
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: bdrcsPrimary,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Text(
                      'LIVE',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
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

  Widget _buildRecentActivity() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activity',
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 20,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 20),
          ...List.generate(3, (index) {
            final activities = [
              'Location updated',
              'Emergency contact added',
              'First aid guide accessed',
            ];
            final times = ['2 min ago', '1 hour ago', '3 hours ago'];
            final icons = [
              Icons.location_on,
              Icons.person_add,
              Icons.medical_services,
            ];
            return Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: bdrcsPrimary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icons[index], color: bdrcsPrimary, size: 20),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      activities[index],
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Text(
                    times[index],
                    style: TextStyle(
                      color: bdrcsGray,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAlertsPage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber, color: bdrcsPrimary, size: 28),
              SizedBox(width: 12),
              Text(
                'Active Emergency Alerts',
                style: TextStyle(
                  color: Color(0xFF2D3748),
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          ..._activeAlerts.map((alert) => _buildAlertCard(alert)),
        ],
      ),
    );
  }

  Widget _buildAlertCard(Map<String, dynamic> alert) {
    Color severityColor =
        alert['severity'] == 'HIGH' ? bdrcsPrimary : bdrcsWarning;
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: severityColor.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: severityColor.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: severityColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(alert['icon'], color: severityColor, size: 28),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: severityColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            alert['severity'],
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          alert['time'],
                          style: TextStyle(
                            color: bdrcsGray,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 8),
                    Text(
                      alert['title'],
                      style: TextStyle(
                        color: Color(0xFF2D3748),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (alert['location'] != null) ...[
            SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.location_on, color: bdrcsGray, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Location: ${alert['location']}',
                    style: TextStyle(
                      color: bdrcsGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (alert['reporter'] != null) ...[
            SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.person, color: bdrcsGray, size: 16),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Reporter: ${alert['reporter']}',
                    style: TextStyle(
                      color: bdrcsGray,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContactsPage() {
    final contacts = [
      {
        'name': 'Emergency Services',
        'number': '911',
        'icon': Icons.local_fire_department,
      },
      {
        'name': 'Poison Control',
        'number': '1-800-222-1222',
        'icon': Icons.healing,
      },
      {'name': 'Crisis Hotline', 'number': '988', 'icon': Icons.support_agent},
      {
        'name': 'Local Police',
        'number': '(555) 123-4567',
        'icon': Icons.local_police,
      },
    ];

    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Contacts',
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 24),
          ...contacts.map((contact) => _buildContactCard(contact)),
        ],
      ),
    );
  }

  Widget _buildContactCard(Map<String, dynamic> contact) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: bdrcsPrimary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(contact['icon'], color: bdrcsPrimary, size: 28),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact['name'],
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  contact['number'],
                  style: TextStyle(
                    color: bdrcsGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _makeCall(contact['number']),
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: bdrcsSuccess.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.phone, color: bdrcsSuccess, size: 24),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfilePage() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Profile',
            style: TextStyle(
              color: Color(0xFF2D3748),
              fontSize: 28,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          SizedBox(height: 24),
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Color(0xFFE2E8F0)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 16,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [bdrcsPrimary, Color(0xFFDD1A1A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Center(
                    child: Text(
                      'TZ',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 16),
                Text(
                  _userName,
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'BDRCS Volunteer',
                  style: TextStyle(
                    color: bdrcsGray,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: _buildProfileStat('Emergency Reports', '3'),
                    ),
                    Container(width: 1, height: 40, color: Color(0xFFE2E8F0)),
                    Expanded(
                      child: _buildProfileStat('Volunteer Hours', '124'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),
          _buildProfileOption(Icons.person, 'Personal Information'),
          _buildProfileOption(Icons.location_on, 'Location Settings'),
          _buildProfileOption(Icons.notifications, 'Notifications'),
          _buildProfileOption(Icons.security, 'Privacy & Security'),
          _buildProfileOption(Icons.help, 'Help & Support'),
          _buildProfileOption(Icons.info, 'About'),
        ],
      ),
    );
  }

  Widget _buildProfileStat(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: Color(0xFF2D3748),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            color: bdrcsGray,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildProfileOption(IconData icon, String title) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: () {},
        child: Container(
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFFE2E8F0)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bdrcsPrimary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: bdrcsPrimary, size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Color(0xFF2D3748),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: bdrcsGray, size: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 16,
            offset: Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home, 'Home', 0),
          _buildNavItem(Icons.warning_amber, 'Alerts', 1),
          _buildNavItem(Icons.phone, 'Contacts', 2),
          _buildNavItem(Icons.chat_bubble_outline, 'Chatbot', 3),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index) {
    bool isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedTab = index),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color:
              isSelected ? bdrcsPrimary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? bdrcsPrimary : bdrcsGray, size: 24),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? bdrcsPrimary : bdrcsGray,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  



  Widget _buildReporterTypeDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Who are you reporting as?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 24),
              _buildReporterOption('Emergency Victim', 'I need immediate help'),
              _buildReporterOption('Witness', 'I saw an emergency situation'),
              _buildReporterOption(
                'Helper',
                'I want to help with an emergency',
              ),
              SizedBox(height: 16),
              TextButton(
                onPressed:
                    () => setState(() => _showReporterTypeDialog = false),
                child: Text('Cancel'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReporterOption(String type, String description) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedReporterType = type;
          _showReporterTypeDialog = false;
          _showEmergencyDialog = true;
        });
      },
      child: Container(
        width: double.infinity,
        margin: EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bdrcsPrimary.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: bdrcsPrimary.withOpacity(0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              type,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 4),
            Text(description, style: TextStyle(fontSize: 14, color: bdrcsGray)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmergencyDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Emergency Type',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 24),
              GridView.builder(
                shrinkWrap: true,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1,
                ),
                itemCount: _emergencyTypes.length,
                itemBuilder: (context, index) {
                  final type = _emergencyTypes[index];
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _showEmergencyDialog = false;
                        _showLocationDialog = true;
                      });
                    },
                    child: Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: type['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: type['color'].withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(type['icon'], color: type['color'], size: 40),
                          SizedBox(height: 12),
                          Text(
                            type['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showEmergencyDialog = false),
                  child: Text('Cancel'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.location_on, color: bdrcsPrimary, size: 48),
              SizedBox(height: 16),
              Text(
                'Emergency Reported Successfully',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              Text(
                'Your location has been shared with emergency services. Help is on the way.',
                style: TextStyle(fontSize: 14, color: bdrcsGray),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showLocationDialog = false;
                      _emergencyActive = true;
                      _emergencyStatus = "Emergency Active";
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: bdrcsPrimary,
                    padding: EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'OK',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
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

  Widget _buildFirstAidDialog() {
    final firstAidSteps = [
      'Check for responsiveness',
      'Call for emergency help',
      'Check breathing and pulse',
      'Start CPR if needed',
      'Control bleeding',
      'Treat for shock',
    ];

    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.medical_services,
                    color: Color(0xFFDD1A1A),
                    size: 32,
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Basic First Aid Steps',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20),
              ...firstAidSteps.asMap().entries.map((entry) {
                return Container(
                  margin: EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Color(0xFFDD1A1A),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '${entry.key + 1}',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
              SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _showFirstAidDialog = false),
                  child: Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportDialog() {
    return Container(
      color: Colors.black.withOpacity(0.5),
      child: Center(
        child: Container(
          margin: EdgeInsets.all(24),
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report Incident',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF2D3748),
                ),
              ),
              SizedBox(height: 20),
              TextField(
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: 'Describe the incident...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: bdrcsPrimary),
                  ),
                ),
              ),
              SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed:
                          () => setState(() => _showReportDialog = false),
                      child: Text('Cancel'),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() => _showReportDialog = false);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Incident reported successfully'),
                            backgroundColor: bdrcsSuccess,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bdrcsPrimary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        'Submit',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _makeEmergencyCall() {
    // In a real app, this would use url_launcher to make a phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling emergency services...'),
        backgroundColor: bdrcsPrimary,
      ),
    );
  }

  void _makeCall(String number) {
    // In a real app, this would use url_launcher to make a phone call
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Calling $number...'),
        backgroundColor: bdrcsSuccess,
      ),
    );
  }

  void _shareLocation() {
    // In a real app, this would use location services and sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Location shared successfully'),
        backgroundColor: bdrcsSuccess,
      ),
    );
  }
}
