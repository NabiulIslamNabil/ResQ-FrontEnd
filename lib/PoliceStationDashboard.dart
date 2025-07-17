import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'services/emergency_report_service.dart';
import 'providers/auth_provider.dart';
import 'Landing_Page.dart';
import 'MapPage.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ResQ - Police Station Dashboard',
      theme: ThemeData(
        primaryColor: Colors.red,
        colorScheme: ColorScheme.light(
          primary: Colors.red,
          secondary: Colors.red.shade700,
          surface: Colors.white,
        ),
        fontFamily: 'Roboto',
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0,
        ),
      ),
      home: const PoliceDashboard(),
    );
  }
}

// Priority enum for emergency classification
enum Priority { critical, high, moderate, low }

// Emergency class to hold data
class Emergency {
  final String id;
  final Priority priority;
  final String name;
  final String status; // Added missing status property
  final int age;
  final String message;
  final String timeAgo;
  final double latitude;
  final double longitude;
  bool isResponding;
  final String incidentType;

  Emergency({
    required this.id,
    required this.priority,
    required this.name,
    required this.age,
    required this.message,
    required this.timeAgo,
    required this.latitude,
    required this.longitude,
    required this.isResponding,
    required this.incidentType,
    this.status = 'PENDING', // Default value
  });
}

class PoliceDashboard extends StatefulWidget {
  const PoliceDashboard({super.key});

  @override
  State<PoliceDashboard> createState() => _PoliceDashboardState();
}

class _PoliceDashboardState extends State<PoliceDashboard>
    with SingleTickerProviderStateMixin {
  String selectedFilter = 'All';
  bool showAssignedOnly = false;
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Status options for emergencies
  final List<Map<String, String>> statusOptions = [
    {'value': 'PENDING', 'label': 'Pending'},
    {'value': 'RESPONDING', 'label': 'Responding'},
    {'value': 'ON_SCENE', 'label': 'On Scene'},
    {'value': 'RESOLVED', 'label': 'Resolved'},
  ];

  bool _isLoading = false;
  List<dynamic> _apiEmergencies = [];
  Map<String, int> _statusCounts = {
    'pending': 0,
    'responding': 0,
    'on_scene': 0,
    'resolved': 0,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchEmergencies();
  }

  // Fetch emergencies from the API
  Future<void> _fetchEmergencies() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final apiEmergencies = await EmergencyReportService.getEmergencyReports(
        context,
      );

      // Count emergencies by status
      int pending = 0;
      int responding = 0;
      int onScene = 0;
      int resolved = 0;

      for (final emergency in apiEmergencies) {
        final status = emergency['status'] ?? 'PENDING';
        if (status == 'PENDING') {
          pending++;
        } else if (status == 'RESPONDING')
          responding++;
        else if (status == 'ON_SCENE')
          onScene++;
        else if (status == 'RESOLVED')
          resolved++;
      }

      setState(() {
        _apiEmergencies = apiEmergencies;
        _statusCounts = {
          'pending': pending,
          'responding': responding,
          'on_scene': onScene,
          'resolved': resolved,
        };
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching emergencies: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Update emergency status
  Future<void> _updateEmergencyStatus(String id, String newStatus) async {
    try {
      setState(() {
        _isLoading = true;
      });

      final success = await EmergencyReportService.updateEmergencyStatus(
        context: context,
        emergencyId: id,
        status: newStatus,
      );

      if (success) {
        // Refresh the emergency list
        await _fetchEmergencies();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Emergency status updated successfully')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update emergency status')),
        );
      }
    } catch (e) {
      debugPrint('Error updating status: $e');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Show the status change dialog for API emergency objects
  void _showStatusUpdateDialog(Map<String, dynamic> emergency) {
    String selectedStatus = emergency['status'] ?? 'PENDING';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
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
                      selectedStatus = value;
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
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: Text('Update'),
            ),
          ],
        );
      },
    );
  }

  // Get the status label from the status code
  String _getStatusLabel(Emergency emergency) {
    if (emergency.isResponding) {
      return 'Responding';
    } else {
      return 'Pending';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // Sample data for emergency reports
  final List<Emergency> emergencies = [
    Emergency(
      id: '1',
      priority: Priority.critical,
      name: 'Nabiul Alom',
      age: 36,
      message: "There's a fire in my house, 3rd floor",
      timeAgo: '3 mins ago',
      latitude: 23.810331,
      longitude: 90.412521, // Dhaka coordinates
      isResponding: false,
      incidentType: 'Fire',
    ),
    Emergency(
      id: '2',
      priority: Priority.high,
      name: 'Khurshed Ahmed',
      age: 42,
      message: "My neighbor is threatening me with a knife",
      timeAgo: '7 mins ago',
      latitude: 23.807331,
      longitude: 90.415521,
      isResponding: false,
      incidentType: 'Assault',
    ),
    Emergency(
      id: '3',
      priority: Priority.moderate,
      name: 'Farida Begum',
      age: 68,
      message: "I've fallen and can't get up, need medical assistance",
      timeAgo: '12 mins ago',
      latitude: 23.809331,
      longitude: 90.411521,
      isResponding: true,
      incidentType: 'Medical',
    ),
    Emergency(
      id: '4',
      priority: Priority.low,
      name: 'Rahima Khatun',
      age: 29,
      message: "My car has been stolen from the parking lot",
      timeAgo: '24 mins ago',
      latitude: 23.812331,
      longitude: 90.410521,
      isResponding: false,
      incidentType: 'Theft',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      drawer: _buildDrawer(),
      body: Column(
        children: [
          _buildTabBar(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildMapTab(),
                _buildEmergencyListTab(),
                _buildStatsTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateEmergencyDialog();
        },
        backgroundColor: Colors.red,
        child: const Icon(Icons.add),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
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
              Icons.local_police_rounded,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'ResQ',
            style: TextStyle(
              color: Colors.red[500],
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(Icons.location_on, color: Colors.red[700], size: 16),
              const SizedBox(width: 4),
              Text(
                'Dhaka, BD',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        CircleAvatar(
          backgroundColor: Colors.red.shade100,
          radius: 16,
          child: Icon(Icons.security, color: Colors.red[700], size: 18),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildDrawer() {
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
                  child: Icon(Icons.security, size: 36, color: Colors.red[700]),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Dhaka Central',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Police Station',
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
            title: const Text('Emergency Reports'),
            onTap: () {
              Navigator.pop(context);
              _tabController.animateTo(1);
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
              onPressed: () {},
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

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        indicatorColor: Colors.red,
        labelColor: Colors.red,
        unselectedLabelColor: Colors.grey,
        tabs: const [
          Tab(icon: Icon(Icons.map), text: 'Map'),
          Tab(icon: Icon(Icons.assignment), text: 'Reports'),
          Tab(icon: Icon(Icons.bar_chart), text: 'Stats'),
        ],
      ),
    );
  }

  Widget _buildMapTab() {
    return Column(
      children: [
        _buildMap(),
        _buildFilterTabs(),
        Expanded(child: _buildEmergencyList()),
      ],
    );
  }

  Widget _buildEmergencyListTab() {
    return Column(
      children: [
        _buildFilterTabs(),
        Expanded(child: _buildEmergencyList(showAll: true)),
      ],
    );
  }

  Widget _buildStatsTab() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Emergency Statistics',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Total Emergencies',
                '${_apiEmergencies.length}',
                Colors.red,
                Icons.emergency,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Active Responses',
                '${_statusCounts['responding'] ?? 0}',
                Colors.green,
                Icons.local_police,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildStatCard(
                'Critical Incidents',
                '${_apiEmergencies.where((e) => (e['priority'] ?? '') == 'CRITICAL').length}',
                Colors.red[900]!,
                Icons.warning,
              ),
              const SizedBox(width: 16),
              _buildStatCard(
                'Resolved Today',
                '${_statusCounts['resolved'] ?? 0}',
                Colors.blue,
                Icons.check_circle,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 24),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMap() {
    return Container(
      height: 200,
      color: const Color(0xFFF5F5F5),
      child: const Center(
        child: Text('Map View Goes Here', style: TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip('All'),
                  _buildFilterChip('Critical'),
                  _buildFilterChip('Medical'),
                  _buildFilterChip('Theft'),
                  _buildFilterChip('Assault'),
                ],
              ),
            ),
          ),
          Switch(
            value: showAssignedOnly,
            onChanged: (value) {
              setState(() {
                showAssignedOnly = value;
              });
            },
            activeColor: Colors.red,
          ),
          Text(
            'Assigned',
            style: TextStyle(
              fontSize: 14,
              color: showAssignedOnly ? Colors.red : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedFilter = label;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? Colors.red : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.black87,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildEmergencyList({bool showAll = false}) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    // Filter the API emergencies based on selected filters
    List<dynamic> filteredEmergencies =
        _apiEmergencies.where((emergency) {
          // Check if assigned only filter is applied
          if (showAssignedOnly && (emergency['status'] ?? '') != 'RESPONDING') {
            return false;
          }

          // Apply incident type filter
          if (selectedFilter == 'All') {
            return true;
          } else if (selectedFilter == 'Critical') {
            return (emergency['priority'] ?? '') == 'CRITICAL';
          } else if (selectedFilter == 'Medical') {
            final type = emergency['incident_type'] ?? '';
            return type.toLowerCase().contains('medical');
          } else if (selectedFilter == 'Theft') {
            final type = emergency['incident_type'] ?? '';
            return type.toLowerCase().contains('theft');
          } else if (selectedFilter == 'Assault') {
            final type = emergency['incident_type'] ?? '';
            return type.toLowerCase().contains('assault');
          }

          return true;
        }).toList();

    return Container(
      color: Colors.grey[50],
      child:
          filteredEmergencies.isEmpty
              ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.search_off, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text(
                      'No emergencies match your filters',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                  ],
                ),
              )
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: filteredEmergencies.length,
                itemBuilder: (context, index) {
                  final emergency = filteredEmergencies[index];
                  return _buildEmergencyCard(emergency);
                },
              ),
    );
  }

  Widget _buildEmergencyCard(Map<String, dynamic> emergency) {
    final String status = emergency['status'] ?? 'PENDING';
    final String priority = emergency['priority'] ?? 'MODERATE';
    final bool isResponding = status == 'RESPONDING' || status == 'ON_SCENE';
    final String reporter = emergency['reporter_name'] ?? 'Anonymous';
    final String reporterAge = emergency['reporter_age']?.toString() ?? '';
    final String reporterInfo =
        reporterAge.isEmpty ? reporter : '$reporter • $reporterAge yrs';
    final String message =
        emergency['description'] ?? 'No description provided';
    final String timeAgo = emergency['created_at'] ?? 'Recently';
    final String incidentType =
        emergency['incident_type'] ?? 'General Incident';

    Color statusColor;
    IconData priorityIcon;
    String priorityText;

    // Set colors and icons based on priority
    switch (priority) {
      case 'CRITICAL':
        statusColor = Colors.red;
        priorityIcon = Icons.warning;
        priorityText = 'Critical';
        break;
      case 'HIGH':
        statusColor = Colors.deepOrange;
        priorityIcon = Icons.priority_high;
        priorityText = 'High';
        break;
      case 'MODERATE':
        statusColor = Colors.orange;
        priorityIcon = Icons.report_problem;
        priorityText = 'Moderate';
        break;
      case 'LOW':
        statusColor = Colors.blue;
        priorityIcon = Icons.info;
        priorityText = 'Low';
        break;
      default:
        statusColor = Colors.grey;
        priorityIcon = Icons.help_outline;
        priorityText = priority;
    }

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
                Icon(priorityIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        incidentType,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        reporterInfo,
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                    ],
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
                    priorityText,
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Text(
              message,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Text(
                  timeAgo,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                ),
                const Spacer(),
                if (isResponding)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 14),
                        SizedBox(width: 4),
                        Text(
                          status,
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    _showEmergencyDetailsDialog(emergency);
                  },
                  child: const Text('Details'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () {
                    _showStatusUpdateDialog(emergency);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isResponding ? Colors.grey : Colors.red,
                  ),
                  child: Text(isResponding ? 'Update' : 'Respond'),
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
                Text('${emergency['incident_type'] ?? 'Emergency'} Details'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _detailRow(
                  'Reported by',
                  emergency['reporter_name'] ?? 'Anonymous',
                ),
                _detailRow('Message', emergency['description'] ?? ''),
                _detailRow('Time', emergency['created_at'] ?? ''),
                _detailRow('Status', emergency['status'] ?? 'PENDING'),
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
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          'Lat: ${emergency['latitude']}, Long: ${emergency['longitude']}',
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
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Close'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _showStatusUpdateDialog(emergency);
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Update Status'),
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

  void _showCreateEmergencyDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Add Emergency Report'),
            content: const SizedBox(
              height: 200,
              child: Center(
                child: Text('Emergency creation form would go here'),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('Create'),
              ),
            ],
          ),
    );
  }

  // Add a method to open MapPage with specific location
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
            (context) => MapPage(initialLocation: LatLng(latitude, longitude)),
      ),
    );
  }

  // Keep only one version of _getStatusColor and _getPriorityIcon methods and delete the duplicates
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
        return Colors.red;
    }
  }

  // Helper method to get priority icon for API emergencies
  IconData _getPriorityIcon(String priority) {
    switch (priority) {
      case 'CRITICAL':
        return Icons.warning;
      case 'HIGH':
        return Icons.priority_high;
      case 'MODERATE':
        return Icons.report_problem;
      case 'LOW':
        return Icons.info;
      default:
        return Icons.help_outline;
    }
  }

  // Fix logout method - there's only one version needed
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
}
