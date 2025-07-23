import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'Landing_Page.dart';
import 'services/location_service.dart';
import 'services/emergency_report_service.dart'; // Added missing import
import 'Map_Page_for_Volunteer.dart';

class VolunteerDashboard extends StatefulWidget {
  const VolunteerDashboard({super.key});

  @override
  State<VolunteerDashboard> createState() => _VolunteerDashboardState();
}

class _VolunteerDashboardState extends State<VolunteerDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _pendingEmergencies = [];
  Map<String, int> _statusCounts = {
    'pending': 0,
    'responding': 0,
    'on_scene': 0,
  };
  int _unreadNotifications = 0;
  bool _isLoadingLocation = true;
  String? _cityName;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _getCurrentLocation();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      // Get dashboard data from API
      final dashboardData = await authProvider.getDashboardData();

      if (dashboardData != null) {
        setState(() {
          _dashboardData = dashboardData;

          // Extract pending emergencies
          _pendingEmergencies = dashboardData['pending_emergencies'] ?? [];

          // Extract status counts
          _statusCounts = dashboardData['current_status'] ?? {};

          // Extract unread notifications
          _unreadNotifications = dashboardData['unread_notifications'] ?? 0;
        });
      }
    } catch (e) {
      // Handle error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading dashboard: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Get current location
  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);

    try {
      final locationService = LocationService();
      await locationService.getCurrentLocation(context);
      final city = await locationService.getCityName(context);

      if (city != null) {
        setState(() {
          _cityName = city;

          // Update the provider with location data
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          authProvider.setUserLocation(
            city,
            locationService.currentPosition?.latitude,
            locationService.currentPosition?.longitude,
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

  // Fetch emergency data and count status
  Future<void> _fetchEmergencyData() async {
    try {
      final reports = await EmergencyReportService.getEmergencyReports(context);

      // Count statuses
      int pending = 0;
      int responding = 0;
      int onScene = 0;

      for (final report in reports) {
        final status = report['status'] ?? 'PENDING';
        if (status == 'PENDING') {
          pending++;
        } else if (status == 'RESPONDING') {
          responding++;
        } else if (status == 'ON_SCENE') {
          onScene++;
        }
      }

      setState(() {
        _statusCounts = {
          'pending': pending,
          'responding': responding,
          'on_scene': onScene,
        };
      });
    } catch (e) {
      debugPrint('Error fetching emergency data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final teamName = user?.fullName ?? "Volunteer Team";
    final authProvider = Provider.of<AuthProvider>(context);
    final displayCity = authProvider.city ?? _cityName ?? 'Get location';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
            _scaffoldKey.currentState!.openDrawer();
          },
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Icon(
                Icons.volunteer_activism,
                color: Colors.white,
                size: 18,
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                'ResQ Volunteer',
                style: TextStyle(
                  color: Colors.red[500],
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          // Refresh button in app bar
          IconButton(
            onPressed: () {
              _loadDashboardData();
              _fetchEmergencyData();
            },
            icon: Icon(
              Icons.refresh,
              color: Colors.red[700],
            ),
            tooltip: 'Refresh Data',
          ),
          // Location display - made more compact
          GestureDetector(
            onTap: () {
              if (!_isLoadingLocation) {
                _getCurrentLocation();
              }
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8, top: 8, bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              constraints: const BoxConstraints(maxWidth: 120),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _isLoadingLocation
                      ? SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red[700],
                        ),
                      )
                      : Icon(
                        Icons.location_on,
                        color: Colors.red[700],
                        size: 14,
                      ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      displayCity,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.red[700],
                        fontWeight: FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          // User avatar - made smaller
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: CircleAvatar(
              backgroundColor: Colors.red.shade100,
              radius: 14,
              child: Icon(
                Icons.volunteer_activism,
                color: Colors.red[700],
                size: 16,
              ),
            ),
          ),
        ],
      ),
      drawer: _buildDrawer(teamName),
      body: RefreshIndicator(
        onRefresh: () async {
          await _loadDashboardData();
          await _fetchEmergencyData();
        },
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  _buildVolunteerStats(),
                  _buildActiveMissions(),
                  Expanded(
                    child: _pendingEmergencies.isEmpty
                        ? _buildEmptyTaskList()
                        : _buildTaskList(),
                  ),
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Replace the modal bottom sheet with direct navigation to MapPageForVolunteer
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MapPageForVolunteer(),
            ),
          );
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(String teamName) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(color: Colors.red),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.white,
                  radius: 32,
                  child: Icon(
                    Icons.volunteer_activism,
                    size: 36,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  teamName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Volunteer Head',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard, color: Colors.red),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Volunteer Teams'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.medical_services),
            title: const Text('Resources'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: OutlinedButton.icon(
              onPressed: () {
                _handleLogout();
              },
              icon: Icon(Icons.exit_to_app, color: Colors.red[700]),
              label: Text('Sign Out', style: TextStyle(color: Colors.red[700])),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.red[700]!),
                padding: const EdgeInsets.symmetric(
                  vertical: 12,
                  horizontal: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVolunteerStats() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatCard(
            'Pending',
            _statusCounts['pending']?.toString() ?? '0',
            Colors.orange,
          ),
          _buildStatCard(
            'Responding',
            _statusCounts['responding']?.toString() ?? '0',
            Colors.blue,
          ),
          _buildStatCard(
            'On Scene',
            _statusCounts['on_scene']?.toString() ?? '0',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
      ],
    );
  }

  Widget _buildActiveMissions() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.grey[50],
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text(
            'Active Volunteer Missions',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          Text(
            '${_pendingEmergencies.length} tasks',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTaskList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'No active tasks available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
          const SizedBox(height: 8),
          Text(
            'New volunteer tasks will appear here',
            style: TextStyle(fontSize: 14, color: Colors.grey[500]),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _pendingEmergencies.length,
      itemBuilder: (context, index) {
        final task = _pendingEmergencies[index];
        return _buildTaskCard(task);
      },
    );
  }

  Widget _buildTaskCard(Map<String, dynamic> emergency) {
    final String status = emergency['status'] ?? 'UNKNOWN';
    final Color statusColor = _getStatusColor(status);
    final String priority = emergency['priority'] ?? 'MODERATE';
    final String incidentType =
        emergency['incident_type'] ?? 'General Incident';
    final String description =
        emergency['description'] ?? 'No description provided';
    final String reporter = emergency['reporter_type'] ?? 'Anonymous';
    final String reporterName = emergency['reporter_name'] ?? 'Unknown';
    final String reportTimestamp =
        emergency['created_at'] ?? emergency['timeAgo'] ?? '';

    final String location = [
      emergency['address'],
      '${emergency['latitude']?.toStringAsFixed(6)}, ${emergency['longitude']?.toStringAsFixed(6)}',
    ].where((e) => e != null).join(' - ');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: statusColor.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: Row(
              children: [
                Icon(_getStatusIcon(status), color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              incidentType,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              priority,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (location.isNotEmpty)
                        GestureDetector(
                          onTap: () {
                            _openMapWithLocation(
                              emergency['latitude'] as double?,
                              emergency['longitude'] as double?,
                            );
                          },
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ),
                              Icon(
                                Icons.map,
                                size: 16,
                                color: Colors.blue[600],
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Reported by: ',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '$reporter ($reporterName)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      reportTimestamp,
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getStatusColor(status).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      color: _getStatusColor(status),
                      fontWeight: FontWeight.w500,
                      fontSize: 12,
                    ),
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () {
                    _showEmergencyDetailsDialog(emergency);
                  },
                  child: const Text('Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Show emergency details dialog - without update status button
  void _showEmergencyDetailsDialog(Map<String, dynamic> emergency) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getStatusIcon(emergency['status'] ?? 'PENDING'),
                  color: _getStatusColor(emergency['status'] ?? 'PENDING'),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text('${emergency['incident_type'] ?? 'Emergency'} Details'),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _detailRow(
                    'Incident Type',
                    emergency['incident_type'] ?? 'General Incident',
                  ),
                  _detailRow(
                    'Reporter Type',
                    emergency['reporter_type'] ?? 'Anonymous',
                  ),
                  _detailRow(
                    'Reporter Name',
                    emergency['reporter_name'] ?? 'Unknown',
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.pop(context);
                      _openMapWithLocation(
                        emergency['latitude'] as double?,
                        emergency['longitude'] as double?,
                      );
                    },
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 90,
                          child: Text(
                            'Location:',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            [
                              emergency['address'],
                              '${emergency['latitude']?.toStringAsFixed(6)}, ${emergency['longitude']?.toStringAsFixed(6)}',
                            ].where((e) => e != null).join(' - '),
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                        Icon(
                          Icons.open_in_new,
                          size: 16,
                          color: Colors.blue[600],
                        ),
                      ],
                    ),
                  ),
                  _detailRow('Status', emergency['status'] ?? 'PENDING'),
                  _detailRow('Priority', emergency['priority'] ?? 'MODERATE'),
                  _detailRow(
                    'Time',
                    emergency['created_at'] ?? emergency['timeAgo'] ?? '',
                  ),
                  _detailRow(
                    'Contact',
                    emergency['contact_info'] ?? 'No contact info',
                  ),
                  _detailRow('Description', emergency['description'] ?? ''),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
          ),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
        ],
      ),
    );
  }

  // Helper method to get status color
  Color _getStatusColor(String? status) {
    switch (status) {
      case 'PENDING':
        return Colors.orange;
      case 'RESPONDING':
        return Colors.blue;
      case 'ON_SCENE':
        return Colors.green;
      case 'RESOLVED':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  // Add the missing _getStatusIcon method
  IconData _getStatusIcon(String? status) {
    switch (status) {
      case 'PENDING':
        return Icons.hourglass_empty;
      case 'RESPONDING':
        return Icons.directions_run;
      case 'ON_SCENE':
        return Icons.location_on;
      case 'RESOLVED':
        return Icons.check_circle;
      default:
        return Icons.help_outline;
    }
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _selectedIndex,
      onTap: (index) {
        setState(() {
          _selectedIndex = index;
        });
      },
      backgroundColor: Colors.white,
      selectedItemColor: Colors.red,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'Dashboard',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.people), label: 'Teams'),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }

  // Handle logout
  Future<void> _handleLogout() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    await authProvider.logout();

    // Navigate back to landing page
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LandingPage()),
      (route) => false,
    );
  }

  // Add a new method to open MapPage with specific location
  void _openMapWithLocation(double? latitude, double? longitude) {
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location coordinates not available'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MapPageForVolunteer(),
      ),
    );
  }
}