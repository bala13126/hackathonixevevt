import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../widgets/glass_card.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.pushNamed(context, AppConstants.routeSettings);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          GlassCard(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 40,
                  backgroundColor: AppColors.accent.withOpacity(0.1),
                  child: Icon(Icons.person, size: 40, color: AppColors.accent),
                ),
                const SizedBox(height: 12),
                Text(
                  'Profile not set',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                Text(
                  'Add your details to personalize ResQLink',
                  style: TextStyle(color: AppColors.textSecondary),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Honour Panel',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('0', 'Honour Score'),
                    _buildStatItem('0', 'Rescues'),
                    _buildStatItem('None', 'Badge'),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Progress to Next Badge'),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: 0.0,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation(AppColors.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Certificates'),
          GlassCard(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(Icons.verified_outlined, color: AppColors.textSecondary),
              title: const Text(
                'No certificates yet',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text('Complete trainings to earn certificates', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Medals'),
          GlassCard(
            child: ListTile(
              leading: Icon(Icons.emoji_events_outlined, color: AppColors.textSecondary),
              title: const Text('No medals yet', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Contribute to cases to earn medals', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 24),
          _buildSectionTitle('Contribution History'),
          GlassCard(
            child: ListTile(
              leading: Icon(Icons.history, color: AppColors.textSecondary),
              title: const Text('No contributions yet', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Your activity will show up here', style: TextStyle(color: AppColors.textSecondary)),
            ),
          ),
          const SizedBox(height: 24),
          GlassCard(
            child: ListTile(
              leading: const Icon(Icons.logout, color: AppColors.textSecondary),
              title: const Text('Logout', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
