import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

// Model class for chat messages
class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });
}

// Model class for chat sessions - we'll keep this but not use its full functionality
class ChatSession {
  final String id;
  final String title;
  final String lastMessage;
  final DateTime timestamp;

  ChatSession({
    required this.id,
    required this.title,
    required this.lastMessage,
    required this.timestamp,
  });
}

class ChatQHomePage extends StatefulWidget {
  const ChatQHomePage({super.key});

  @override
  State<ChatQHomePage> createState() => _ChatQHomePageState();
}

class _ChatQHomePageState extends State<ChatQHomePage> {
  final TextEditingController _mainInputController = TextEditingController();
  final String _selectedMode = 'chat';
  final bool _isPremiumUser = false;
  bool _isLoading = false;

  // Chat message storage
  List<ChatMessage> _messages = [];

  // Use existing chatSessions for the guides
  final List<ChatSession> _chatSessions = [
    ChatSession(
      id: '1',
      title: 'Fire Emergency Protocols',
      lastMessage: 'What are the steps for evacuating a high-rise building?',
      timestamp: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
    ChatSession(
      id: '2',
      title: 'Flood Safety Guidelines',
      lastMessage: 'How to secure your home before flood waters arrive?',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    ChatSession(
      id: '3',
      title: 'First Aid for Injuries',
      lastMessage: 'How to treat burn injuries until help arrives',
      timestamp: DateTime.now().subtract(const Duration(days: 1)),
    ),
    ChatSession(
      id: '4',
      title: 'Building Collapse Safety',
      lastMessage: 'What to do if trapped under debris after collapse',
      timestamp: DateTime.now().subtract(const Duration(days: 2)),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _loadChatHistory();
    // Add welcome message
    _addBotMessage(
      "Hello! I'm your ResQ emergency assistant. How can I help you today? You can ask me about emergency procedures, safety tips, or how to use ResQ features.",
    );
  }

  @override
  void dispose() {
    _mainInputController.dispose();
    super.dispose();
  }

  // Load chat history from SharedPreferences
  Future<void> _loadChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryJson = prefs.getString('chat_history');

      if (chatHistoryJson != null) {
        final chatHistoryList = jsonDecode(chatHistoryJson) as List;
        setState(() {
          _messages =
              chatHistoryList
                  .map(
                    (messageJson) => ChatMessage(
                      text: messageJson['text'],
                      isUser: messageJson['isUser'],
                      timestamp: DateTime.parse(messageJson['timestamp']),
                    ),
                  )
                  .toList();
        });
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  // Save chat history to SharedPreferences
  Future<void> _saveChatHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatHistoryList =
          _messages
              .map(
                (message) => {
                  'text': message.text,
                  'isUser': message.isUser,
                  'timestamp': message.timestamp.toIso8601String(),
                },
              )
              .toList();

      await prefs.setString('chat_history', jsonEncode(chatHistoryList));
    } catch (e) {
      print('Error saving chat history: $e');
    }
  }

  void _addUserMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessage(text: message, isUser: true, timestamp: DateTime.now()),
      );
    });
    _saveChatHistory();
  }

  void _addBotMessage(String message) {
    setState(() {
      _messages.add(
        ChatMessage(text: message, isUser: false, timestamp: DateTime.now()),
      );
    });
    _saveChatHistory();
  }

  // Handle chat input and generate responses based on input
  Future<void> _handleMainInput() async {
    final userInput = _mainInputController.text.trim();
    if (userInput.isEmpty) return;

    _addUserMessage(userInput);
    _mainInputController.clear();

    setState(() {
      _isLoading = true;
    });

    // Simulate a brief delay for the bot to "think"
    await Future.delayed(const Duration(milliseconds: 800));

    // Generate a response based on keywords in the user input
    final response = _generateResponse(userInput);
    _addBotMessage(response);

    setState(() {
      _isLoading = false;
    });
  }

  // Simple keyword-based response generator (in a real app, this would be an API call)
  String _generateResponse(String input) {
    final lowerInput = input.toLowerCase();

    // Emergency related keywords
    if (lowerInput.contains('fire') || lowerInput.contains('burning')) {
      return "If you're facing a fire emergency:\n\n1. Stay low to avoid smoke inhalation\n2. Use stairs, NOT elevators\n3. Feel doors before opening - if hot, find another exit\n4. Call emergency services immediately\n5. If trapped, seal doors with wet towels and signal from windows";
    }

    if (lowerInput.contains('flood') || lowerInput.contains('water')) {
      return "For flood safety:\n\n1. Move to higher ground immediately\n2. Don't walk or drive through flood waters\n3. Disconnect utilities if safe to do so\n4. Prepare an emergency kit with food, water, medications\n5. Monitor emergency broadcasts for instructions";
    }

    if (lowerInput.contains('earthquake') ||
        lowerInput.contains('building') ||
        lowerInput.contains('collapse')) {
      return "During an earthquake or building collapse:\n\n1. Drop, Cover, and Hold On\n2. Stay away from windows and exterior walls\n3. If trapped, protect your airway and tap on pipes/walls\n4. Don't use elevators\n5. After shaking stops, exit carefully and watch for hazards";
    }

    if (lowerInput.contains('medical') ||
        lowerInput.contains('hurt') ||
        lowerInput.contains('injury') ||
        lowerInput.contains('bleeding')) {
      return "For medical emergencies:\n\n1. Call emergency services immediately\n2. For bleeding: apply direct pressure with clean cloth\n3. For burns: cool with running water, don't use ice\n4. Keep the person still if spinal injury is suspected\n5. Perform CPR if trained and needed";
    }

    if (lowerInput.contains('sos') ||
        lowerInput.contains('help') ||
        lowerInput.contains('emergency')) {
      return "To report an emergency through ResQ:\n\n1. Tap the SOS button on the home screen\n2. Choose whether you're a victim or spectator\n3. Provide details about the emergency\n4. Your location will automatically be shared with emergency services\n5. Stay on the line for further instructions";
    }

    if (lowerInput.contains('report') || lowerInput.contains('incident')) {
      return "To report an incident in ResQ:\n\n1. Go to the home screen and tap 'Report Emergency'\n2. Select the incident type and provide details\n3. Upload photos if available\n4. Confirm your location or adjust if needed\n5. Submit your report to alert emergency services";
    }

    if (lowerInput.contains('contact') ||
        lowerInput.contains('call') ||
        lowerInput.contains('phone')) {
      return "To contact emergency services through ResQ:\n\n1. Use the SOS button for immediate help\n2. For non-urgent situations, go to 'Emergency Contacts'\n3. Select the appropriate service type\n4. The app will connect you while sharing your location data\n5. Your emergency contacts will also be notified";
    }

    if (lowerInput.contains('hi') ||
        lowerInput.contains('hello') ||
        lowerInput.contains('hey')) {
      return "Hi there! I'm your ResQ emergency assistant. How can I help you today? You can ask me about emergency procedures, safety guidelines, or how to use the ResQ app features.";
    }

    if (lowerInput.contains('thank')) {
      return "You're welcome! Your safety is our priority. Is there anything else I can help you with?";
    }

    // Default response
    return "I'm not sure I understand your question. Could you rephrase or ask about a specific emergency situation like fire, flood, earthquake, or medical emergencies? You can also ask about how to use ResQ features.";
  }

  void _handleLibrary() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Opening Library')));
  }

  void _handleVoiceInput() {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Voice input activated')));
  }

  void _showChatSessions() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.8,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Header - Removed the + button
                      const Row(
                        children: [
                          Text(
                            'Emergency Guides',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Chat Sessions List
                      Expanded(
                        child: ListView.builder(
                          controller: scrollController,
                          itemCount: _chatSessions.length,
                          itemBuilder: (context, index) {
                            final session = _chatSessions[index];
                            return _buildChatSessionTile(session);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildChatSessionTile(ChatSession session) {
    // Set appropriate icon for each emergency type
    IconData tileIcon;
    if (session.title.contains('Fire')) {
      tileIcon = Icons.local_fire_department;
    } else if (session.title.contains('Flood')) {
      tileIcon = Icons.water_damage;
    } else if (session.title.contains('First Aid')) {
      tileIcon = Icons.medical_services;
    } else if (session.title.contains('Building Collapse')) {
      tileIcon = Icons.domain_disabled;
    } else {
      tileIcon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.red[100],
            borderRadius: BorderRadius.circular(20),
          ),
          child: Icon(tileIcon, color: Colors.red, size: 20),
        ),
        title: Text(
          session.title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              session.lastMessage,
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatTimestamp(session.timestamp),
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
            ),
          ],
        ),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey),
        onTap: () {
          Navigator.pop(context);
          _showEmergencyGuide(session);
        },
      ),
    );
  }

  // Show the emergency guide content
  void _showEmergencyGuide(ChatSession guide) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EmergencyGuideDetailPage(guideTitle: guide.title),
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  void _showFAQPage() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const FAQPage()),
    );
  }

  void _showPremiumDetails() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const PremiumDetailsPage()),
    );
  }

  void _showProfileDetails() {
    // Implementation kept from the original code
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder:
          (context) => DraggableScrollableSheet(
            initialChildSize: 0.7,
            minChildSize: 0.5,
            maxChildSize: 0.9,
            expand: false,
            builder:
                (context, scrollController) => Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      // Handle bar
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Profile Header
                      Row(
                        children: [
                          const CircleAvatar(
                            radius: 30,
                            backgroundColor: Colors.red,
                            child: Icon(
                              Icons.person,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'ChatQ User',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Rasel',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color:
                                        _isPremiumUser
                                            ? Colors.amber[100]
                                            : Colors.grey[200],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_isPremiumUser)
                                        const Icon(
                                          Icons.workspace_premium,
                                          size: 14,
                                          color: Colors.amber,
                                        ),
                                      if (_isPremiumUser)
                                        const SizedBox(width: 4),
                                      Text(
                                        _isPremiumUser
                                            ? 'ChatQ Pro'
                                            : 'Free Plan',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color:
                                              _isPremiumUser
                                                  ? Colors.amber[700]
                                                  : Colors.grey[600],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // Profile Options
                      Expanded(
                        child: ListView(
                          controller: scrollController,
                          children: [
                            _buildProfileOption(
                              icon: Icons.edit,
                              title: 'Edit Profile',
                              subtitle: 'Update your personal information',
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening Edit Profile'),
                                  ),
                                );
                              },
                            ),
                            if (!_isPremiumUser)
                              _buildProfileOption(
                                icon: Icons.workspace_premium,
                                title: 'Upgrade to ChatQ Pro',
                                subtitle:
                                    'Get unlimited access and advanced features',
                                trailing: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.amber,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: const Text(
                                    'PRO',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                onTap: () {
                                  Navigator.pop(context);
                                  _showPremiumDetails();
                                },
                              ),
                            _buildProfileOption(
                              icon: Icons.history,
                              title: 'Emergency Guides',
                              subtitle: 'View your emergency guide history',
                              onTap: () {
                                Navigator.pop(context);
                                _showChatSessions();
                              },
                            ),
                            _buildProfileOption(
                              icon: Icons.settings,
                              title: 'Settings',
                              subtitle: 'Manage your preferences',
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening Settings'),
                                  ),
                                );
                              },
                            ),
                            _buildProfileOption(
                              icon: Icons.help_outline,
                              title: 'Help & Support',
                              subtitle: 'Get help and contact support',
                              onTap: () {
                                Navigator.pop(context);
                                _showFAQPage();
                              },
                            ),
                            _buildProfileOption(
                              icon: Icons.privacy_tip_outlined,
                              title: 'Privacy Policy',
                              subtitle: 'View our privacy policy',
                              onTap: () {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Opening Privacy Policy'),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 20),
                            _buildProfileOption(
                              icon: Icons.logout,
                              title: 'Sign Out',
                              subtitle: 'Sign out of your account',
                              isDestructive: true,
                              onTap: () {
                                Navigator.pop(context);
                                _showSignOutDialog();
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
          ),
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required String subtitle,
    Widget? trailing,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: isDestructive ? Colors.red[50] : Colors.grey[100],
        child: Icon(
          icon,
          color: isDestructive ? Colors.red : Colors.grey[700],
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: isDestructive ? Colors.red : Colors.black87,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
    );
  }

  void _showSignOutDialog() {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Sign Out'),
            content: const Text(
              'Are you sure you want to sign out of your account?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signed out successfully')),
                  );
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Sign Out'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.red, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.local_fire_department,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Flexible(
              child: Text(
                'ChatQ',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        actions: [
          // Emergency guides button
          IconButton(
            icon: const Icon(Icons.menu_book_outlined),
            color: Colors.red,
            onPressed: _showChatSessions,
          ),
          // Help button
          IconButton(
            icon: const Icon(Icons.help_outline),
            color: Colors.grey[700],
            onPressed: _showFAQPage,
          ),
          // Premium upgrade button (only for non-premium users)
          if (!_isPremiumUser)
            Flexible(
              child: Container(
                margin: const EdgeInsets.only(right: 8),
                child: TextButton.icon(
                  onPressed: _showPremiumDetails,
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  icon: const Icon(Icons.workspace_premium, size: 14),
                  label: const Text(
                    'Upgrade',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Main content - Chat messages
          Expanded(
            child: Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child:
                  _messages.isEmpty
                      ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 60,
                              color: Colors.grey[300],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Ask me anything about emergency procedures',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[500],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      )
                      : ListView.builder(
                        reverse: true,
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message =
                              _messages[_messages.length - 1 - index];
                          return _buildChatMessage(message);
                        },
                      ),
            ),
          ),

          // Typing indicator
          if (_isLoading)
            Container(
              color: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(width: 20),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Thinking...',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

          // Input field
          Container(
            color: Colors.white,
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _mainInputController,
                            decoration: const InputDecoration(
                              hintText: 'Ask about emergency procedures...',
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                            ),
                            onSubmitted: (_) => _handleMainInput(),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mic, color: Colors.red),
                          onPressed: _handleVoiceInput,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white, size: 20),
                    onPressed: _handleMainInput,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Build chat message bubble
  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          top: 8,
          bottom: 8,
          left: message.isUser ? 64 : 8,
          right: message.isUser ? 8 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: message.isUser ? Colors.red.shade500 : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 2,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: TextStyle(
                color: message.isUser ? Colors.white : Colors.black87,
                fontSize: 15,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                color:
                    message.isUser
                        ? Colors.white.withOpacity(0.7)
                        : Colors.grey.shade600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    // Format time as HH:MM
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Widget _buildMenuTile({
    required IconData icon,
    required String title,
    String? trailing,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.grey[600], size: 20),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
      ),
      trailing:
          trailing != null
              ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  trailing,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                ),
              )
              : const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 2),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    String? label,
    bool isHighlighted = false,
    required VoidCallback onPressed,
  }) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isHighlighted ? Colors.red : Colors.grey[100],
        foregroundColor: isHighlighted ? Colors.white : Colors.grey[600],
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18),
          if (label != null) ...[
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ],
        ],
      ),
    );
  }
}

// FAQ Page with updated emergency-focused questions
class FAQPage extends StatelessWidget {
  const FAQPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Safety Guidelines'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildFAQItem(
            'What should I do during a fire emergency?',
            'Stay low to the ground to avoid smoke inhalation. If possible, cover your mouth with a damp cloth. Exit the building following your emergency escape plan, and never use elevators. If trapped, seal doors with wet towels and signal for help from windows. Call emergency services once you\'re safe.',
          ),
          _buildFAQItem(
            'How should I prepare for a flood?',
            'Create an emergency kit with food, water, medications, and important documents in waterproof containers. Know evacuation routes and monitor weather alerts. Move valuable items to higher levels and be ready to turn off utilities if instructed. If evacuation is ordered, do so immediately.',
          ),
          _buildFAQItem(
            'What actions should I take during a building collapse?',
            'If you sense a collapse is imminent, exit immediately if possible. If trapped, cover your mouth, avoid unnecessary movement, and tap on pipes or walls to signal rescuers. Don\'t light matches or use lighters due to potential gas leaks. Conserve your phone battery and call for help when possible.',
          ),
          _buildFAQItem(
            'How can I signal rescuers if I\'m trapped?',
            'Use a whistle, tap on pipes or walls in sets of three (universal distress signal), flash a light, or wave bright-colored cloth if near an opening. If you have phone service, call emergency services and describe your location in detail. Conserve energy between signaling attempts.',
          ),
          _buildFAQItem(
            'What items should be in my emergency kit?',
            'Your emergency kit should include: water (one gallon per person per day for 3 days), non-perishable food, first aid supplies, flashlight, battery-powered radio, extra batteries, whistle, dust masks, plastic sheeting, duct tape, moist towelettes, garbage bags, local maps, and a portable phone charger.',
          ),
          _buildFAQItem(
            'How can I help others during an emergency?',
            'Only help if you can do so safely without endangering yourself. Provide first aid if you are trained. Don\'t move seriously injured people unless they\'re in immediate danger. Report trapped individuals to emergency responders and share specific location details. Follow instructions from emergency personnel.',
          ),
          _buildFAQItem(
            'How does the ResQ app help during emergencies?',
            'ResQ connects you with emergency services and provides real-time guidance during crises. It features location sharing, emergency contacts, step-by-step safety protocols, and communication tools when traditional methods fail. The app works offline and includes pre-downloaded safety instructions for various emergencies.',
          ),
        ],
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: ExpansionTile(
        title: Text(
          question,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Premium Details Page
class PremiumDetailsPage extends StatelessWidget {
  const PremiumDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ChatQ Pro'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Colors.amber, Colors.orange],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.workspace_premium,
                    color: Colors.white,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'ChatQ Pro',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Unlock the full potential of ChatQ',
                    style: TextStyle(color: Colors.white, fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Features
            const Text(
              'Pro Features',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            _buildFeatureItem(
              Icons.chat_bubble_outline,
              'Advanced Emergency Guidance',
              'Get personalized emergency response plans',
            ),
            _buildFeatureItem(
              Icons.flash_on,
              'Faster Response Times',
              'Priority connection to emergency services',
            ),
            _buildFeatureItem(
              Icons.psychology,
              'AI-Powered Risk Assessment',
              'Get real-time danger evaluation in emergencies',
            ),
            _buildFeatureItem(
              Icons.history,
              'Extended Emergency History',
              'Keep comprehensive records of all incidents',
            ),
            _buildFeatureItem(
              Icons.support_agent,
              'Priority Support',
              '24/7 access to emergency specialists',
            ),

            const SizedBox(height: 32),

            // Pricing
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Column(
                children: [
                  const Text(
                    'Special Launch Offer',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$4.99',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Colors.amber[700],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/month',
                        style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Cancel anytime • 7-day free trial',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Upgrade Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Upgrade functionality would be implemented here',
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.amber,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.workspace_premium, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'Start Free Trial',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Terms
            Text(
              'By subscribing, you agree to our Terms of Service and Privacy Policy. Your subscription will automatically renew unless cancelled at least 24 hours before the end of the current period.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.amber[100],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: Colors.amber[700], size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Emergency Guide Detail Page
class EmergencyGuideDetailPage extends StatelessWidget {
  final String guideTitle;

  const EmergencyGuideDetailPage({super.key, required this.guideTitle});

  @override
  Widget build(BuildContext context) {
    // Return different content based on guide title
    return Scaffold(
      appBar: AppBar(
        title: Text(guideTitle),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header icon and title
            Center(
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.red[100],
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Icon(
                      _getIconForGuide(guideTitle),
                      color: Colors.red,
                      size: 30,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    guideTitle,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Guide content
            ..._getContentForGuide(guideTitle),
          ],
        ),
      ),
    );
  }

  IconData _getIconForGuide(String title) {
    if (title.contains('Fire')) {
      return Icons.local_fire_department;
    } else if (title.contains('Flood')) {
      return Icons.water_damage;
    } else if (title.contains('First Aid')) {
      return Icons.medical_services;
    } else if (title.contains('Building Collapse')) {
      return Icons.domain_disabled;
    } else {
      return Icons.warning_amber_rounded;
    }
  }

  List<Widget> _getContentForGuide(String title) {
    if (title.contains('Fire')) {
      return _getFireGuideContent();
    } else if (title.contains('Flood')) {
      return _getFloodGuideContent();
    } else if (title.contains('First Aid')) {
      return _getFirstAidGuideContent();
    } else if (title.contains('Building Collapse')) {
      return _getBuildingCollapseGuideContent();
    } else {
      return [const Text('Guide content not available.')];
    }
  }

  List<Widget> _getFireGuideContent() {
    return [
      _buildGuideSection('Evacuating a High-Rise Building', [
        '1. Stay calm and don\'t use elevators',
        '2. Use stairwells for evacuation',
        '3. Feel doors before opening them - if hot, find another exit',
        '4. Stay low to the floor to avoid smoke inhalation',
        '5. Cover your nose and mouth with a damp cloth if possible',
        '6. Close doors behind you to slow fire spread',
      ]),
      _buildGuideSection('If You\'re Trapped', [
        '1. Seal cracks around doors with wet towels or clothing',
        '2. Signal for help from windows with bright cloth or flashlight',
        '3. Call emergency services with your exact location',
        '4. Stay close to the floor where air is cleaner',
      ]),
      _buildGuideSection('Fire Prevention Tips', [
        '• Install smoke alarms on every level of your home',
        '• Create and practice a fire escape plan',
        '• Keep flammable items away from heat sources',
        '• Never leave cooking unattended',
        '• Check electrical cords for damage regularly',
      ]),
    ];
  }

  List<Widget> _getFloodGuideContent() {
    return [
      _buildGuideSection('Before a Flood', [
        '1. Know your area\'s flood risk',
        '2. Prepare an emergency kit with essential supplies',
        '3. Safeguard valuable documents in waterproof containers',
        '4. Learn community evacuation routes',
        '5. Install check valves to prevent water backup',
      ]),
      _buildGuideSection('During Evacuation', [
        '1. Listen to authorities for evacuation instructions',
        '2. Disconnect utilities if instructed',
        '3. Secure your home if time permits',
        '4. Take only essential items with you',
        '5. Never walk, swim, or drive through flood waters',
      ]),
      _buildGuideSection('If You Cannot Evacuate', [
        '1. Move to the highest level of the building',
        '2. Avoid closed attics where you might become trapped',
        '3. Only go onto the roof if necessary',
        '4. Signal for help using bright cloth, flashlight, or whistle',
      ]),
    ];
  }

  List<Widget> _getFirstAidGuideContent() {
    return [
      _buildGuideSection('Burn Treatment', [
        '1. Cool the burn with cool (not cold) running water for 10-15 minutes',
        '2. Do not apply ice directly to burns',
        '3. Remove jewelry or tight items before swelling occurs',
        '4. Cover with sterile, non-adhesive bandage or clean cloth',
        '5. Do not apply butter, ointments, or home remedies to serious burns',
        '6. Seek medical attention for chemical burns, electrical burns, or large burns',
      ]),
      _buildGuideSection('Bleeding Control', [
        '1. Apply direct pressure with clean cloth or bandage',
        '2. If bleeding continues, add more material without removing the first layer',
        '3. Elevate the injured area above the heart if possible',
        '4. For severe bleeding, apply pressure to the artery (pressure point)',
        '5. Only use tourniquets as a last resort',
      ]),
      _buildGuideSection('CPR Basics', [
        '1. Check for responsiveness and call for emergency help',
        '2. Position person on back on firm surface',
        '3. Place hands in center of chest (between nipples)',
        '4. Perform compressions: Push hard, push fast (100-120 per minute)',
        '5. Allow chest to completely recoil between compressions',
      ]),
    ];
  }

  List<Widget> _getBuildingCollapseGuideContent() {
    return [
      _buildGuideSection('If You Are Trapped', [
        '1. Cover your nose and mouth to filter dust',
        '2. Avoid unnecessary movement to prevent stirring up dust',
        '3. Tap on pipes or walls so rescuers can hear you',
        '4. Shout only as a last resort (to avoid inhaling dust)',
        '5. Stay near walls or under sturdy furniture',
      ]),
      _buildGuideSection('Safety Precautions', [
        '1. Do not use matches, lighters, or open flames',
        '2. Avoid shifting building materials',
        '3. Listen for sounds of rescuers',
        '4. If you have a phone, conserve battery and call for help',
        '5. Signal your location with reflective material or bright objects',
      ]),
      _buildGuideSection('After Being Rescued', [
        '1. Seek immediate medical attention even if you appear uninjured',
        '2. Watch for delayed symptoms of injuries',
        '3. Follow authorities instructions regarding safety',
        '4. Stay away from damaged buildings until declared safe',
      ]),
    ];
  }

  Widget _buildGuideSection(String title, List<String> bullets) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 12),
        ...bullets.map(
          (bullet) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              bullet,
              style: const TextStyle(fontSize: 16, height: 1.5),
            ),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
