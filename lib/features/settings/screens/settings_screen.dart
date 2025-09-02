import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'company_settings_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 24),
              _buildBusinessSection(context),
              const SizedBox(height: 16),
              _buildPreferencesSection(context),
              const SizedBox(height: 16),
              _buildAboutSection(context),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue.shade600,
            Colors.blue.shade800,
          ],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(
              Icons.settings,
              color: Colors.white,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Settings & Configuration',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Customize your invoice app',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context) {
    return _buildSection(
      'Business',
      Icons.business,
      Colors.green,
      [
        _buildSettingsTile(
          context,
          title: 'Company Information',
          subtitle: 'Update your business details, logo, and contact info',
          icon: Icons.business_center,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CompanySettingsScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Invoice Templates',
          subtitle: 'Customize your invoice layout and branding',
          icon: Icons.receipt_long,
          onTap: () => _showComingSoon(context, 'Invoice Templates'),
        ),
        _buildSettingsTile(
          context,
          title: 'Tax Settings',
          subtitle: 'Configure tax rates and calculations',
          icon: Icons.calculate,
          onTap: () => _showComingSoon(context, 'Tax Settings'),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return _buildSection(
      'Preferences',
      Icons.tune,
      Colors.blue,
      [
        _buildSettingsTile(
          context,
          title: 'Currency & Format',
          subtitle: 'Set default currency and number formats',
          icon: Icons.attach_money,
          onTap: () => _showComingSoon(context, 'Currency Settings'),
        ),
        _buildSettingsTile(
          context,
          title: 'Notifications',
          subtitle: 'Configure email and push notifications',
          icon: Icons.notifications,
          onTap: () => _showComingSoon(context, 'Notification Settings'),
        ),
        _buildSettingsTile(
          context,
          title: 'Backup & Sync',
          subtitle: 'Manage data backup and cloud synchronization',
          icon: Icons.cloud_sync,
          onTap: () => _showComingSoon(context, 'Backup Settings'),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      'About',
      Icons.info,
      Colors.orange,
      [
        _buildSettingsTile(
          context,
          title: 'App Version',
          subtitle: 'Version 1.0.0',
          icon: Icons.info_outline,
          showArrow: false,
          onTap: null,
        ),
        _buildSettingsTile(
          context,
          title: 'Help & Support',
          subtitle: 'Get help and contact support',
          icon: Icons.help_outline,
          onTap: () => _showComingSoon(context, 'Help & Support'),
        ),
        _buildSettingsTile(
          context,
          title: 'Privacy Policy',
          subtitle: 'Review our privacy policy',
          icon: Icons.privacy_tip_outlined,
          onTap: () => _showComingSoon(context, 'Privacy Policy'),
        ),
      ],
    );
  }

  Widget _buildSection(String title, IconData icon, Color color, List<Widget> children) {
    return Card(
      elevation: 2,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: _getDarkerColor(color),
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    bool showArrow = true,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.grey.shade600, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontWeight: FontWeight.w500,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 12,
        ),
      ),
      trailing: showArrow ? const Icon(Icons.chevron_right) : null,
      onTap: onTap,
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.orange,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    final hsl = HSLColor.fromColor(color);
    return hsl.withLightness(0.3).toColor();
  }
}