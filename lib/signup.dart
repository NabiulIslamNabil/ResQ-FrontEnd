import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class RoleBasedSignUpPage extends StatefulWidget {
  const RoleBasedSignUpPage({super.key});

  @override
  State<RoleBasedSignUpPage> createState() => _RoleBasedSignUpPageState();
}

class _RoleBasedSignUpPageState extends State<RoleBasedSignUpPage>
    with SingleTickerProviderStateMixin {
  String? selectedRole;
  bool showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> formData = {};
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  final List<Map<String, dynamic>> roles = [
    {'label': 'Civilian', 'icon': Icons.person},
    {'label': 'Fire Officer', 'icon': Icons.local_fire_department},
    {'label': 'Police Officer', 'icon': Icons.local_police},
    {'label': 'Volunteer Head', 'icon': Icons.volunteer_activism},
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void showRoleSelector() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return ListView(
          shrinkWrap: true,
          children: roles
              .map((role) => ListTile(
                    leading: Icon(role['icon'], color: Colors.redAccent),
                    title: Text(role['label']),
                    onTap: () {
                      setState(() {
                        selectedRole = role['label'];
                        formData.clear();
                      });
                      Navigator.pop(context);
                    },
                  ))
              .toList(),
        );
      },
    );
  }

  void handleSocialSignUp(String provider) {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a role before signing up.'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }
    print('Signing up with $provider as $selectedRole');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          Container(
            height: 120,
            width: double.infinity,
            color: Colors.redAccent,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SafeArea(
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Create Account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
                children: [
                  buildSocialButtons(),
                  const SizedBox(height: 25),
                  buildRolePicker(),
                  const SizedBox(height: 25),
                  if (selectedRole != null)
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: buildFormFields(selectedRole!),
                      ),
                    ),
                  const SizedBox(height: 30),
                  buildSubmitButton(),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget buildSocialButtons() {
    return Center(
      child: Column(
        children: [
          const Text("— SIGN UP WITH —", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              buildSocialIcon(Icons.g_mobiledata, Colors.red, "Google"),
              const SizedBox(width: 20),
              buildSocialIcon(Icons.facebook, Colors.blue, "Facebook"),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildSocialIcon(IconData icon, Color color, String provider) {
    return GestureDetector(
      onTap: () => handleSocialSignUp(provider),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))],
        ),
        child: Icon(icon, size: 30, color: color),
      ),
    );
  }

  Widget buildRolePicker() {
    return GestureDetector(
      onTap: showRoleSelector,
      child: Material(
        elevation: 3,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(30),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                selectedRole ?? 'Select Role',
                style: TextStyle(
                  fontSize: 16,
                  color: selectedRole != null ? Colors.black87 : Colors.grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Icon(Icons.keyboard_arrow_down_rounded),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildSubmitButton() {
    return ElevatedButton.icon(
      onPressed: () {
        if (_formKey.currentState?.validate() ?? false) {
          _formKey.currentState?.save();
          print(formData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Sign up Successful!')),
          );
        }
      },
      icon: const Icon(Icons.check_circle_outline),
      label: const Text('Complete Sign Up'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.redAccent,
        padding: const EdgeInsets.symmetric(vertical: 16),
        textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
    );
  }

  Widget buildFormFields(String role) {
    return Form(
      key: _formKey,
      child: Column(children: getFieldsForRole(role)),
    );
  }

  List<Widget> getFieldsForRole(String role) {
    switch (role) {
      case 'Civilian':
        return [
          buildTextField('Name', Icons.person),
          buildTextField('Email', Icons.email),
          buildTextField('Mobile No', Icons.phone),
          buildTextField('National ID no', Icons.badge),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
      case 'Fire Officer':
        return [
          buildTextField('Name of Officer in charge', Icons.person),
          buildTextField('Fire Station Name', Icons.fire_extinguisher),
          buildTextField('Fire Station Email', Icons.email),
          buildUniqueIdField('Fire Station ID', Icons.verified),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
      case 'Police Officer':
        return [
          buildTextField('Name of Officer in charge', Icons.person),
          buildTextField('Police Station Name', Icons.local_police),
          buildTextField('Police Station Email', Icons.email),
          buildUniqueIdField('Police Station ID', Icons.verified),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
      case 'Volunteer Head':
        return [
          buildTextField('Name of Head in charge', Icons.person),
          buildTextField('Volunteer Team Name', Icons.groups),
          buildTextField('Volunteer Team Email', Icons.email),
          buildUniqueIdField('Volunteer Team ID', Icons.verified),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
      default:
        return [];
    }
  }

  Widget buildTextField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(30),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.redAccent),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
          onSaved: (value) => formData[label] = value,
        ),
      ),
    );
  }

  Widget buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(30),
        child: TextFormField(
          obscureText: !showPassword,
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: const Icon(Icons.lock_outline, color: Colors.redAccent),
            suffixIcon: IconButton(
              icon: Icon(
                showPassword ? Icons.visibility : Icons.visibility_off,
                color: Colors.redAccent,
              ),
              onPressed: () => setState(() => showPassword = !showPassword),
            ),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
          onSaved: (value) => formData[label] = value,
        ),
      ),
    );
  }

  Widget buildUniqueIdField(String label, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: Material(
        elevation: 2,
        borderRadius: BorderRadius.circular(30),
        child: TextFormField(
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: Icon(icon, color: Colors.redAccent),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Please enter $label';
            if (value == 'DUPLICATE_ID') return '$label already exists!';
            return null;
          },
          onSaved: (value) => formData[label] = value,
        ),
      ),
    );
  }
}
