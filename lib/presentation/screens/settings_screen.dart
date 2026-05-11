import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/presentation/widgets/permission_interstitial.dart'; // For consistent button styles if needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
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
    FurHaptics.tap();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceNarration = value;
    });
    await prefs.setBool('voiceNarration', value);
  }

  void _showAboutDialog() {
    HapticFeedback.selectionClick();
    showAboutDialog(
      context: context,
      applicationName: 'FurSpeak AI',
      applicationVersion: '1.0.0',
      applicationLegalese: '© 2024 FurSpeak AI. All rights reserved.',
      children: [
        Padding(
          padding: const EdgeInsets.only(top: AppTheme.space16),
          child: Text(
            'FurSpeak AI helps you understand your dog\'s emotions using AI-powered analysis. Built with love for dog owners everywhere! 🐾',
            style: AppTheme.bodyStyle,
          ),
        ),
      ],
    );
  }

  void _showContactSupport() {
    HapticFeedback.selectionClick();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        backgroundColor: AppTheme.surfaceActive,
        title: Text('Contact Support', style: AppTheme.titleStyle.copyWith(color: AppTheme.primaryColor)),
        content: Text(
          'Have a question or need help?\n\nEmail us at support@furspeak.ai 📧',
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.textLightColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text('Close', style: AppTheme.bodyStyle.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSignOut() async {
    HapticFeedback.mediumImpact();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusLarge),
        backgroundColor: AppTheme.surfaceActive,
        title: Row(
          children: [
            Icon(Icons.logout_rounded, color: AppTheme.accentColor, size: 24),
            const SizedBox(width: AppTheme.space12),
            Text('Sign Out', style: AppTheme.titleStyle),
          ],
        ),
        content: Text(
          'Are you sure you want to sign out? You can always sign back in later.',
          style: AppTheme.bodyStyle.copyWith(color: AppTheme.textLightColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: AppTheme.bodyStyle.copyWith(color: AppTheme.textLightColor, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: AppTheme.borderRadiusMedium),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space16, vertical: AppTheme.space12),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Sign Out', style: AppTheme.bodyStyle.copyWith(color: Colors.white, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    ) ?? false;

    if (confirmed && mounted) {
      final authProvider = context.read<AuthProvider>();
      await authProvider.logout();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final isGuest = authProvider.isGuest;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: Text(
            'Settings',
            style: AppTheme.titleStyle.copyWith(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            onPressed: () {
              FurHaptics.tap();
              context.go('/home');
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.primaryColor),
          ),
        ),
        body: SafeArea(
          child: StaggeredEntrance(
            children: [
              ListView(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
                children: [
                  // ─── General Settings ─────────────────────
                  _buildSectionCard(
                    title: 'App Experience',
                    icon: Icons.auto_awesome_rounded,
                    children: [
                      _SettingsTile(
                        icon: Icons.volume_up_rounded,
                        title: 'Voice Narration',
                        subtitle: 'Read emotion results aloud',
                        trailing: Switch.adaptive(
                          value: _voiceNarration,
                          onChanged: _setVoiceNarration,
                          activeColor: AppTheme.primaryColor,
                        ),
                      ),
                      const SizedBox(height: AppTheme.space8),
                      _SettingsTile(
                        icon: Icons.language_rounded,
                        title: 'Language',
                        subtitle: 'English',
                        onTap: () {
                          FurHaptics.tap();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('🌍 More languages coming soon!', style: AppTheme.bodyStyle.copyWith(color: Colors.white, fontSize: 14)),
                              backgroundColor: AppTheme.textColor,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              margin: const EdgeInsets.all(AppTheme.space16),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space20),
    
                  // ─── Account Settings ─────────────────────
                  _buildSectionCard(
                    title: 'Account',
                    icon: Icons.person_rounded,
                    children: [
                      if (!isGuest) ...[
                        _SettingsTile(
                          icon: Icons.person_outline_rounded,
                          title: 'Profile Info',
                          subtitle: 'Manage your dog\'s profile',
                          onTap: () {
                            FurHaptics.tap();
                            context.go(AppRoutes.profileSetup);
                          },
                        ),
                        const SizedBox(height: AppTheme.space8),
                      ],
                      _SettingsTile(
                        icon: isGuest ? Icons.login_rounded : Icons.logout_rounded,
                        title: isGuest ? 'Finish Setup' : 'Sign Out',
                        subtitle: isGuest ? 'Create an account to save data' : 'Safely exit your account',
                        textColor: isGuest ? AppTheme.primaryColor : AppTheme.errorColor,
                        onTap: isGuest
                            ? () {
                                FurHaptics.impact();
                                context.go(AppRoutes.welcome);
                              }
                            : _handleSignOut,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space20),
    
                  // ─── About Section ────────────────────────
                  _buildSectionCard(
                    title: 'Support & Info',
                    icon: Icons.info_outline_rounded,
                    children: [
                      _SettingsTile(
                        icon: Icons.description_rounded,
                        title: 'Terms of Service',
                        subtitle: 'Read our terms and conditions',
                        onTap: () {
                          FurHaptics.tap();
                          _showAboutDialog();
                        },
                      ),
                      const SizedBox(height: AppTheme.space8),
                      _SettingsTile(
                        icon: Icons.privacy_tip_rounded,
                        title: 'Privacy Policy',
                        subtitle: 'How we handle your data',
                        onTap: () {
                          FurHaptics.tap();
                          _showAboutDialog();
                        },
                      ),
                      const SizedBox(height: AppTheme.space8),
                      _SettingsTile(
                        icon: Icons.support_agent_rounded,
                        title: 'Contact Support',
                        subtitle: 'Get help from our team',
                        onTap: () {
                          FurHaptics.tap();
                          _showContactSupport();
                        },
                      ),
                      const SizedBox(height: AppTheme.space16),
                      Center(
                        child: Column(
                          children: [
                            Text(
                              'FurSpeak AI v1.0.0',
                              style: AppTheme.captionStyle.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.textLightColor.withOpacity(0.4),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Made with 🐾 for dog lovers',
                              style: AppTheme.captionStyle.copyWith(
                                fontSize: 11,
                                color: AppTheme.textLightColor.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return PetMoodGlass(
      color: AppTheme.surfaceActive,
      opacity: 0.7,
      borderRadius: AppTheme.borderRadiusLarge,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        decoration: BoxDecoration(
          borderRadius: AppTheme.borderRadiusLarge,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Row(
                children: [
                  Icon(icon, size: 18, color: AppTheme.primaryColor),
                  const SizedBox(width: AppTheme.space12),
                  Text(
                    title.toUpperCase(),
                    style: AppTheme.titleStyle.copyWith(
                      color: AppTheme.primaryColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space12),
            ...children,
          ],
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: AppTheme.borderRadiusMedium,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.space12,
            vertical: AppTheme.space12,
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: (textColor ?? AppTheme.primaryColor).withOpacity(0.08),
                  borderRadius: AppTheme.borderRadiusMedium,
                ),
                child: Icon(
                  icon,
                  color: textColor ?? AppTheme.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: AppTheme.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 15,
                        color: textColor ?? AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTheme.captionStyle.copyWith(
                        fontSize: 13,
                        color: AppTheme.textLightColor,
                      ),
                    ),
                  ],
                ),
              ),
              trailing ??
                  (onTap != null
                      ? Icon(
                          Icons.chevron_right_rounded,
                          color: AppTheme.primaryColor.withOpacity(0.4),
                          size: 22,
                        )
                      : const SizedBox.shrink()),
            ],
          ),
        ),
      ),
    );
  }
}
