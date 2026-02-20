import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../widgets/glass_card.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSectionTitle('Urgent Alerts'),
          _buildEmptyItem('No urgent alerts right now'),
          const SizedBox(height: 20),
          _buildSectionTitle('Case Updates'),
          _buildEmptyItem('No case updates yet'),
          const SizedBox(height: 20),
          _buildSectionTitle('System Updates'),
          _buildEmptyItem('No system updates available'),
          const SizedBox(height: 20),
          _buildSectionTitle('Achievement Alerts'),
          _buildEmptyItem('No achievements yet'),
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

  Widget _buildEmptyItem(String message) {
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          const Icon(Icons.notifications_none, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
