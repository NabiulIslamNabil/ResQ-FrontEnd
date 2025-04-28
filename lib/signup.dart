// signup.dart
import 'package:flutter/material.dart';

class RoleBasedSignUpPage extends StatefulWidget {
  const RoleBasedSignUpPage({super.key});

  @override
  State<RoleBasedSignUpPage> createState() => _RoleBasedSignUpPageState();
}

class _RoleBasedSignUpPageState extends State<RoleBasedSignUpPage> {
  String? selectedRole;
  bool showPassword = false;
  final _formKey = GlobalKey<FormState>();

  final Map<String, dynamic> formData = {};

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Sign Up'),
        backgroundColor: Colors.red,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: ListView(
          children: [
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                labelText: 'Select Role',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
              value: selectedRole,
              items: [
                'Civilian',
                'Fire Officer',
                'Police Officer',
                'Volunteer Head',
              ]
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(role),
                      ))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  selectedRole = value;
                  formData.clear(); // Reset form when role changes
                });
              },
            ),
            const SizedBox(height: 20),
            if (selectedRole != null) buildFormFields(selectedRole!),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                if (_formKey.currentState?.validate() ?? false) {
                  _formKey.currentState?.save();
                  // Submit the form
                  print(formData);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Sign up Successful!')),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Sign Up', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.g_mobiledata, color: Colors.red),
                  onPressed: () {
                    // Google sign up logic
                  },
                ),
                const SizedBox(width: 20),
                IconButton(
                  icon: const Icon(Icons.facebook, color: Colors.blue),
                  onPressed: () {
                    // Facebook sign up logic
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget buildFormFields(String role) {
    return Form(
      key: _formKey,
      child: Column(
        children: getFieldsForRole(role),
      ),
    );
  }

  List<Widget> getFieldsForRole(String role) {
    List<Widget> fields = [];

    switch (role) {
      case 'Civilian':
        fields = [
          buildTextField('Name'),
          buildTextField('Email'),
          buildTextField('Mobile No'),
          buildTextField('National ID no'),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
        break;
      case 'Fire Officer':
        fields = [
          buildTextField('Name of Officer in charge'),
          buildTextField('Fire Station Name'),
          buildUniqueIdField('Fire Station ID'),
          buildTextField('Fire Station Email'),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
        break;
      case 'Police Officer':
        fields = [
          buildTextField('Name of Officer in charge'),
          buildTextField('Police Station Name'),
          buildUniqueIdField('Police Station ID'),
          buildTextField('Police Station Email'),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
        break;
      case 'Volunteer Head':
        fields = [
          buildTextField('Name of Head in charge'),
          buildTextField('Volunteer Team Name'),
          buildUniqueIdField('Volunteer Team ID'),
          buildTextField('Volunteer Team Email'),
          buildPasswordField('Password'),
          buildPasswordField('Confirm Password'),
        ];
        break;
    }

    return fields;
  }

  Widget buildTextField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onSaved: (value) => formData[label] = value,
      ),
    );
  }

  Widget buildPasswordField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        obscureText: !showPassword,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          suffixIcon: IconButton(
            icon: Icon(showPassword ? Icons.visibility : Icons.visibility_off),
            onPressed: () {
              setState(() {
                showPassword = !showPassword;
              });
            },
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          return null;
        },
        onSaved: (value) => formData[label] = value,
      ),
    );
  }

  Widget buildUniqueIdField(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 15),
      child: TextFormField(
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Please enter $label';
          }
          // Here you can add your own Unique ID checking logic
          if (value == 'DUPLICATE_ID') {
            return '$label already exists!';
          }
          return null;
        },
        onSaved: (value) => formData[label] = value,
      ),
    );
  }
}
