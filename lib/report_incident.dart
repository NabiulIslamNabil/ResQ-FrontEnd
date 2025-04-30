import 'package:flutter/material.dart';
import 'chatbot.dart'; // Ensure this import is correct

class ReportIncidentPage extends StatefulWidget {
  const ReportIncidentPage({super.key});

  @override
  State<ReportIncidentPage> createState() => _ReportIncidentPageState();
}

class _ReportIncidentPageState extends State<ReportIncidentPage> {
  final Color redTheme = const Color(0xFFFF6B6B);

  String? selectedIncidentType;
  String? selectedFloor;
  String? fireAmount;
  String? peopleCount;

  final List<String> incidentTypes = [
    'Fire Incident',
    'Flood Incident',
    'Gas Leak',
    'Building Collapse',
    'Pet Rescue',
    'Others',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: redTheme,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showUnselectedLabels: true,
        currentIndex: 1,
        onTap: (index) {
          //if (index == 2) {
            //Navigator.push(
              //context,
              //MaterialPageRoute(builder: (context) => const ChatBotPage()),
            //);
          //}
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.report), label: "Report"),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: "Chatbot"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),

      body: SafeArea(
        child: Column(
          children: [
            // Red Top Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
              decoration: BoxDecoration(
                color: redTheme,
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(25),
                  bottomRight: Radius.circular(25),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          'Report an Incident',
                          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Help is a tap away,\nProvide the details below.',
                          style: TextStyle(fontSize: 16, color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.local_fire_department, color: Colors.white),
                ],
              ),
            ),

            // Form Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.my_location),
                      label: const Text("Load your Current Location"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: redTheme,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      ),
                    ),
                    const SizedBox(height: 25),

                    // Incident Type Dropdown
                    Text('Incident Type', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          hint: const Text("Tap to choose"),
                          value: selectedIncidentType,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          onChanged: (value) {
                            setState(() {
                              selectedIncidentType = value;
                              selectedFloor = null;
                              fireAmount = null;
                              peopleCount = null;
                            });
                          },
                          items: incidentTypes.map((type) {
                            return DropdownMenuItem<String>(
                              value: type,
                              child: Text(type),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),

                    if (selectedIncidentType == 'Fire Incident') ...[
                      _buildDropdown('Which floor?', ['1-5', '6-10', '>10'], selectedFloor, (value) {
                        setState(() => selectedFloor = value);
                      }),
                      const SizedBox(height: 15),
                      _buildDropdown('How much fire?', ['Less', 'Medium', 'High'], fireAmount, (value) {
                        setState(() => fireAmount = value);
                      }),
                      const SizedBox(height: 15),
                      _buildDropdown('People affected?', ['<4', '4-8', '>10'], peopleCount, (value) {
                        setState(() => peopleCount = value);
                      }),
                    ],
                    if (selectedIncidentType == 'Flood Incident') ...[
                      _buildDropdown('Water Level?', ['Low', 'Medium', 'High'], fireAmount, (value) {
                        setState(() => fireAmount = value);
                      }),
                      const SizedBox(height: 15),
                      _buildDropdown('People stranded?', ['<4', '4-8', '>10'], peopleCount, (value) {
                        setState(() => peopleCount = value);
                      }),
                    ],
                    if (selectedIncidentType == 'Gas Leak') ...[
                      _buildDropdown('Leak Source?', ['Kitchen', 'Pipe Line', 'Unknown'], fireAmount, (value) {
                        setState(() => fireAmount = value);
                      }),
                      const SizedBox(height: 15),
                      _buildDropdown('People nearby?', ['<4', '4-8', '>10'], peopleCount, (value) {
                        setState(() => peopleCount = value);
                      }),
                    ],
                    if (selectedIncidentType == 'Building Collapse') ...[
                      _buildDropdown('Severity?', ['Partial', 'Complete'], fireAmount, (value) {
                        setState(() => fireAmount = value);
                      }),
                      const SizedBox(height: 15),
                      _buildDropdown('Trapped people?', ['<4', '4-8', '>10'], peopleCount, (value) {
                        setState(() => peopleCount = value);
                      }),
                    ],
                    if (selectedIncidentType == 'Pet Rescue') ...[
                      _buildDropdown('Animal Type?', ['Cat', 'Dog', 'Bird', 'Other'], fireAmount, (value) {
                        setState(() => fireAmount = value);
                      }),
                    ],

                    const SizedBox(height: 15),
                    _buildInputField(Icons.location_on, 'Location', 'Current Location Detected'),
                    const SizedBox(height: 15),
                    _buildInputField(Icons.photo_camera_back_rounded, 'Upload Photo (Optional)', 'Tap to upload'),
                    const SizedBox(height: 15),
                    _buildInputField(Icons.phone, 'Contact Number (Optional)', 'Enter your contact number'),

                    const SizedBox(height: 30),
                    Center(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: redTheme,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 60),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                        ),
                        child: const Text('Submit', style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 25),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField(IconData icon, String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 6),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Colors.redAccent),
            filled: true,
            fillColor: Colors.grey[100],
            contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown(String label, List<String> options, String? selectedValue, ValueChanged<String> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(30),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              hint: const Text("Tap to choose"),
              value: selectedValue,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down),
              onChanged: (value) => onChanged(value!),
              items: options.map((option) {
                return DropdownMenuItem<String>(
                  value: option,
                  child: Text(option),
                );
              }).toList(),
            ),
          ),
        ),
      ],
    );
  }
}
