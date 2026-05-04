import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:furspeak_ai/services/auth_service.dart';
import 'package:furspeak_ai/presentation/screens/guest_mode_warning_screen.dart';
import 'package:furspeak_ai/config/app_routes.dart';
import 'package:furspeak_ai/config/app_theme.dart';

class RootNavShell extends StatelessWidget {
  final StatefulNavigationShell navigationShell;

  const RootNavShell({
    super.key,
    required this.navigationShell,
  });

  Future<bool> _showExitDialog(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Icon(Icons.pets, color: AppTheme.primaryColor, size: 28),
                const SizedBox(width: 10),
                Text('Exit App', style: AppTheme.titleStyle),
              ],
            ),
            content: Text(
              'Are you sure you want to leave?',
              style: AppTheme.bodyStyle,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text('Cancel',
                    style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text('Exit',
                    style: TextStyle(color: AppTheme.errorColor)),
              ),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final authService = AuthService();
    final isGuest = authService.isGuest;
    final currentIndex = navigationShell.currentIndex;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (currentIndex != 0) {
          navigationShell.goBranch(0);
          return;
        }
        final shouldExit = await _showExitDialog(context);
        if (shouldExit) {
          // Allow the system to handle exit
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: NavigationBar(
          backgroundColor: AppTheme.bgColor,
          indicatorColor: AppTheme.primaryColor.withOpacity(0.08),
          selectedIndex: currentIndex,
          onDestinationSelected: (index) {
            if (isGuest && (index == 1 || index == 2)) {
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (context) => GuestModeWarningScreen(
                  onContinue: () {
                    Navigator.pop(context);
                    navigationShell.goBranch(0);
                  },
                  onSignIn: () {
                    Navigator.pop(context);
                    context.goWelcome();
                  },
                ),
              );
            } else {
              navigationShell.goBranch(
                index,
                initialLocation: index == navigationShell.currentIndex,
              );
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
      ),
    );
  }
}
