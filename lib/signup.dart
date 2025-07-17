import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'HomePage.dart';
import 'login.dart';
import 'providers/auth_provider.dart';
import 'widgets/connection_error_widget.dart';
import 'utils/provider_wrapper.dart';

class RoleBasedSignUpPage extends StatefulWidget {
  const RoleBasedSignUpPage({super.key});

  @override
  State<RoleBasedSignUpPage> createState() => _RoleBasedSignUpPageState();
}

// Create a widget that wraps the signup page with the required provider
class RoleBasedSignUpPageWrapper extends StatelessWidget {
  const RoleBasedSignUpPageWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Use our utility wrapper to ensure the provider is available
    return ProviderWrapper(child: const RoleBasedSignUpPage());
  }
}

class _RoleBasedSignUpPageState extends State<RoleBasedSignUpPage>
    with SingleTickerProviderStateMixin {
  String? selectedRole;
  bool showPassword = false;
  final _formKey = GlobalKey<FormState>();
  final Map<String, dynamic> formData = {};
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  bool _isLoading = false;
  String? _errorMessage;

  // Text controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _idController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _stationNameController = TextEditingController();
  final TextEditingController _teamNameController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();

  final List<Map<String, dynamic>> roles = [
    {
      'label': 'Civilian',
      'icon': Icons.person_outline_rounded,
      'apiRole': 'CITIZEN',
    },
    {
      'label': 'Fire Officer',
      'icon': Icons.local_fire_department_outlined,
      'apiRole': 'FIRE_STATION',
    },
    {
      'label': 'Police Officer',
      'icon': Icons.local_police_outlined,
      'apiRole': 'POLICE',
    },
    {
      'label': 'Volunteer Head',
      'icon': Icons.volunteer_activism_outlined,
      'apiRole': 'RED_CRESCENT',
    },
  ];

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _idController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _usernameController.dispose();
    _stationNameController.dispose();
    _teamNameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  // Get API role from selected role
  String _getApiRole() {
    if (selectedRole == null) return 'CITIZEN';

    final roleMap = roles.firstWhere(
      (role) => role['label'] == selectedRole,
      orElse: () => {'apiRole': 'CITIZEN'},
    );

    return roleMap['apiRole'];
  }

  // Handle registration submission
  Future<void> _handleSignUp() async {
    if (_formKey.currentState?.validate() ?? false) {
      _formKey.currentState?.save();

      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        final authProvider = Provider.of<AuthProvider>(context, listen: false);

        // Split full name into first and last name
        final nameParts = _nameController.text.split(' ');
        final firstName = nameParts.first;
        final lastName =
            nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

        // Use mock location data for now - in a real app you'd get actual coordinates
        const double latitude = 23.810331;
        const double longitude = 90.412521;
        final String address =
            _addressController.text.isNotEmpty
                ? _addressController.text
                : "Default Address";

        final success = await authProvider.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          firstName: firstName,
          lastName: lastName,
          phoneNumber: _phoneController.text,
          role: _getApiRole(),
          latitude: latitude,
          longitude: longitude,
          address: address,
        );

        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Sign up Successful! Please login to continue.',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: const Color(0xFFE53935),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.all(16),
            ),
          );

          // Navigate to LoginPage after successful sign up
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const LoginPageWrapper()),
          );
        } else if (authProvider.status == AuthStatus.connectionError) {
          // Show connection error dialog
          _showConnectionErrorDialog(
            context,
            authProvider.errorMessage ?? "Connection error",
          );
        } else {
          setState(() {
            _errorMessage = authProvider.errorMessage;
          });
        }
      } catch (e) {
        setState(() {
          _errorMessage = e.toString();
        });
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _showConnectionErrorDialog(BuildContext context, String errorMessage) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            contentPadding: EdgeInsets.zero,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ConnectionErrorWidget(
                errorMessage: errorMessage,
                onRetry: () {
                  Navigator.pop(context);
                  final authProvider = Provider.of<AuthProvider>(
                    context,
                    listen: false,
                  );
                  authProvider.retryConnection();
                },
              ),
            ),
          ),
    );
  }

  void showRoleSelector() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Color(0xFF9E9E9E)),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              const Divider(height: 1, color: Color(0xFFE0E0E0)),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  children:
                      roles.map((role) {
                        return ListTile(
                          leading: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              role['icon'],
                              color: const Color(0xFFE53935),
                            ),
                          ),
                          title: Text(
                            role['label'],
                            style: const TextStyle(
                              fontWeight: FontWeight.w500,
                              color: Color(0xFF212121),
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Color(0xFF9E9E9E),
                            size: 16,
                          ),
                          onTap: () {
                            setState(() {
                              selectedRole = role['label'];
                            });
                            Navigator.pop(context);
                          },
                        );
                      }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void handleSocialSignUp(String provider) {
    if (selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please select a role before signing up.'),
          backgroundColor: const Color(0xFFE53935),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          margin: const EdgeInsets.all(16),
        ),
      );
      return;
    }
    print('Signing up with $provider as $selectedRole');
    // Navigate to HomePage after social sign up
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const HomePageWrapper()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF212121)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed:
              () => Navigator.canPop(context) ? Navigator.pop(context) : null,
        ),
        centerTitle: true,
        title: const Text(
          'Create Account',
          style: TextStyle(
            color: Color(0xFF212121),
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Container(
            color: Colors.white,
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                // Logo with Fire and blinking animation
                Center(child: PulsingLogoWidget()),
                const SizedBox(height: 16),
                const Center(
                  child: Text(
                    "Join ResQ",
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Center(
                  child: Text(
                    "Create an account to access emergency services",
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    "tailored to your role",
                    style: TextStyle(fontSize: 14, color: Color(0xFF757575)),
                  ),
                ),
                const SizedBox(height: 40),

                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.red.shade200),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                buildRolePicker(),
                const SizedBox(height: 24),

                if (selectedRole != null) buildFormFields(selectedRole!),

                const SizedBox(height: 24),

                _isLoading
                    ? const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFFE53935),
                      ),
                    )
                    : buildSubmitButton(),

                const SizedBox(height: 32),

                buildSocialButtons(),
                const SizedBox(height: 24),

                // Sign in link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Already have an account?",
                        style: TextStyle(color: Color(0xFF757575)),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const LoginPageWrapper(),
                            ),
                          );
                        },
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFE53935),
                          minimumSize: Size.zero,
                          padding: const EdgeInsets.only(left: 8),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text("Sign In"),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget buildSocialButtons() {
    return Column(
      children: [
        const Row(
          children: [
            Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 15),
              child: Text(
                "OR SIGN UP WITH",
                style: TextStyle(
                  color: Color(0xFF9E9E9E),
                  fontSize: 12,
                  letterSpacing: 1,
                ),
              ),
            ),
            Expanded(child: Divider(thickness: 1, color: Color(0xFFE0E0E0))),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            buildSocialIcon(
              Icons.g_mobiledata,
              const Color(0xFFDB4437),
              "Google",
            ),
            const SizedBox(width: 24),
            buildSocialIcon(
              Icons.facebook,
              const Color(0xFF4267B2),
              "Facebook",
            ),
            const SizedBox(width: 24),
            buildSocialIcon(Icons.apple, const Color(0xFF333333), "Apple"),
          ],
        ),
      ],
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
          border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
        ),
        child: Icon(icon, size: 28, color: color),
      ),
    );
  }

  Widget buildRolePicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            "I am a",
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Color(0xFF212121),
              fontSize: 16,
            ),
          ),
        ),
        GestureDetector(
          onTap: showRoleSelector,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0), width: 1),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    if (selectedRole != null)
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF5F5F5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          roles.firstWhere(
                            (role) => role['label'] == selectedRole,
                            orElse:
                                () => {'icon': Icons.person_outline_rounded},
                          )['icon'],
                          color: const Color(0xFFE53935),
                          size: 20,
                        ),
                      ),
                    const SizedBox(width: 12),
                    Text(
                      selectedRole ?? "Select your role",
                      style: TextStyle(
                        color:
                            selectedRole != null
                                ? const Color(0xFF212121)
                                : const Color(0xFF9E9E9E),
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: const Color(0xFF9E9E9E),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget buildSubmitButton() {
    return ElevatedButton(
      onPressed: _handleSignUp,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        minimumSize: const Size(double.infinity, 56),
      ),
      child: const Text(
        'Create Account',
        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget buildFormFields(String role) {
    return Form(key: _formKey, child: Column(children: getFieldsForRole(role)));
  }

  List<Widget> getFieldsForRole(String role) {
    switch (role) {
      case 'Civilian':
        return [
          buildTextField(
            'Full Name',
            Icons.person_outline_rounded,
            controller: _nameController,
            hint: 'Enter your full name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (!value.contains(' ')) {
                return 'Please enter both first and last name';
              }
              return null;
            },
          ),
          buildTextField(
            'Username',
            Icons.account_circle_outlined,
            controller: _usernameController,
            hint: 'Choose a unique username',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.contains(' ')) {
                return 'Username cannot contain spaces';
              }
              return null;
            },
          ),
          buildTextField(
            'Email Address',
            Icons.email_outlined,
            controller: _emailController,
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter an email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          buildTextField(
            'Phone Number',
            Icons.phone_outlined,
            controller: _phoneController,
            hint: '+880 1X XXXX XXXX',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your phone number';
              }
              return null;
            },
          ),
          buildTextField(
            'Home Address',
            Icons.home_outlined,
            controller: _addressController,
            hint: 'Enter your full address',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your address';
              }
              return null;
            },
          ),
          buildTextField(
            'National ID',
            Icons.badge_outlined,
            controller: _idController,
            hint: 'Enter your National ID number',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your National ID';
              }
              return null;
            },
          ),
          buildPasswordField(
            'Password',
            controller: _passwordController,
            hint: 'Create a strong password',
          ),
          buildPasswordField(
            'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ];
      case 'Fire Officer':
        return [
          buildTextField(
            'Officer Name',
            Icons.person_outline_rounded,
            controller: _nameController,
            hint: 'Enter your full name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (!value.contains(' ')) {
                return 'Please enter both first and last name';
              }
              return null;
            },
          ),
          buildTextField(
            'Username',
            Icons.account_circle_outlined,
            controller: _usernameController,
            hint: 'Choose a unique username',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.contains(' ')) {
                return 'Username cannot contain spaces';
              }
              return null;
            },
          ),
          buildTextField(
            'Fire Station Name',
            Icons.local_fire_department_outlined,
            controller: _stationNameController,
            hint: 'Enter your fire station name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter fire station name';
              }
              return null;
            },
          ),
          buildTextField(
            'Station Email',
            Icons.email_outlined,
            controller: _emailController,
            hint: 'station@firedept.gov.bd',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter station email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          buildTextField(
            'Phone Number',
            Icons.phone_outlined,
            controller: _phoneController,
            hint: '+880 1X XXXX XXXX',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter station phone number';
              }
              return null;
            },
          ),
          buildTextField(
            'Station Address',
            Icons.location_on_outlined,
            controller: _addressController,
            hint: 'Enter station address',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter station address';
              }
              return null;
            },
          ),
          buildUniqueIdField(
            'Station ID',
            Icons.verified_outlined,
            controller: _idController,
            hint: 'Enter official station ID',
          ),
          buildPasswordField(
            'Password',
            controller: _passwordController,
            hint: 'Create a strong password',
          ),
          buildPasswordField(
            'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ];
      case 'Police Officer':
        return [
          buildTextField(
            'Officer Name',
            Icons.person_outline_rounded,
            controller: _nameController,
            hint: 'Enter your full name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (!value.contains(' ')) {
                return 'Please enter both first and last name';
              }
              return null;
            },
          ),
          buildTextField(
            'Username',
            Icons.account_circle_outlined,
            controller: _usernameController,
            hint: 'Choose a unique username',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.contains(' ')) {
                return 'Username cannot contain spaces';
              }
              return null;
            },
          ),
          buildTextField(
            'Police Station Name',
            Icons.local_police_outlined,
            controller: _stationNameController,
            hint: 'Enter your police station name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter police station name';
              }
              return null;
            },
          ),
          buildTextField(
            'Station Email',
            Icons.email_outlined,
            controller: _emailController,
            hint: 'station@police.gov.bd',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter station email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          buildTextField(
            'Phone Number',
            Icons.phone_outlined,
            controller: _phoneController,
            hint: '+880 1X XXXX XXXX',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter station phone number';
              }
              return null;
            },
          ),
          buildTextField(
            'Station Address',
            Icons.location_on_outlined,
            controller: _addressController,
            hint: 'Enter station address',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter station address';
              }
              return null;
            },
          ),
          buildUniqueIdField(
            'Station ID',
            Icons.verified_outlined,
            controller: _idController,
            hint: 'Enter official police station ID',
          ),
          buildPasswordField(
            'Password',
            controller: _passwordController,
            hint: 'Create a strong password',
          ),
          buildPasswordField(
            'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ];
      case 'Volunteer Head':
        return [
          buildTextField(
            'Head Name',
            Icons.person_outline_rounded,
            controller: _nameController,
            hint: 'Enter your full name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter your full name';
              }
              if (!value.contains(' ')) {
                return 'Please enter both first and last name';
              }
              return null;
            },
          ),
          buildTextField(
            'Username',
            Icons.account_circle_outlined,
            controller: _usernameController,
            hint: 'Choose a unique username',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter a username';
              }
              if (value.contains(' ')) {
                return 'Username cannot contain spaces';
              }
              return null;
            },
          ),
          buildTextField(
            'Team Name',
            Icons.groups_outlined,
            controller: _teamNameController,
            hint: 'Enter your volunteer team name',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter team name';
              }
              return null;
            },
          ),
          buildTextField(
            'Team Email',
            Icons.email_outlined,
            controller: _emailController,
            hint: 'team@volunteers.org',
            keyboardType: TextInputType.emailAddress,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter team email address';
              }
              if (!RegExp(
                r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
              ).hasMatch(value)) {
                return 'Please enter a valid email address';
              }
              return null;
            },
          ),
          buildTextField(
            'Phone Number',
            Icons.phone_outlined,
            controller: _phoneController,
            hint: '+880 1X XXXX XXXX',
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter team phone number';
              }
              return null;
            },
          ),
          buildTextField(
            'Team Address',
            Icons.location_on_outlined,
            controller: _addressController,
            hint: 'Enter team headquarters address',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please enter team address';
              }
              return null;
            },
          ),
          buildUniqueIdField(
            'Team ID',
            Icons.verified_outlined,
            controller: _idController,
            hint: 'Enter official volunteer team ID',
          ),
          buildPasswordField(
            'Password',
            controller: _passwordController,
            hint: 'Create a strong password',
          ),
          buildPasswordField(
            'Confirm Password',
            controller: _confirmPasswordController,
            hint: 'Re-enter your password',
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Please confirm your password';
              }
              if (value != _passwordController.text) {
                return 'Passwords do not match';
              }
              return null;
            },
          ),
        ];
      default:
        return [];
    }
  }

  Widget buildTextField(
    String label,
    IconData icon, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator:
            validator ??
            (value) =>
                value == null || value.isEmpty ? 'Please enter $label' : null,
        onSaved: (value) => formData[label] = value,
      ),
    );
  }

  Widget buildPasswordField(
    String label, {
    TextEditingController? controller,
    String? Function(String?)? validator,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        obscureText: !showPassword,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: const Icon(
            Icons.lock_outline_rounded,
            color: Color(0xFF9E9E9E),
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              showPassword
                  ? Icons.visibility_outlined
                  : Icons.visibility_off_outlined,
              color: const Color(0xFF9E9E9E),
              size: 20,
            ),
            onPressed: () => setState(() => showPassword = !showPassword),
          ),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator:
            validator ??
            (value) {
              if (value == null || value.isEmpty) return 'Please enter $label';
              return null; // Removed password length restriction
            },
        onSaved: (value) => formData[label] = value,
      ),
    );
  }

  Widget buildUniqueIdField(
    String label,
    IconData icon, {
    TextEditingController? controller,
    String? hint,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: const TextStyle(color: Color(0xFF757575), fontSize: 14),
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
          prefixIcon: Icon(icon, color: const Color(0xFF9E9E9E), size: 20),
          filled: true,
          fillColor: const Color(0xFFFAFAFA),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE53935), width: 1),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFE74C3C), width: 1),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 16,
            horizontal: 16,
          ),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return 'Please enter $label';
          if (value == 'DUPLICATE_ID') return '$label already exists!';
          return null;
        },
        onSaved: (value) => formData[label] = value,
      ),
    );
  }
}

// PulsingLogoWidget Implementation
class PulsingLogoWidget extends StatefulWidget {
  const PulsingLogoWidget({super.key});

  @override
  State<PulsingLogoWidget> createState() => _PulsingLogoWidgetState();
}

class _PulsingLogoWidgetState extends State<PulsingLogoWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFFFEBEE),
            boxShadow: [
              BoxShadow(
                color: const Color(
                  0xFFE53935,
                ).withOpacity(0.3 * _pulseAnimation.value),
                blurRadius: 12 * _pulseAnimation.value,
                spreadRadius: 2 * _pulseAnimation.value,
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 40 * _pulseAnimation.value,
              color: const Color(0xFFE53935),
            ),
          ),
        );
      },
    );
  }
}
