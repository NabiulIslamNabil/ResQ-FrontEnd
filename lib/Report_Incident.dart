import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/emergency_report_service.dart';

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final Color primaryRed = const Color(0xFFE53935);
  final Color secondaryRed = const Color(0xFFFF8A80);
  final Color darkBlue = const Color(0xFF263238);
  final Color lightGrey = const Color(0xFFF5F5F5);

  String? selectedIncidentType;
  String? selectedFloor;
  String? fireAmount;
  String? peopleCount;
  int _currentStep = 0;
  bool _isSubmitting = false;
  Position? _currentPosition;

  // Form controllers
  final TextEditingController _contactNameController = TextEditingController();
  final TextEditingController _contactPhoneController = TextEditingController();
  final TextEditingController _incidentDetailsController =
      TextEditingController();

  final List<String> incidentTypes = [
    'Fire Incident',
    'Flood Incident',
    'Gas Leak',
    'Building Collapse',
    'Pet Rescue',
    'Others',
  ];

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  @override
  void dispose() {
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    _incidentDetailsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      setState(() {
        _currentPosition = position;
      });
    } catch (e) {
      debugPrint('Error getting location: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(),
      body: SafeArea(
        child: Column(
          children: [
            _buildStepIndicator(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Hero text
                    Text(
                      'Report an Incident',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Help is on the way. Provide details so we can assist you better.',
                      style: TextStyle(fontSize: 15, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 32),

                    // Current location card
                    _buildLocationCard(),
                    const SizedBox(height: 24),

                    // Form fields
                    _buildIncidentTypeSelector(),
                    const SizedBox(height: 24),

                    // Dynamic fields based on incident type
                    if (selectedIncidentType == 'Fire Incident')
                      _buildFireIncidentFields(),
                    if (selectedIncidentType == 'Flood Incident')
                      _buildFloodIncidentFields(),
                    if (selectedIncidentType == 'Gas Leak')
                      _buildGasLeakFields(),
                    if (selectedIncidentType == 'Building Collapse')
                      _buildBuildingCollapseFields(),
                    if (selectedIncidentType == 'Pet Rescue')
                      _buildPetRescueFields(),

                    if (selectedIncidentType != null)
                      const SizedBox(height: 24),

                    _buildAttachmentField(),
                    const SizedBox(height: 24),

                    _buildContactField(),
                    const SizedBox(height: 32),

                    _buildSubmitButton(),
                    const SizedBox(height: 32),

                    _buildEmergencyNumbersSection(),
                    const SizedBox(height: 16),

                    _buildCopyright(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back, color: darkBlue),
        onPressed: () {},
      ),
      actions: [
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: darkBlue),
          onPressed: () {},
        ),
        IconButton(
          icon: Icon(Icons.help_outline, color: darkBlue),
          onPressed: () {},
        ),
      ],
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.local_fire_department, color: primaryRed, size: 28),
          const SizedBox(width: 8),
          Text(
            'ResQ',
            style: TextStyle(
              color: darkBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ],
      ),
      centerTitle: true,
    );
  }

  Widget _buildStepIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildStepDot(0, 'Type'),
          _buildStepLine(0, 1),
          _buildStepDot(1, 'Details'),
          _buildStepLine(1, 2),
          _buildStepDot(2, 'Submit'),
        ],
      ),
    );
  }

  Widget _buildStepDot(int step, String label) {
    bool isActive = _currentStep >= step;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: isActive ? primaryRed : Colors.grey[300],
            shape: BoxShape.circle,
          ),
          child:
              isActive
                  ? Icon(Icons.check, color: Colors.white, size: 16)
                  : Center(
                    child: Text(
                      '${step + 1}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? primaryRed : Colors.grey[500],
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildStepLine(int fromStep, int toStep) {
    bool isActive = _currentStep >= toStep;
    return Container(
      width: 60,
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 8),
      color: isActive ? primaryRed : Colors.grey[300],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.location_on, color: primaryRed),
              const SizedBox(width: 8),
              Text(
                'Current Location',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: darkBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: lightGrey,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Expanded(
                  child:
                      _currentPosition != null
                          ? Text(
                            'Lat: ${_currentPosition!.latitude}, Lon: ${_currentPosition!.longitude}',
                            style: TextStyle(color: Colors.grey[800]),
                          )
                          : Row(
                            children: [
                              SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryRed,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Fetching location...',
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                            ],
                          ),
                ),
                Icon(
                  _currentPosition != null
                      ? Icons.my_location
                      : Icons.location_searching,
                  color: primaryRed,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: _getCurrentLocation,
            icon: Icon(Icons.refresh, color: primaryRed, size: 18),
            label: Text(
              'Refresh Location',
              style: TextStyle(color: primaryRed, fontSize: 14),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: const Size(0, 30),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIncidentTypeSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What type of incident are you reporting?',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 0.9,
          children:
              incidentTypes
                  .map((type) => _buildIncidentTypeCard(type))
                  .toList(),
        ),
      ],
    );
  }

  Widget _buildIncidentTypeCard(String type) {
    final bool isSelected = selectedIncidentType == type;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedIncidentType = type;
          _currentStep = 1; // Move to next step on selection
        });
      },
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? primaryRed.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryRed : Colors.grey.shade300,
          ),
          boxShadow:
              isSelected
                  ? [
                    BoxShadow(
                      color: primaryRed.withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                  : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _getIconForIncidentType(type),
              color: isSelected ? primaryRed : Colors.grey.shade600,
              size: 32,
            ),
            const SizedBox(height: 8),
            Text(
              type,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: isSelected ? primaryRed : Colors.grey.shade800,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForIncidentType(String type) {
    switch (type) {
      case 'Fire Incident':
        return Icons.local_fire_department;
      case 'Flood Incident':
        return Icons.water_damage;
      case 'Gas Leak':
        return Icons.warning_amber;
      case 'Building Collapse':
        return Icons.domain_disabled;
      case 'Pet Rescue':
        return Icons.pets;
      default:
        return Icons.report_problem;
    }
  }

  // Add these methods to build specific incident detail forms

  Widget _buildFireIncidentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fire Incident Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailField('Fire Size', [
          'Small (contained to single object)',
          'Medium (single room)',
          'Large (multiple rooms)',
          'Severe (whole building)',
        ]),
        const SizedBox(height: 16),
        _buildDetailField('People Involved', [
          'No one',
          '1-5 people',
          '5-20 people',
          '20+ people',
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _incidentDetailsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Details',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildFloodIncidentFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Flood Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailField('Water Level', [
          'Ankle deep',
          'Knee deep',
          'Waist deep',
          'Above waist',
        ]),
        const SizedBox(height: 16),
        _buildDetailField('Area Affected', [
          'Street only',
          'Few buildings',
          'Entire block',
          'Multiple blocks',
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _incidentDetailsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Details',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildGasLeakFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Gas Leak Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailField('Smell Intensity', [
          'Faint',
          'Moderate',
          'Strong',
          'Overwhelming',
        ]),
        const SizedBox(height: 16),
        _buildDetailField('Area Affected', [
          'Single room',
          'Single building',
          'Multiple buildings',
          'Entire block',
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _incidentDetailsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Details',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildBuildingCollapseFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Building Collapse Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailField('Collapse Severity', [
          'Partial',
          'Half collapsed',
          'Mostly collapsed',
          'Complete collapse',
        ]),
        const SizedBox(height: 16),
        _buildDetailField('People Trapped', [
          'None',
          'Few people',
          'Many people',
          'Unknown',
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _incidentDetailsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Details',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildPetRescueFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pet Rescue Details',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        _buildDetailField('Animal Type', ['Dog', 'Cat', 'Bird', 'Other']),
        const SizedBox(height: 16),
        _buildDetailField('Situation', [
          'Trapped',
          'Injured',
          'Aggressive',
          'Abandoned',
        ]),
        const SizedBox(height: 16),
        TextField(
          controller: _incidentDetailsController,
          maxLines: 3,
          decoration: InputDecoration(
            labelText: 'Additional Details',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailField(String label, List<String> options) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w500,
            fontSize: 14,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children:
                options.map((option) {
                  return RadioListTile<String>(
                    title: Text(option),
                    value: option,
                    groupValue:
                        label == 'Fire Size' ||
                                label == 'Smell Intensity' ||
                                label == 'Collapse Severity' ||
                                label == 'Water Level'
                            ? fireAmount
                            : peopleCount,
                    onChanged: (value) {
                      setState(() {
                        if (label == 'Fire Size' ||
                            label == 'Smell Intensity' ||
                            label == 'Collapse Severity' ||
                            label == 'Water Level') {
                          fireAmount = value;
                        } else {
                          peopleCount = value;
                        }
                      });
                    },
                    contentPadding: EdgeInsets.symmetric(horizontal: 16),
                    dense: true,
                  );
                }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildAttachmentField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Add Photos/Videos',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Image picker functionality would be implemented here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Image upload not implemented in this demo',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_a_photo, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Text(
                        'Add Photo',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  // Video picker functionality would be implemented here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Video upload not implemented in this demo',
                      ),
                    ),
                  );
                },
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: lightGrey,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.videocam, color: Colors.grey.shade600),
                      const SizedBox(height: 8),
                      Text(
                        'Add Video',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildContactField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Contact Information',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 16,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contactNameController,
          decoration: InputDecoration(
            labelText: 'Your Name',
            prefixIcon: Icon(Icons.person),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _contactPhoneController,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(
            labelText: 'Phone Number',
            prefixIcon: Icon(Icons.phone),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isSubmitting ? null : _submitReport,
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryRed,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child:
            _isSubmitting
                ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text('Submitting...'),
                  ],
                )
                : Text('Submit Report'),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Cannot get your location. Please try again.')),
      );
      return;
    }

    if (selectedIncidentType == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Please select an incident type')));
      return;
    }

    setState(() {
      _isSubmitting = true;
      _currentStep = 2; // Move to final step
    });

    // Prepare report details with updated structure
    final Map<String, dynamic> details = {
      'description': _incidentDetailsController.text,
      'severity': fireAmount, // This will be mapped to the severity field
      'people_involved':
          peopleCount, // This will be mapped to the people_count field
      'reporter_type': 'SPECTATOR', // Explicitly set the reporter type
      'answers': {
        // Store detailed answers separately for description generation
        'Fire Size/Severity': fireAmount,
        'People Involved': peopleCount,
        'Additional Details': _incidentDetailsController.text,
      },
      'contact_info':
          'Name: ${_contactNameController.text}, Phone: ${_contactPhoneController.text}',
    };

    try {
      final success = await EmergencyReportService.submitIncidentReport(
        context: context,
        incidentType: selectedIncidentType!,
        details: details,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
        contactInfo:
            'Name: ${_contactNameController.text}, Phone: ${_contactPhoneController.text}',
      );

      setState(() {
        _isSubmitting = false;
      });

      if (success) {
        _showSuccessDialog();
      } else {
        _showErrorDialog();
      }
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          content: Container(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_circle,
                    color: Colors.green,
                    size: 48,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Report Submitted!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your incident report has been sent to emergency services. They will respond as soon as possible.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: darkBlue.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Incident Type: $selectedIncidentType',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: $_currentPosition',
                        style: TextStyle(
                          color: darkBlue.withOpacity(0.7),
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Status: PENDING',
                        style: TextStyle(
                          color: Colors.orange,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Reset form
                setState(() {
                  selectedIncidentType = null;
                  selectedFloor = null;
                  fireAmount = null;
                  peopleCount = null;
                  _currentStep = 0;
                  _incidentDetailsController.clear();
                  _contactNameController.clear();
                  _contactPhoneController.clear();
                });
              },
              child: Text(
                'New Report',
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
              ),
              child: Text('Done'),
            ),
          ],
        );
      },
    );
  }

  void _showErrorDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Error'),
          content: Text(
            'Failed to submit your report. Please try again later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildEmergencyNumbersSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Emergency Numbers',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _buildEmergencyNumberCard('Police', '999', Icons.local_police),
              const SizedBox(width: 12),
              _buildEmergencyNumberCard(
                'Fire',
                '000',
                Icons.local_fire_department,
              ),
              const SizedBox(width: 12),
              _buildEmergencyNumberCard(
                'Ambulance',
                '888',
                Icons.medical_services,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmergencyNumberCard(String title, String number, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Column(
          children: [
            Icon(icon, color: primaryRed),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
            ),
            Text(
              number,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: primaryRed,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Text(
      '© 2024 ResQ Emergency Services',
      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: 1,
      selectedItemColor: primaryRed,
      items: const [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(
          icon: Icon(Icons.report_problem),
          label: 'Report',
        ),
        BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
      ],
    );
  }
}

Widget _buildCopyright() {
  return Text(
    '© 2024 ResQ Emergency Services',
    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
    textAlign: TextAlign.center,
  );
}

Widget _buildBottomNavigationBar() {
  return BottomNavigationBar(
    currentIndex: 1,
    items: const [
      BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
      BottomNavigationBarItem(
        icon: Icon(Icons.report_problem),
        label: 'Report',
      ),
      BottomNavigationBarItem(icon: Icon(Icons.map), label: 'Map'),
      BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
    ],
  );
}
