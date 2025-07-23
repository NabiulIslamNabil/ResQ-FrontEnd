import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
// Add this import for LatLng
import 'providers/auth_provider.dart';
import 'Landing_Page.dart';
import 'services/location_service.dart';
import 'services/emergency_report_service.dart';
import 'Map_Page_For_Fire_Station.dart';

class FireStationDashboard extends StatefulWidget {
  const FireStationDashboard({super.key});

  @override
  State<FireStationDashboard> createState() => _FireStationDashboardState();
}

class _FireStationDashboardState extends State<FireStationDashboard> {
  int _selectedIndex = 0;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _isLoading = true;
  bool _isLoadingLocation = true;
  Map<String, dynamic>? _dashboardData;
  List<dynamic> _emergencies = [];
  String? _cityName;

  // Status options from API
  final List<Map<String, String>> statusOptions = [
    {'value': 'PENDING', 'label': 'Pending'},
    {'value': 'RESPONDING', 'label': 'Responding'},
    {'value': 'ON_SCENE', 'label': 'On Scene'},
    {'value': 'RESOLVED', 'label': 'Resolved'},
  ];

  Map<String, int> _statusCounts = {
    'pending': 0,
    'responding': 0,
    'on_scene': 0,
  };

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
    _getCurrentLocation();
  }

  // Load dashboard data from API
  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final dashboardData = await authProvider.getDashboardData();

      if (dashboardData != null) {
        setState(() {
          _dashboardData = dashboardData;

          // Extract status counts
          _statusCounts = {
            'pending': dashboardData['current_status']['pending'] ?? 0,
            'responding': dashboardData['current_status']['responding'] ?? 0,
            'on_scene': dashboardData['current_status']['on_scene'] ?? 0,
          };

          // Extract emergencies list
          _emergencies = dashboardData['pending_emergencies'] ?? [];
        });
      }
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
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

  // Update emergency status with API integration
  Future<void> _updateEmergencyStatus(String id, String newStatus) async {
    try {
      setState(() => _isLoading = true);

      final success = await EmergencyReportService.updateEmergencyStatus(
        context: context,
        emergencyId: id,
        status: newStatus,
      );

      if (success) {
        // Refresh the emergency list
        await _loadDashboardData();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Status updated successfully')));
      } else {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to update status')));
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // Show status update dialog with API integration
  // Replace the _showStatusUpdateDialog method with this fixed version

void _showStatusUpdateDialog(Map<String, dynamic> emergency) {
  String selectedStatus = emergency['status'] ?? 'PENDING';

  showDialog(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Update Emergency Status'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Current Status: ${emergency['status'] ?? 'PENDING'}'),
            const SizedBox(height: 16),
            Text('Select new status:'),
            const SizedBox(height: 8),
            ...statusOptions.map(
              (status) => RadioListTile<String>(
                title: Text(status['label']!),
                value: status['value']!,
                groupValue: selectedStatus,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      selectedStatus = value;
                    });
                  }
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(context).pop();
              _updateEmergencyStatus(emergency['id'], selectedStatus);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              elevation: 2,
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: Text(
              'Update',
              style: TextStyle(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

  Widget _buildEmergencyCard(Map<String, dynamic> emergency) {
    final status = emergency['status'] ?? 'PENDING';
    final statusColor = _getStatusColor(status);
    final priority = emergency['priority'] ?? 'MODERATE';
    final description = emergency['description'] ?? 'No description provided';
    final reporter = emergency['reporter_type'] ?? 'Anonymous';
    final reporterName = emergency['reporter_name'] ?? 'Unknown';
    final reporterContact = emergency['contact_info'] ?? 'No contact info';
    final reportTimestamp =
        emergency['created_at'] ?? emergency['timeAgo'] ?? '';
    final incidentType = emergency['incident_type'] ?? 'General Emergency';

    final location = [
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
                Icon(_getPriorityIcon(priority), color: statusColor, size: 20),
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
                if (reporterContact.isNotEmpty &&
                    reporterContact != 'No contact info')
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.contact_phone,
                          size: 14,
                          color: Colors.grey[700],
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Contact: $reporterContact',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[700],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Row(
                  children: [
                    Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      reportTimestamp,
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
                const Spacer(),
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
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () => _showEmergencyDetailsDialog(emergency),
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _showStatusUpdateDialog(emergency),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getStatusColor(status),
                  ),
                  child: Text('Update Status'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showEmergencyDetailsDialog(Map<String, dynamic> emergency) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Row(
              children: [
                Icon(
                  _getPriorityIcon(emergency['priority'] ?? 'MODERATE'),
                  color: _getStatusColor(emergency['status'] ?? 'PENDING'),
                ),
                const SizedBox(width: 8),
                const Text('Emergency Details'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _detailRow(
                    'Incident Type',
                    emergency['incident_type'] ?? 'General Emergency',
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
                      children: [
                        SizedBox(
                          width: 80,
                          child: Text(
                            'Location:',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            emergency['location'] ??
                                '${emergency['latitude']}, ${emergency['longitude']}',
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
                  _detailRow(
                    'Description',
                    emergency['description'] ?? emergency['message'] ?? '',
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showStatusUpdateDialog(emergency);
                },
                style: ElevatedButton.styleFrom(backgroundColor: const Color.fromARGB(255, 254, 254, 254)),
                child: const Text('Update Status'),
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
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return Icons.warning;
      case 'HIGH':
        return Icons.priority_high;
      case 'MODERATE':
        return Icons.report_problem;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<AuthProvider>(context).user;
    final stationName = user?.fullName ?? "Fire Station";
    final authProvider = Provider.of<AuthProvider>(context);
    final displayCity = authProvider.city ?? _cityName ?? 'Tap to get location';

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
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'ResQ Fire',
              style: TextStyle(
                color: Colors.red[500],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          GestureDetector(
            onTap: () {
              if (!_isLoadingLocation) {
                _getCurrentLocation();
              }
            },
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  _isLoadingLocation
                      ? SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.red[700],
                        ),
                      )
                      : Icon(
                        Icons.location_on,
                        color: Colors.red[700],
                        size: 16,
                      ),
                  const SizedBox(width: 4),
                  Text(
                    displayCity,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.red[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
          CircleAvatar(
            backgroundColor: Colors.red.shade100,
            radius: 16,
            child: Icon(
              Icons.local_fire_department,
              color: Colors.red[700],
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      drawer: _buildDrawer(stationName),
      body:
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  _buildFireStatus(),
                  _buildActiveEmergencies(),
                  Expanded(
                    child:
                        _emergencies.isEmpty
                            ? _buildEmptyEmergencyList()
                            : _buildEmergencyList(),
                  ),
                ],
              ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showActionOptions();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDrawer(String stationName) {
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
                    Icons.local_fire_department,
                    size: 36,
                    color: Colors.red[700],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  stationName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Fire Station',
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
            leading: const Icon(Icons.emergency),
            title: const Text('Fire Emergencies'),
            onTap: () {
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Fire Team'),
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

  Widget _buildFireStatus() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatusCard(
            'Pending',
            _statusCounts['pending']?.toString() ?? '0',
            Colors.red,
          ),
          _buildStatusCard(
            'Responding',
            _statusCounts['responding']?.toString() ?? '0',
            Colors.orange,
          ),
          _buildStatusCard(
            'On Scene',
            _statusCounts['on_scene']?.toString() ?? '0',
            Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStatusCard(String title, String value, Color color) {
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

  Widget _buildActiveEmergencies() {
    // Get critical emergencies
    final criticalEmergencies =
        _emergencies
            .where(
              (e) => e['priority'] == 'CRITICAL' && e['status'] != 'RESOLVED',
            )
            .toList();

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Active Fire Emergencies',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (criticalEmergencies.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red[700]),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      criticalEmergencies[0]['description'] ??
                          'Critical emergency reported',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmergencyList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _emergencies.length,
      itemBuilder: (context, index) {
        final emergency = _emergencies[index];
        return _buildEmergencyCard(emergency);
      },
    );
  }

  Widget _buildEmptyEmergencyList() {
    return Center(
      child: Text(
        'No active emergencies',
        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
      ),
    );
  }

  Color _getStatusColor(String status) {
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
        BottomNavigationBarItem(
          icon: Icon(Icons.local_fire_department),
          label: 'Emergencies',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
      ],
    );
  }

  void _showActionOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.add_alert, color: Colors.red),
                ),
                title: const Text('Create Fire Alert'),
                subtitle: const Text('Alert citizens about fire hazards'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle create alert
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.fire_truck, color: Colors.blue),
                ),
                title: const Text('Dispatch Fire Truck'),
                subtitle: const Text('Send response team to location'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle dispatch
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.people, color: Colors.green),
                ),
                title: const Text('Coordinate Team'),
                subtitle: const Text('Manage firefighter teams'),
                onTap: () {
                  Navigator.pop(context);
                  // Handle team coordination
                },
              ),
            ],
          ),
        );
      },
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
        const SnackBar(content: Text('Location coordinates not available')),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder:
            (context) => MapPageForFireStation(),
      ),
    );
  }
}
