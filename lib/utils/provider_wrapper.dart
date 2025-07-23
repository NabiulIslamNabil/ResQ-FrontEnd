import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

/// A utility widget to wrap pages with the necessary providers
class ProviderWrapper extends StatelessWidget {
  final Widget child;

  const ProviderWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    // Get existing AuthProvider from parent
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    // Use ChangeNotifierProvider.value to maintain the same instance
    return ChangeNotifierProvider<AuthProvider>.value(
      value: authProvider,
      child: child,
    );
  }
}
