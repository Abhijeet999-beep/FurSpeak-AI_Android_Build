import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/presentation/screens/home_screen.dart';
import 'package:furspeak_ai/presentation/screens/history_screen.dart';
import 'package:furspeak_ai/presentation/screens/settings_screen.dart';
import 'package:furspeak_ai/presentation/screens/guest_mode_warning_screen.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';

class RootNavShell extends StatelessWidget {
  final Widget child;
  final int selectedIndex;

  const RootNavShell({
    super.key,
    required this.child,
    required this.selectedIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isGuest = authService.isGuestMode;

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
        backgroundColor: AppTheme.bgColor,
        indicatorColor: AppTheme.primaryColor.withOpacity(0.08),
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          if (isGuest && (index == 1 || index == 2)) {
            // Show guest mode warning when trying to access history or settings
            showModalBottomSheet(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              builder: (context) => GuestModeWarningScreen(
                onContinue: () {
                  Navigator.pop(context);
                  context.goHome();
                },
                onSignIn: () {
                  Navigator.pop(context);
                  context.goLogin();
                },
              ),
            );
          } else {
            switch (index) {
              case 0:
                context.goHome();
                break;
              case 1:
                context.goHistory();
                break;
              case 2:
                context.goSettings();
                break;
            }
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
