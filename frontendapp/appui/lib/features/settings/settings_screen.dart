import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/glass_card.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = ThemeProvider.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark Mode'),
                  subtitle: const Text('Switch between light and dark theme'),
                  value: controller.isDarkMode,
                  onChanged: (_) => controller.toggleTheme(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Notifications'),
                  subtitle: const Text('Receive critical case updates'),
                  value: controller.notificationsEnabled,
                  onChanged: (_) => controller.toggleNotifications(),
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Text('Privacy Mode'),
                  subtitle: const Text('Hide sensitive details in public'),
                  value: controller.privacyMode,
                  onChanged: (_) => controller.togglePrivacyMode(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: ListTile(
              title: const Text('Language'),
              subtitle: const Text('English (United States)'),
              trailing: Icon(Icons.arrow_forward_ios, size: 16, color: AppColors.textSecondary),
              onTap: () {},
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: ListTile(
              title: const Text('Security'),
              subtitle: const Text('Screen capture disabled for privacy'),
              leading: Icon(Icons.shield_outlined, color: AppColors.accent),
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: ListTile(
              title: const Text('Logout'),
              subtitle: const Text('Sign out of your account'),
              leading: const Icon(Icons.logout, color: AppColors.textSecondary),
              onTap: () {
                Navigator.pushNamedAndRemoveUntil(
                  context,
                  AppConstants.routeLogin,
                  (route) => false,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
