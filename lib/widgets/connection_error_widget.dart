import 'package:flutter/material.dart';

class ConnectionErrorWidget extends StatelessWidget {
  final VoidCallback onRetry;
  final String? errorMessage;
  final String title;
  final List<String> troubleshootingTips;

  const ConnectionErrorWidget({
    super.key,
    required this.onRetry,
    this.errorMessage,
    this.title = 'Connection Error',
    this.troubleshootingTips = const [
      'Check your internet connection',
      'Ensure the API server is running',
      'Verify the server address and port',
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Error icon with animation
            _buildErrorIcon(),
            const SizedBox(height: 24),

            // Error title
            Text(
              title,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF212121),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),

            // Error message
            if (errorMessage != null) _buildErrorMessageContainer(),
            const SizedBox(height: 24),

            // Troubleshooting tips
            _buildTroubleshootingTips(),
            const SizedBox(height: 32),

            // Retry button
            _buildRetryButton(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorIcon() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.wifi_off_rounded, color: Colors.red[700], size: 64),
    );
  }

  Widget _buildErrorMessageContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Text(
        errorMessage!,
        style: TextStyle(color: Colors.red.shade800),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTroubleshootingTips() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Troubleshooting Tips:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Color(0xFF424242),
            ),
          ),
          const SizedBox(height: 12),
          ...troubleshootingTips.map(
            (tip) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '• ',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRetryButton() {
    return ElevatedButton.icon(
      onPressed: onRetry,
      icon: const Icon(Icons.refresh_rounded),
      label: const Text('Retry Connection'),
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFFE53935),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        minimumSize: const Size(200, 50),
      ),
    );
  }
}
