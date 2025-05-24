import 'package:flutter/material.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const CircleAvatar(
            radius: 50,
            child: Icon(Icons.person, size: 50),
          ),
          const SizedBox(height: 16),
          const Text(
            'User Name',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          _buildSection(
            context,
            'Account',
            [
              _buildListTile(
                context,
                'Edit Profile',
                Icons.edit,
                () {
                  // TODO: Implement edit profile
                },
              ),
              _buildListTile(
                context,
                'Change Password',
                Icons.lock,
                () {
                  // TODO: Implement change password
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'Preferences',
            [
              _buildListTile(
                context,
                'Notifications',
                Icons.notifications,
                () {
                  // TODO: Implement notifications settings
                },
              ),
              _buildListTile(
                context,
                'Language',
                Icons.language,
                () {
                  // TODO: Implement language settings
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildSection(
            context,
            'About',
            [
              _buildListTile(
                context,
                'Terms of Service',
                Icons.description,
                () {
                  // TODO: Show terms of service
                },
              ),
              _buildListTile(
                context,
                'Privacy Policy',
                Icons.privacy_tip,
                () {
                  // TODO: Show privacy policy
                },
              ),
              _buildListTile(
                context,
                'Version 1.0.0',
                Icons.info,
                null,
              ),
            ],
          ),
          const SizedBox(height: 32),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              onPressed: () {
                // TODO: Implement logout
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Logout'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(
      BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Theme.of(context).primaryColor,
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
        Card(
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildListTile(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap,
  ) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: onTap != null ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }
}
