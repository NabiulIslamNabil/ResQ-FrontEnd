import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'services/emergency_report_service.dart'; // Add this import
// Add this import for Provider
// Add this import for AuthProvider

class VictimReportPage extends StatefulWidget {
  const VictimReportPage({super.key});

  @override
  State<VictimReportPage> createState() => _VictimReportPageState();
}

class _VictimReportPageState extends State<VictimReportPage>
    with TickerProviderStateMixin {
  final Color primaryRed = const Color(0xFFE53935);
  final Color darkBlue = const Color(0xFF1A237E);
  final Color lightGrey = const Color(0xFFF8F9FA);
  final Color accentOrange = const Color(0xFFFF6F00);

  String? selectedIncident;
  Map<String, String?> selectedAnswers = {};
  bool showQuestions = false;
  bool isLocationFetched = false;
  String currentLocation = 'Fetching your current location...';
  TextEditingController floorController = TextEditingController();

  late AnimationController _pulseController;
  late AnimationController _fadeController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> incidents = [
    {
      'name': 'Fire',
      'icon': Icons.local_fire_department,
      'color': Colors.redAccent,
    },
    {'name': 'Flood', 'icon': Icons.waves, 'color': Colors.blueAccent},
    {
      'name': 'Collapse',
      'icon': Icons.domain_disabled,
      'color': Colors.orangeAccent,
    },
    {'name': 'Other', 'icon': Icons.warning, 'color': Colors.purpleAccent},
  ];

  final Map<String, List<String>> questions = {
    'Fire': [
      'Is the fire spreading rapidly?',
      'Are people trapped inside?',
      'Is smoke blocking exits?',
      'Which floor is affected?',
    ],
    'Flood': [
      'Is the water level rising?',
      'Are people stranded on rooftops?',
      'Is electricity still on in the area?',
      'Are roads completely blocked?',
    ],
    'Collapse': [
      'Is the building completely collapsed?',
      'Are people trapped under debris?',
      'Can you hear voices from inside?',
      'Are there visible injuries?',
    ],
    'Other': [
      'Is this life-threatening?',
      'Are you in immediate danger?',
      'Do you need medical assistance?',
      'Are others involved?',
    ],
  };

  final List<String> answerOptions = ['Yes', 'No', 'Don\'t Know'];
  final List<String> floorOptions = [
    'Ground Floor',
    '1st Floor',
    '2nd Floor',
    '3rd Floor',
    '4th Floor',
    '5th Floor',
    'Higher Floor',
    'Don\'t Know',
  ];

  Position?
  _currentPosition; // Add this to store the position for sending to backend
  bool _isSendingSOS = false; // Add this to track SOS sending state

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _fetchLocation();
  }

  void _initializeAnimations() {
    _pulseController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
  }

  void _fetchLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        currentLocation = 'Location services are disabled.';
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        setState(() {
          currentLocation = 'Location permissions are denied';
        });
        return;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      setState(() {
        currentLocation = 'Location permissions are permanently denied';
      });
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      isLocationFetched = true;
      _currentPosition = position; // Store the position for API call
      currentLocation =
          '${position.latitude.toStringAsFixed(6)}, ${position.longitude.toStringAsFixed(6)}';
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _fadeController.dispose();
    floorController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildSimpleAppBar(),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              _buildLocationCard(),
              const SizedBox(height: 30),
              // Emergency SOS Section moved to top
              Center(child: _buildSOSSection()),
              const SizedBox(height: 30),
              _buildOrDivider(),
              const SizedBox(height: 25),
              // Incident selector moved below SOS
              _buildIncidentSelector(),
              const SizedBox(height: 25),
              if (showQuestions && selectedIncident != null)
                _buildIncidentQuestions(selectedIncident!),
              if (showQuestions) const SizedBox(height: 25),
              if (showQuestions) _buildSubmitButton(),
              const SizedBox(height: 30),
              _buildCopyright(),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildSimpleAppBar() {
    return AppBar(
      backgroundColor: primaryRed,
      elevation: 2,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.local_fire_department,
              color: primaryRed,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'ResQ',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Emergency Response',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        Container(
          margin: const EdgeInsets.only(right: 8),
          child: IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildLocationCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [lightGrey, Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryRed.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isLocationFetched ? Icons.location_on : Icons.location_searching,
              color: primaryRed,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your Location',
                  style: TextStyle(
                    color: darkBlue.withOpacity(0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  currentLocation,
                  style: TextStyle(
                    color: darkBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (isLocationFetched)
            Icon(Icons.check_circle, color: Colors.green, size: 20),
        ],
      ),
    );
  }

  Widget _buildSOSSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryRed.withOpacity(0.1), Colors.white],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: primaryRed.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            'Emergency SOS',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: darkBlue,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap for immediate emergency response\nwhen you don\'t have time for details',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: darkBlue.withOpacity(0.7)),
          ),
          const SizedBox(height: 24),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: GestureDetector(
                  onTap:
                      _isSendingSOS ? null : _sendSOS, // Disable while sending
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        colors: [primaryRed, primaryRed.withOpacity(0.8)],
                        stops: [0.6, 1.0],
                      ),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryRed.withOpacity(0.4),
                          blurRadius: 20,
                          spreadRadius: 8,
                        ),
                      ],
                    ),
                    child: Center(
                      child:
                          _isSendingSOS
                              ? CircularProgressIndicator(
                                color: Colors.white,
                              ) // Show loading indicator
                              : const Text(
                                'SOS',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 2,
                                ),
                              ),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrDivider() {
    return Row(
      children: [
        Expanded(
          child: Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'OR',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: darkBlue.withOpacity(0.7),
            ),
          ),
        ),
        Expanded(
          child: Divider(color: Colors.grey.withOpacity(0.4), thickness: 1),
        ),
      ],
    );
  }

  Widget _buildIncidentSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Incident Type',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: darkBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Choose the type of emergency you\'re reporting',
          style: TextStyle(fontSize: 14, color: darkBlue.withOpacity(0.6)),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 1.2,
          ),
          itemCount: incidents.length,
          itemBuilder: (context, index) {
            final incident = incidents[index];
            final bool isSelected = selectedIncident == incident['name'];

            return GestureDetector(
              onTap: () {
                setState(() {
                  selectedIncident = incident['name'];
                  showQuestions = true;
                  selectedAnswers.clear();
                });
                _fadeController.forward();
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient:
                      isSelected
                          ? LinearGradient(
                            colors: [primaryRed, primaryRed.withOpacity(0.8)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )
                          : LinearGradient(
                            colors: [Colors.white, lightGrey],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color:
                        isSelected ? primaryRed : Colors.grey.withOpacity(0.2),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color:
                          isSelected
                              ? primaryRed.withOpacity(0.3)
                              : Colors.grey.withOpacity(0.1),
                      blurRadius: isSelected ? 12 : 6,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color:
                            isSelected
                                ? Colors.white.withOpacity(0.2)
                                : incident['color'].withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        incident['icon'],
                        size: 32,
                        color: isSelected ? Colors.white : incident['color'],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      incident['name'],
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isSelected ? Colors.white : darkBlue,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildIncidentQuestions(String incidentType) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: primaryRed.withOpacity(0.2)),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: primaryRed.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.quiz, color: primaryRed, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Assessment',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Please answer these questions to help us respond better',
              style: TextStyle(fontSize: 14, color: darkBlue.withOpacity(0.6)),
            ),
            const SizedBox(height: 20),
            ...questions[incidentType]!.asMap().entries.map((entry) {
              int index = entry.key;
              String question = entry.value;

              return Container(
                margin: const EdgeInsets.only(bottom: 20),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: lightGrey.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${index + 1}. $question',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: darkBlue,
                      ),
                    ),
                    const SizedBox(height: 12),
                    question == 'Which floor is affected?'
                        ? Column(
                          children: [
                            Row(
                              children: [
                                // Quick options for common floors
                                ...['G', '1', '2', '3', '4', '5'].map((floor) {
                                  bool isSelected =
                                      selectedAnswers[question] ==
                                      '${floor == 'G' ? 'Ground' : floor} Floor';
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.only(right: 6),
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedAnswers[question] =
                                                floor == 'G'
                                                    ? 'Ground Floor'
                                                    : '$floor Floor';
                                            floorController.clear();
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 10,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? primaryRed
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? primaryRed
                                                      : Colors.grey.withOpacity(
                                                        0.3,
                                                      ),
                                            ),
                                          ),
                                          child: Text(
                                            floor,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : darkBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                }),
                              ],
                            ),
                            const SizedBox(height: 12),
                            // Custom floor input
                            Row(
                              children: [
                                Expanded(
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: TextField(
                                      controller: floorController,
                                      keyboardType: TextInputType.number,
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: darkBlue,
                                      ),
                                      decoration: InputDecoration(
                                        hintText: 'Enter floor #',
                                        hintStyle: TextStyle(
                                          color: Colors.grey,
                                          fontSize: 12,
                                        ),
                                        border: InputBorder.none,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 12,
                                            ),
                                      ),
                                      onChanged: (value) {
                                        if (value.isNotEmpty) {
                                          setState(() {
                                            selectedAnswers[question] =
                                                'Floor $value';
                                          });
                                        } else {
                                          setState(() {
                                            selectedAnswers.remove(question);
                                          });
                                        }
                                      },
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      selectedAnswers[question] = 'Basement';
                                      floorController.clear();
                                    });
                                  },
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 200),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 12,
                                    ),
                                    decoration: BoxDecoration(
                                      color:
                                          selectedAnswers[question] ==
                                                  'Basement'
                                              ? primaryRed
                                              : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color:
                                            selectedAnswers[question] ==
                                                    'Basement'
                                                ? primaryRed
                                                : Colors.grey.withOpacity(0.3),
                                      ),
                                    ),
                                    child: Text(
                                      'Basement',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color:
                                            selectedAnswers[question] ==
                                                    'Basement'
                                                ? Colors.white
                                                : darkBlue,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        )
                        : Row(
                          children:
                              answerOptions.map((answer) {
                                bool isSelected =
                                    selectedAnswers[question] == answer;
                                Color answerColor =
                                    answer == 'Yes'
                                        ? Colors.red
                                        : answer == 'No'
                                        ? Colors.green
                                        : Colors.orange;

                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: GestureDetector(
                                      onTap: () {
                                        setState(() {
                                          selectedAnswers[question] = answer;
                                        });
                                      },
                                      child: GestureDetector(
                                        onTap: () {
                                          setState(() {
                                            selectedAnswers[question] = answer;
                                          });
                                        },
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            vertical: 12,
                                            horizontal: 16,
                                          ),
                                          decoration: BoxDecoration(
                                            color:
                                                isSelected
                                                    ? answerColor
                                                    : Colors.white,
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color:
                                                  isSelected
                                                      ? answerColor
                                                      : Colors.grey.withOpacity(
                                                        0.3,
                                                      ),
                                            ),
                                          ),
                                          child: Text(
                                            answer,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              fontSize: 13,
                                              fontWeight: FontWeight.w600,
                                              color:
                                                  isSelected
                                                      ? Colors.white
                                                      : darkBlue,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                        ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSubmitButton() {
    bool allQuestionsAnswered = questions[selectedIncident]!.every(
      (question) => selectedAnswers.containsKey(question),
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: allQuestionsAnswered ? _submitReport : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: allQuestionsAnswered ? primaryRed : Colors.grey,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: allQuestionsAnswered ? 8 : 2,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.send, size: 20),
            const SizedBox(width: 8),
            Text(
              'Submit Emergency Report',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCopyright() {
    return Center(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: lightGrey.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              '© 2024 ResQ Emergency Response',
              style: TextStyle(
                fontSize: 12,
                color: darkBlue.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Powered by ReBuggers 101',
              style: TextStyle(fontSize: 10, color: darkBlue.withOpacity(0.4)),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _sendSOS to actually send data to backend
  Future<void> _sendSOS() async {
    // Check if we have location
    if (!isLocationFetched || _currentPosition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cannot get your location. Please try again.'),
        ),
      );
      return;
    }

    setState(() {
      _isSendingSOS = true;
    });

    try {
      // Create emergency details
      Map<String, dynamic> emergencyDetails = {
        'description':
            'URGENT VICTIM SOS: Immediate assistance required! Victim in imminent danger.',
        'reporter_type': 'VICTIM', // Explicitly mark as victim
        'is_emergency': true,
        'priority': 'CRITICAL',
      };

      // Send to backend API
      final success = await EmergencyReportService.submitEmergencyReport(
        context: context,
        incidentType: 'Emergency SOS',
        details: emergencyDetails,
        latitude: _currentPosition!.latitude,
        longitude: _currentPosition!.longitude,
      );

      if (success) {
        _showSOSSuccessDialog();
      } else {
        _showSOSErrorDialog(
          'Failed to send emergency alert. Please try again.',
        );
      }
    } catch (e) {
      print('Error sending SOS: $e');
      _showSOSErrorDialog(
        'An error occurred while sending your emergency alert.',
      );
    } finally {
      setState(() {
        _isSendingSOS = false;
      });
    }
  }

  void _showSOSSuccessDialog() {
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
                  'SOS Alert Sent!',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: darkBlue,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Emergency services have been notified of your location. Help is on the way.',
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
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.priority_high, color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'Priority: CRITICAL',
                        style: TextStyle(
                          color: Colors.green,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
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
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'OK',
                style: TextStyle(
                  color: primaryRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showSOSErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _submitReport() {
    // Replace with actual API call when implementing form submission
    // Similar to _sendSOS but with detailed form data
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
                  'Your detailed emergency report has been sent to the appropriate response team.',
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
                        'Incident Type: $selectedIncident',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: darkBlue,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Location: $currentLocation',
                        style: TextStyle(
                          color: darkBlue.withOpacity(0.7),
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
                setState(() {
                  selectedIncident = null;
                  selectedAnswers.clear();
                  showQuestions = false;
                  floorController.clear();
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
}
