import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class LocationPermissionScreen extends StatelessWidget {
  const LocationPermissionScreen({super.key});

  void _handleAllowLocation(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppConstants.routeHome);
  }

  void _handleSkip(BuildContext context) {
    Navigator.pushReplacementNamed(context, AppConstants.routeHome);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.spacing24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // Illustration/Icon
              Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on,
                  size: 100,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: AppConstants.spacing48),

              // Title
              Text(
                'Enable Location Access',
                style: AppTextStyles.displayMedium.copyWith(
                  color: AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.spacing16),

              // Description
              Text(
                'ResQLink uses geo-priority to show you missing persons cases near your location. This helps reunite families faster.',
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Features
              _buildFeatureItem(
                Icons.notifications_active,
                'Priority Alerts',
                'Get notified about urgent cases nearby',
              ),
              const SizedBox(height: AppConstants.spacing16),
              _buildFeatureItem(
                Icons.map,
                'Distance Tracking',
                'See how far missing persons were last seen',
              ),
              const SizedBox(height: AppConstants.spacing16),
              _buildFeatureItem(
                Icons.security,
                'Privacy Protected',
                'Your location is never shared publicly',
              ),

              const Spacer(),

              // Allow Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => _handleAllowLocation(context),
                  child: const Text('Allow Location'),
                ),
              ),

              const SizedBox(height: AppConstants.spacing16),

              // Skip Button
              TextButton(
                onPressed: () => _handleSkip(context),
                child: Text(
                  'Skip for now',
                  style: AppTextStyles.labelLarge.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacing24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeatureItem(IconData icon, String title, String description) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
          ),
          child: Icon(
            icon,
            color: AppColors.accent,
            size: 24,
          ),
        ),
        const SizedBox(width: AppConstants.spacing16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.headlineSmall,
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: AppTextStyles.bodySmall,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
