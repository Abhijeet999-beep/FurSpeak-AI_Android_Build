import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _autoClearTemp = true;
  bool _autoSaveHistory = true;
  bool _pushNotifications = false;
  bool _dailySummaries = false;
  TimeOfDay _summaryTime = const TimeOfDay(hour: 8, minute: 0);
  String _defaultDog = 'Buddy';
  final List<String> _dogProfiles = ['Buddy', 'Luna', 'Max', 'Bella'];
  bool _voiceNarration = false;

  @override
  void initState() {
    super.initState();
    _loadVoiceNarration();
  }

  Future<void> _loadVoiceNarration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceNarration = prefs.getBool('voiceNarration') ?? false;
    });
  }

  Future<void> _setVoiceNarration(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceNarration = value;
    });
    await prefs.setBool('voiceNarration', value);
  }

  Future<void> _pickSummaryTime() async {
    HapticFeedback.selectionClick();
    final picked = await showTimePicker(
      context: context,
      initialTime: _summaryTime,
    );
    if (picked != null) {
      setState(() => _summaryTime = picked);
    }
  }

  void _showAboutDialog() {
    HapticFeedback.selectionClick();
    showAboutDialog(
      context: context,
      applicationName: 'FurSpeak AI',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 FurSpeak AI',
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 16.0),
          child: Text(
            'FurSpeak AI helps you understand your dog\'s emotions using AI-powered analysis. Built with love for dog owners everywhere!',
            style: const TextStyle(fontFamily: 'Inter'),
          ),
        ),
      ],
    );
  }

  void _showPrivacyPolicy() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Our privacy policy will be available soon.',
            style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  void _showContactSupport() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Contact Support',
            style:
                TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        content: const Text('Email us at support@furspeak.ai',
            style: TextStyle(fontFamily: 'Inter')),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        // If you have a loading state, block back navigation
        // if (_isLoading) return false;
        context.go('/home');
        return false;
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFFCF5), // Creamy White
        appBar: AppBar(
          title: const Text(
            'Settings',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A5BD9), // Sky Indigo
            ),
          ),
          backgroundColor: Colors.white,
          elevation: 0,
          iconTheme:
              const IconThemeData(color: Color(0xFF5A5BD9)), // Sky Indigo
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // General Settings
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'General',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A5BD9), // Sky Indigo
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingsTile(
                        icon: Icons.notifications,
                        title: 'Notifications',
                        subtitle: 'Manage notification preferences',
                        onTap: () {
                          // Handle notifications settings
                        },
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.language,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {
                          // Handle language settings
                        },
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.dark_mode,
                        title: 'Dark Mode',
                        subtitle: 'System default',
                        trailing: Switch(
                          value: false,
                          onChanged: (value) {
                            // Handle dark mode toggle
                          },
                        ),
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.volume_up,
                        title: 'Enable Voice Narration',
                        subtitle: 'Let the app speak emotion results out loud.',
                        trailing: Switch(
                          value: _voiceNarration,
                          onChanged: (value) => _setVoiceNarration(value),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Account Settings
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Account',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A5BD9), // Sky Indigo
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingsTile(
                        icon: Icons.person,
                        title: 'Profile',
                        subtitle: 'Manage your profile information',
                        onTap: () {
                          // Handle profile settings
                        },
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.security,
                        title: 'Security',
                        subtitle: 'Password and security settings',
                        onTap: () {
                          // Handle security settings
                        },
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.delete,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account',
                        textColor: const Color(0xFFF95F62), // Coral Red
                        onTap: () {
                          // Handle account deletion
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // About Section
              Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'About',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A5BD9), // Sky Indigo
                        ),
                      ),
                      const SizedBox(height: 16),
                      _SettingsTile(
                        icon: Icons.info,
                        title: 'Version',
                        subtitle: '1.0.0',
                        onTap: null,
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.description,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms and conditions',
                        onTap: () {
                          // Handle terms of service
                        },
                      ),
                      const Divider(),
                      _SettingsTile(
                        icon: Icons.privacy_tip,
                        title: 'Privacy Policy',
                        subtitle: 'Read our privacy policy',
                        onTap: () {
                          // Handle privacy policy
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final Color? textColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(
        icon,
        color: textColor ?? const Color(0xFF5A5BD9), // Sky Indigo
      ),
      title: Text(
        title,
        style: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor ?? const Color(0xFF2C2C2C), // Charcoal Gray
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          fontFamily: 'Inter',
          fontSize: 14,
          color: const Color(0xFF777777), // Stone Gray
        ),
      ),
      trailing: trailing ??
          (onTap != null
              ? const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF5A5BD9), // Sky Indigo
                )
              : null),
      onTap: onTap,
    );
  }
}
