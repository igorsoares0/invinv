import 'package:flutter/material.dart';
import 'company_settings_screen.dart';
import 'invoice_templates_screen.dart';
import '../../../shared/services/simple_subscription_service.dart';
import '../../../shared/models/models.dart';
import '../../subscription/screens/paywall_screen.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Settings',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        toolbarHeight: 80,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 16),
              _buildSubscriptionSection(context),
              const SizedBox(height: 20),
              _buildBusinessSection(context),
              const SizedBox(height: 20),
              _buildPreferencesSection(context),
              const SizedBox(height: 20),
              _buildAboutSection(context),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubscriptionSection(BuildContext context) {
    return StreamBuilder<SubscriptionStatus>(
      stream: SimpleSubscriptionService().statusStream,
      builder: (context, snapshot) {
        final status = snapshot.data;

        return _buildSection(
          'Subscription',
          Icons.star_outline,
          [
            _buildSubscriptionTile(context, status),
          ],
        );
      },
    );
  }

  Widget _buildSubscriptionTile(BuildContext context, SubscriptionStatus? status) {
    final isPremium = status?.isPremium ?? false;
    final statusText = status?.statusText ?? 'Loading...';

    String title = isPremium ? 'Premium Plan' : 'Free Plan';
    String subtitle = statusText;
    Color backgroundColor = isPremium ? Colors.amber.shade50 : Colors.grey.shade50;
    Color borderColor = isPremium ? Colors.amber.shade200 : Colors.grey.shade200;
    IconData iconData = isPremium ? Icons.star : Icons.star_outline;
    Color iconColor = isPremium ? Colors.amber.shade700 : Colors.grey.shade600;

    if (!isPremium && status != null) {
      final remaining = status.remainingFreeInvoices;
      if (remaining >= 0) {
        subtitle = '$remaining free invoices remaining';
      }
    }

    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: isPremium ? Colors.amber.shade100 : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            iconData,
            color: iconColor,
            size: 20,
          ),
        ),
        title: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isPremium ? Colors.amber.shade800 : Colors.black87,
              ),
            ),
            if (isPremium) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  'ACTIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 14,
                color: isPremium ? Colors.amber.shade700 : Colors.grey.shade600,
              ),
            ),
            if (!isPremium) ...[
              const SizedBox(height: 8),
              Text(
                'Upgrade for unlimited invoices, no watermark, and premium features',
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
        trailing: isPremium
            ? null
            : Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                  'Upgrade',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        onTap: isPremium ? null : () async {
          await Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const PaywallScreen(),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBusinessSection(BuildContext context) {
    return _buildSection(
      'Business',
      Icons.business_outlined,
      [
        _buildSettingsTile(
          context,
          title: 'Company Information',
          subtitle: 'Update your business details, logo, and contact info',
          icon: Icons.business_center_outlined,
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
          icon: Icons.receipt_long_outlined,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const InvoiceTemplatesScreen(),
            ),
          ),
        ),
        _buildSettingsTile(
          context,
          title: 'Tax Settings',
          subtitle: 'Configure tax rates and calculations',
          icon: Icons.calculate_outlined,
          onTap: () => _showComingSoon(context, 'Tax Settings'),
        ),
      ],
    );
  }

  Widget _buildPreferencesSection(BuildContext context) {
    return _buildSection(
      'Preferences',
      Icons.tune_outlined,
      [
        _buildSettingsTile(
          context,
          title: 'Currency & Format',
          subtitle: 'Set default currency and number formats',
          icon: Icons.attach_money_outlined,
          onTap: () => _showComingSoon(context, 'Currency Settings'),
        ),
        _buildSettingsTile(
          context,
          title: 'Notifications',
          subtitle: 'Configure email and push notifications',
          icon: Icons.notifications_outlined,
          onTap: () => _showComingSoon(context, 'Notification Settings'),
        ),
        _buildSettingsTile(
          context,
          title: 'Backup & Sync',
          subtitle: 'Manage data backup and cloud synchronization',
          icon: Icons.cloud_sync_outlined,
          onTap: () => _showComingSoon(context, 'Backup Settings'),
        ),
      ],
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return _buildSection(
      'About',
      Icons.info_outline,
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

  Widget _buildSection(String title, IconData icon, List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: Colors.grey.shade600,
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: Colors.grey.shade600,
            size: 20,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey.shade600,
          ),
        ),
        trailing: showArrow 
            ? Icon(
                Icons.chevron_right,
                color: Colors.grey.shade400,
              )
            : null,
        onTap: onTap,
      ),
    );
  }

  void _showComingSoon(BuildContext context, String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature - Coming Soon!'),
        backgroundColor: Colors.blue,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}