import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'Landing_Page.dart';
import 'widgets/connection_error_widget.dart';
import 'utils/provider_wrapper.dart';
import 'services/location_service.dart';
import 'MapPage.dart';
import 'Chatbot.dart';
import 'Report_Incident.dart';
import 'victimReport.dart';

void main() {
  runApp(const ResQApp());
}

class ResQApp extends StatelessWidget {
  const ResQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQ Emergency App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFE53935),
          primary: const Color(0xFFE53935),
          secondary: const Color(0xFF2979FF),
          surface: Colors.white,
          background: const Color(0xFFF5F5F5),
        ),
        useMaterial3: true,
        fontFamily: 'Poppins',
        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.bold),
          displayMedium: TextStyle(fontWeight: FontWeight.bold),
          bodyLarge: TextStyle(fontSize: 16.0),
        ),
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.transparent,
        ),
      ),
      home: const HomePageWrapper(),
    );
  }
}

// Create a wrapper for HomePage with the required provider
class HomePageWrapper extends StatelessWidget {
  const HomePageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderWrapper(child: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  bool _isLoading = true;
  bool _isConnectionError = false;
  String? _errorMessage;
  String? _cityName;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
    _getCurrentLocation();
  }

  // Load user profile data
  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _isConnectionError = false;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.refreshUserProfile();

      if (authProvider.status == AuthStatus.connectionError) {
        setState(() {
          _isConnectionError = true;
          _errorMessage = authProvider.errorMessage;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error loading profile: ${e.toString()}";
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Retry connection and reload data
  Future<void> _retryConnection() async {
    setState(() {
      _isLoading = true;
      _isConnectionError = false;
      _errorMessage = null;
    });

    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      await authProvider.retryConnection();

      if (authProvider.status == AuthStatus.connectionError) {
        setState(() {
          _isConnectionError = true;
          _errorMessage = authProvider.errorMessage;
        });
      } else {
        await _loadUserProfile();
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Error retrying connection: ${e.toString()}";
        _isLoading = false;
      });
    }
  }

  // Logout handler
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    // Navigate back to landing page
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (route) => false,
    );
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      final locationService = LocationService();
      await locationService.getCurrentLocation(context);
      final city = await locationService.getCityName(context);
      
      if (locationService.currentPosition != null) {
        final position = locationService.currentPosition!;
        setState(() {
          _cityName = city;
          
          // Update the provider with location data
          final authProvider = Provider.of<AuthProvider>(context, listen: false);
          authProvider.setUserLocation(
            city, 
            position.latitude,
            position.longitude
          );
        });
      } else {
        setState(() {
          _cityName = 'Unknown Location';
        });
      }
    } catch (e) {
      debugPrint('Error getting location: $e');
      setState(() {
        _cityName = 'Location Unavailable';
      });
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final user = authProvider.user;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _isConnectionError
              ? ConnectionErrorWidget(onRetry: _retryConnection)
              : SafeArea(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(user?.fullName ?? 'User'),
                      _buildSearchBar(),
                      _buildNavigationTabs(),
                      _buildHeroSection(),
                      _buildSectionTitle('Quick Access'),
                      _buildQuickAccessGrid(),
                      _buildSectionTitle('Emergency Services'),
                      _buildEmergencyServicesSection(),
                      _buildSectionTitle('Recommended'),
                      _buildRecommendedGrid(),
                      _buildSectionTitle('Recent Alerts'),
                      _buildRecentAlertsSection(),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  Widget _buildHeader(String userName) {
    final authProvider = Provider.of<AuthProvider>(context);
    
    // Format coordinates to display instead of city name
    final String locationText = (authProvider.latitude != null && authProvider.longitude != null) 
        ? '${authProvider.latitude!.toStringAsFixed(6)}, ${authProvider.longitude!.toStringAsFixed(6)}'
        : 'Tap to get location';
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Logo and app name
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.red.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.local_fire_department,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Welcome back',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ],
          ),

          // Profile and location
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  if (!_isLoadingLocation) {
                    _getCurrentLocation();
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      _isLoadingLocation 
                          ? SizedBox(
                              width: 16, 
                              height: 16, 
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFE53935),
                              ),
                            )
                          : Icon(Icons.location_on, color: Color(0xFFE53935), size: 16),
                      const SizedBox(width: 4),
                      Text(
                        locationText, // Now shows coordinates instead of city name
                        style: const TextStyle(
                          fontSize: 10, // Smaller font size to fit coordinates
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: () {
                  // Show profile menu
                  showModalBottomSheet(
                    context: context,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.vertical(
                        top: Radius.circular(20),
                      ),
                    ),
                    builder:
                        (context) => Container(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const ListTile(
                                leading: Icon(
                                  Icons.person,
                                  color: Color(0xFFE53935),
                                ),
                                title: Text('My Profile'),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                              ),
                              const ListTile(
                                leading: Icon(
                                  Icons.settings,
                                  color: Color(0xFFE53935),
                                ),
                                title: Text('Settings'),
                                trailing: Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                              ),
                              ListTile(
                                leading: const Icon(
                                  Icons.logout,
                                  color: Color(0xFFE53935),
                                ),
                                title: const Text('Logout'),
                                trailing: const Icon(
                                  Icons.arrow_forward_ios,
                                  size: 16,
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _handleLogout();
                                },
                              ),
                            ],
                          ),
                        ),
                  );
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFE53935),
                      width: 2,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.red.shade50,
                    child: Icon(
                      Icons.person,
                      color: Colors.red.shade700,
                      size: 18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 55,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE53935).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.search,
                color: Color(0xFFE53935),
                size: 20,
              ),
            ),
            const SizedBox(width: 15),
            const Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search emergency services...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.mic, color: Colors.grey, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationTabs() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          _buildNavTab('Home', 0),
          _buildNavTab('Live GPS', 1),
          _buildNavTab('Live Alerts', 2),
          _buildNavTab('Contacts', 3),
          _buildNavTab('First Aid', 4),
        ],
      ),
    );
  }

  Widget _buildNavTab(String title, int index) {
    final isSelected = _selectedIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFE53935) : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? const Color(0xFFE53935) : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade700,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSection() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 15, 20, 10),
      // Remove fixed height to prevent overflow
      // Let the container size according to its content
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFE53935), Color(0xFFFF5252)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        // Modified shadow to prevent overflow issues
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius:
                0, // Added explicit spreadRadius to control shadow expansion
            offset: const Offset(0, 3), // Reduced offset to minimize overflow
          ),
        ],
      ),
      child: ClipRRect(
        // Add this to clip any overflow from the background design elements
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          clipBehavior: Clip.none, // Allow content to overflow the Stack
          children: [
            // Background designs - adjusted positioning to avoid overflow
            Positioned(
              right: -20,
              bottom: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),
            Positioned(
              left: -10,
              top: -10,
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
              ),
            ),

            // Content - Using ConstrainedBox with improved constraints
            ConstrainedBox(
              constraints: const BoxConstraints(
                minHeight: 170,
                maxHeight:
                    210, // Adding a max height to prevent excessive expansion
              ),
              child: Padding(
                padding: const EdgeInsets.all(25),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize:
                            MainAxisSize
                                .min, // Add this to prevent Column from taking all available space
                        children: [
                          const Text(
                            'Emergency?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Get immediate assistance with just one tap',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 15),
                          ElevatedButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (BuildContext context) {
                                  return AlertDialog(
                                    backgroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    title: const Text(
                                      'Report Emergency As',
                                      style: TextStyle(
                                        color: Color(0xFFE53935),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18,
                                      ),
                                    ),
                                    content: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // Close the dialog
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const ReportIncidentPage(),
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Color(0xFFE53935),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 24,
                                            ),
                                          ),
                                          child: const Text(
                                            'Spectator',
                                            style: TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        ElevatedButton(
                                          onPressed: () {
                                            Navigator.pop(
                                              context,
                                            ); // Close the popup
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder:
                                                    (context) =>
                                                        const VictimReportPage(), // update class name if needed
                                              ),
                                            );
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.white,
                                            foregroundColor: Color(0xFFE53935),
                                            side: const BorderSide(
                                              color: Color(0xFFE53935),
                                              width: 2,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 12,
                                              horizontal: 24,
                                            ),
                                          ),
                                          child: const Text('Victim'),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFFE53935),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 20,
                                vertical: 12,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(30),
                              ),
                            ),
                            child: const Text(
                              'SOS',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Icon(
                        Icons.emergency, // Using built-in emergency icon
                        size: 80,
                        color: Colors.white.withOpacity(0.25),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 15),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            'See All',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Report Emergency Button
          Expanded(
            child: _buildQuickAccessButton(
              icon: Icons.report_problem,
              title: 'REPORT\nEMERGENCY',
              subtitle: 'YOU\'RE HERE',
              gradientColors: const [Color(0xFFE53935), Color(0xFFFF5252)],
              textColor: Colors.white,
            ),
          ),
          const SizedBox(width: 15),

          // Live Alert Button
          Expanded(
            child: _buildQuickAccessButton(
              icon: Icons.notifications_active_outlined,
              title: 'LIVE\nALERTS',
              subtitle: 'STAY UPDATED',
              gradientColors: const [Colors.white, Colors.white],
              textColor: Colors.black,
              borderColor: Colors.grey.shade300,
            ),
          ),
        ],
      ),
    );
  }

  // Assuming this is your button building method - modified to handle overflow
  Widget _buildQuickAccessButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required List<Color> gradientColors,
    required Color textColor,
    Color? borderColor,
  }) {
    return Container(
      height: 150, // Fixed height to prevent overflow
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(12),
        border: borderColor != null ? Border.all(color: borderColor) : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {},
          child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, color: textColor, size: 24),
                const SizedBox(height: 8),
                Flexible(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Flexible(
                  child: Text(
                    subtitle,
                    style: TextStyle(
                      color: textColor.withOpacity(0.8),
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyServicesSection() {
    return Container(
      height: 110,
      margin: const EdgeInsets.only(bottom: 5),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _buildEmergencyServiceItem(
            icon: Icons.local_hospital,
            title: 'Medical',
            color: const Color(0xFFE53935),
          ),
          _buildEmergencyServiceItem(
            icon: Icons.local_fire_department,
            title: 'Fire',
            color: const Color(0xFFFF9800),
          ),
          _buildEmergencyServiceItem(
            icon: Icons.local_police,
            title: 'Police',
            color: const Color(0xFF2979FF),
          ),
          _buildEmergencyServiceItem(
            icon: Icons.directions_car,
            title: 'Roadside',
            color: const Color(0xFF43A047),
          ),
          _buildEmergencyServiceItem(
            icon: Icons.family_restroom,
            title: 'Family',
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyServiceItem({
    required IconData icon,
    required String title,
    required Color color,
  }) {
    return Container(
      width: 85,
      margin: const EdgeInsets.symmetric(horizontal: 5),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.15),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Icon(icon, size: 25, color: color),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedGrid() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Automated Emergency Calls
          Expanded(
            child: _buildRecommendedButton(
              icon: Icons.wifi_calling_3,
              title: 'Automated Emergency Calls',
              subtitle: 'Uses mobile data',
              color: Colors.white,
              iconBackgroundColor: const Color(0xFF2979FF).withOpacity(0.1),
              iconColor: const Color(0xFF2979FF),
            ),
          ),
          const SizedBox(width: 15),

          // Social Media Integration
          Expanded(
            child: _buildRecommendedButton(
              icon: Icons.share,
              title: 'Social Media Integration',
              subtitle: 'NEW FEATURE',
              color: Colors.white,
              iconBackgroundColor: const Color(0xFF43A047).withOpacity(0.1),
              iconColor: const Color(0xFF43A047),
              isNew: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required Color iconBackgroundColor,
    required Color iconColor,
    bool isNew = false,
  }) {
    return Container(
      height: 120,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Icon with circular background
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconBackgroundColor,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 18, color: iconColor),
              ),
              if (isNew)
                Expanded(
                  child: Align(
                    alignment: Alignment.topRight,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2979FF).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Text(
                        'NEW',
                        style: TextStyle(
                          color: Color(0xFF2979FF),
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey.shade600,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentAlertsSection() {
    return Container(
      height: 200,
      margin: const EdgeInsets.only(bottom: 10),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        children: [
          _buildAlertItem(
            title: 'Flash Flood Warning',
            location: 'Downtown Area',
            time: '20 min ago',
            color: const Color(0xFF2979FF),
            icon: Icons.waves,
          ),
          _buildAlertItem(
            title: 'Fire Alert',
            location: 'Industrial Zone',
            time: '1 hour ago',
            color: const Color(0xFFFF9800),
            icon: Icons.local_fire_department,
          ),
          _buildAlertItem(
            title: 'Medical Emergency',
            location: 'Central Hospital',
            time: '2 hours ago',
            color: const Color(0xFFE53935),
            icon: Icons.local_hospital,
          ),
        ],
      ),
    );
  }

  Widget _buildAlertItem({
    required String title,
    required String location,
    required String time,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: 200,
      margin: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Status header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: color),
                const SizedBox(width: 8),
                Text(
                  'ACTIVE',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                const Spacer(),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ),

          // Content
          Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      time,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 6,
                    horizontal: 12,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'View Details',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.15),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavBarItem(context,Icons.home_rounded, 'Home', 0),
              _buildNavBarItem(context,Icons.map_rounded, 'Map', 1),

              // Center SOS button
              GestureDetector(
                onTap: () {},
                child: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFE53935), Color(0xFFFF5252)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
              ),

              _buildNavBarItem(context, Icons.notifications_rounded, 'Alerts', 2),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ChatQHomePage()),
                  );
                },
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.message, color: Colors.grey, size: 24),
                    SizedBox(height: 4),
                    Text(
                      'Chat',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ),

            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavBarItem(BuildContext context, IconData icon, String label, int index) {
    return GestureDetector(
      onTap: () {
        if (index == 1) {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const MapPage()),
          );
        } else {
          setState(() {
            _selectedIndex = index;
          });
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color:
                _selectedIndex == index ? const Color(0xFFE53935) : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color:
                  _selectedIndex == index
                      ? const Color(0xFFE53935)
                      : Colors.grey,
              fontSize: 12,
              fontWeight:
                  _selectedIndex == index ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
