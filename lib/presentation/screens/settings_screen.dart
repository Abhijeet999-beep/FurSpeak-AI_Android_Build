import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/config/app_theme.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:provider/provider.dart';
import 'package:furspeak_ai/providers/auth_provider.dart';
import 'package:furspeak_ai/theme/app_animations.dart';
import 'package:furspeak_ai/presentation/widgets/permission_interstitial.dart';
import 'package:isar/isar.dart';
import 'package:get_it/get_it.dart';
import 'package:furspeak_ai/data/models/dog_profile.dart';
import 'package:furspeak_ai/services/result_storage_service.dart'; // For consistent button styles if needed

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _voiceNarration = false;
  bool _biometricLock = false;
  String _narratorPersonality = 'Cute Puppy';
  DogProfile? _dogProfile;
  DateTime? _lastScanTime;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceNarration = prefs.getBool('voiceNarration') ?? false;
      _biometricLock = prefs.getBool('biometricLock') ?? false;
      _narratorPersonality = prefs.getString('narratorPersonality') ?? 'Cute Puppy';
    });

    try {
      final isar = GetIt.instance<Isar>();
      final authProvider = context.read<AuthProvider>();
      final uid = authProvider.userId;
      if (uid != null && uid.isNotEmpty) {
        final profile = await isar.dogProfiles.getByUserId(uid);
        final storage = GetIt.instance<ResultStorageService>();
        final insights = storage.getInsights();
        if (mounted) {
          setState(() {
            _dogProfile = profile;
            _lastScanTime = insights.lastScanTime;
          });
        }
      }
    } catch (e) {
      debugPrint('⚠️ Error loading settings data: $e');
    }
  }

  Future<void> _setVoiceNarration(bool value) async {
    FurHaptics.tap();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _voiceNarration = value;
    });
    await prefs.setBool('voiceNarration', value);
  }

  Future<void> _setBiometricLock(bool value) async {
    FurHaptics.tap();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricLock = value;
    });
    await prefs.setBool('biometricLock', value);
  }

  Future<void> _setNarratorPersonality(String value) async {
    FurHaptics.tap();
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _narratorPersonality = value;
    });
    await prefs.setString('narratorPersonality', value);
  }

  void _showPersonalityPicker() {
    HapticFeedback.selectionClick();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => PetMoodGlass(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: Container(
          padding: const EdgeInsets.fromLTRB(
            AppTheme.space24,
            AppTheme.space24,
            AppTheme.space24,
            0,
          ),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Narrator Personality', style: AppTheme.titleStyle),
                const SizedBox(height: AppTheme.space8),
                Text('How should FurSpeak sound when reading results?', style: AppTheme.bodyStyle.copyWith(color: AppTheme.textLightColor)),
                const SizedBox(height: AppTheme.space24),
                _buildPersonalityOption('Cute Puppy', 'Energetic and playful'),
                _buildPersonalityOption('The Vet', 'Professional and caring'),
                _buildPersonalityOption('Professor', 'Analytical and detailed'),
                const SizedBox(height: AppTheme.space24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalityOption(String title, String subtitle) {
    final isSelected = _narratorPersonality == title;
    return InkWell(
      onTap: () {
        _setNarratorPersonality(title);
        Navigator.pop(context);
      },
      borderRadius: AppTheme.borderRadiusMedium,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space16),
        margin: const EdgeInsets.only(bottom: AppTheme.space8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withOpacity(0.1) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor.withOpacity(0.2),
            width: 1,
          ),
          borderRadius: AppTheme.borderRadiusMedium,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textLightColor,
            ),
            const SizedBox(width: AppTheme.space16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTheme.bodyStyle.copyWith(fontWeight: FontWeight.w700)),
                  Text(subtitle, style: AppTheme.captionStyle.copyWith(color: AppTheme.textLightColor)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
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
          SquishButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space24, vertical: AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor,
                borderRadius: AppTheme.borderRadiusMedium,
              ),
              child: Text(
                'Close',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
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
            onPressed: () {
              FurHaptics.tap();
              Navigator.pop(ctx, false);
            },
            child: Text(
              'Cancel',
              style: AppTheme.bodyStyle.copyWith(
                color: AppTheme.textLightColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          SquishButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
              decoration: BoxDecoration(
                color: AppTheme.errorColor.withOpacity(0.9),
                borderRadius: AppTheme.borderRadiusMedium,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.errorColor.withOpacity(0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                'Sign Out',
                style: AppTheme.bodyStyle.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
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
    final authProvider = context.read<AuthProvider>();

    return Selector<AuthProvider, bool>(
      selector: (_, p) => p.isLoading,
      builder: (context, isLoading, child) {
        return PopScope(
          canPop: !isLoading,
          onPopInvokedWithResult: (didPop, _) {
            if (!didPop && !isLoading) {
              context.go('/home');
            }
          },
          child: child!,
        );
      },
      child: Scaffold(
        backgroundColor: AppTheme.bgColor,
        appBar: AppBar(
          title: Text(
            'Settings',
            style: AppTheme.titleStyle.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          leading: SquishButton(
            onPressed: () {
              if (!authProvider.isLoading) {
                context.go('/home');
              }
            },
            child: const Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: AppTheme.primaryColor),
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.space20, vertical: AppTheme.space12),
            child: StaggeredEntrance(
              children: [
                // ─── Profile Hero Card ─────────────────────
                _buildHeroCard(),
                const SizedBox(height: AppTheme.space24),

                // ─── AI Voice & Narration ─────────────────────
                _buildSectionCard(
                  title: 'AI Voice & Narration',
                  icon: Icons.record_voice_over_rounded,
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
                    if (_voiceNarration) ...[
                      const SizedBox(height: AppTheme.space8),
                      _SettingsTile(
                        icon: Icons.face_retouching_natural_rounded,
                        title: 'Narrator Personality',
                        subtitle: _narratorPersonality,
                        onTap: _showPersonalityPicker,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: AppTheme.space20),

                // ─── App Experience ─────────────────────
                _buildSectionCard(
                  title: 'App Experience',
                  icon: Icons.auto_awesome_rounded,
                  children: [
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

                // ─── Privacy & Security ─────────────────────
                _buildSectionCard(
                  title: 'Privacy & Security',
                  icon: Icons.security_rounded,
                  children: [
                    _SettingsTile(
                      icon: Icons.fingerprint_rounded,
                      title: 'App Lock',
                      subtitle: 'Require biometrics to open',
                      trailing: Switch.adaptive(
                        value: _biometricLock,
                        onChanged: _setBiometricLock,
                        activeColor: AppTheme.primaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.space20),

                // ─── Account Settings ─────────────────────
                Selector<AuthProvider, ({bool isGuest, bool isLoading})>(
                  selector: (_, p) => (isGuest: p.isGuest, isLoading: p.isLoading),
                  builder: (context, state, _) {
                    return _buildSectionCard(
                      title: 'Account',
                      icon: Icons.person_rounded,
                      children: [
                        if (!state.isGuest) ...[
                          _SettingsTile(
                            icon: Icons.person_outline_rounded,
                            title: 'Profile Info',
                            subtitle: 'Manage your dog\'s profile',
                            onTap: () {
                              FurHaptics.tap();
                              context.go('${AppRoutes.profileSetup}?edit=true');
                            },
                          ),
                          const SizedBox(height: AppTheme.space8),
                        ],
                        _SettingsTile(
                          icon: state.isLoading 
                              ? Icons.sync_rounded 
                              : (state.isGuest ? Icons.login_rounded : Icons.logout_rounded),
                          title: state.isGuest ? 'Finish Setup' : 'Sign Out',
                          subtitle: state.isGuest ? 'Create an account to save data' : 'Safely exit your account',
                          textColor: state.isGuest ? AppTheme.primaryColor : AppTheme.errorColor,
                          trailing: state.isLoading 
                              ? const SizedBox(
                                  width: 16, 
                                  height: 16, 
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.errorColor)
                                ) 
                              : null,
                          onTap: state.isLoading 
                              ? null 
                              : (state.isGuest
                                  ? () {
                                      FurHaptics.impact();
                                      context.go(AppRoutes.welcome);
                                    }
                                  : _handleSignOut),
                        ),
                      ],
                    );
                  },
                ),
                const SizedBox(height: AppTheme.space20),

                // ─── Support & Info ────────────────────────
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
          ),
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime? time) {
    if (time == null) return 'No scans yet';
    final diff = DateTime.now().difference(time);
    if (diff.inDays > 0) return '${diff.inDays}d ago';
    if (diff.inHours > 0) return '${diff.inHours}h ago';
    if (diff.inMinutes > 0) return '${diff.inMinutes}m ago';
    return 'Just now';
  }

  Widget _buildHeroCard() {
    return PetMoodGlass(
      color: AppTheme.surfaceActive,
      opacity: 0.7,
      borderRadius: AppTheme.borderRadiusLarge,
      child: Container(
        padding: const EdgeInsets.all(AppTheme.space20),
        decoration: BoxDecoration(
          borderRadius: AppTheme.borderRadiusLarge,
        ),
        child: Row(
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryColor.withOpacity(0.2),
                border: Border.all(color: AppTheme.primaryColor.withOpacity(0.5), width: 2),
              ),
              child: _dogProfile?.imageUrl != null && File(_dogProfile!.imageUrl!).existsSync()
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(35),
                      child: Image.file(
                        File(_dogProfile!.imageUrl!),
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                      ),
                    )
                  : const Center(
                      child: Text('🐶', style: TextStyle(fontSize: 32)),
                    ),
            ),
            const SizedBox(width: AppTheme.space20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _dogProfile?.name ?? 'No Pet Profile',
                    style: AppTheme.titleStyle.copyWith(fontSize: 22, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _dogProfile != null
                        ? '${_dogProfile!.breed} • ${_dogProfile!.age} ${_dogProfile!.age == 1 ? 'Year' : 'Years'}'
                        : 'Tap Profile Info to setup',
                    style: AppTheme.bodyStyle.copyWith(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: AppTheme.space12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.bgColor.withOpacity(0.5),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded, size: 14, color: AppTheme.textLightColor),
                        const SizedBox(width: 6),
                        Text(
                          'Last scan: ${_formatTimeAgo(_lastScanTime)}',
                          style: AppTheme.captionStyle.copyWith(color: AppTheme.textLightColor, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTheme.titleStyle.copyWith(
                        fontSize: 15,
                        color: textColor ?? AppTheme.textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
