import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/missing_person.dart';

class CaseTrackingScreen extends StatelessWidget {
  const CaseTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Case Tracking',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Case Info Card
            Container(
              padding: const EdgeInsets.all(AppConstants.spacing20),
              decoration: BoxDecoration(
                color: AppColors.white,
                borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.shadow,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    child: Image.network(
                      'https://i.pravatar.cc/100?img=1',
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sarah Johnson, 14',
                          style: AppTextStyles.headlineSmall,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Case #12345',
                          style: AppTextStyles.labelSmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppConstants.spacing32),

            // Timeline
            Text(
              'Progress Timeline',
              style: AppTextStyles.headlineMedium,
            ),

            const SizedBox(height: AppConstants.spacing24),

            _buildTimelineStep(
              CaseStatus.submitted,
              'Report Submitted',
              '2 hours ago',
              'Case report has been received',
              isCompleted: true,
              isActive: false,
            ),

            _buildTimelineStep(
              CaseStatus.verified,
              'Verified',
              '1 hour ago',
              'Information verified by authorities',
              isCompleted: true,
              isActive: false,
            ),

            _buildTimelineStep(
              CaseStatus.active,
              'Search Active',
              'In Progress',
              'Local community and authorities are searching',
              isCompleted: false,
              isActive: true,
            ),

            _buildTimelineStep(
              CaseStatus.found,
              'Person Found',
              'Pending',
              'Waiting for resolution',
              isCompleted: false,
              isActive: false,
            ),

            _buildTimelineStep(
              CaseStatus.archived,
              'Case Closed',
              'Pending',
              'Case will be archived after resolution',
              isCompleted: false,
              isActive: false,
              isLast: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimelineStep(
    CaseStatus status,
    String title,
    String time,
    String description, {
    required bool isCompleted,
    required bool isActive,
    bool isLast = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: isCompleted
                    ? AppColors.success
                    : isActive
                        ? AppColors.accent
                        : AppColors.grey300,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isActive ? AppColors.accent : Colors.transparent,
                  width: 3,
                ),
              ),
              child: Icon(
                isCompleted
                    ? Icons.check
                    : isActive
                        ? Icons.pending
                        : Icons.circle_outlined,
                size: 20,
                color: AppColors.white,
              ),
            ),
            if (!isLast)
              Container(
                width: 2,
                height: 60,
                color: isCompleted ? AppColors.success : AppColors.grey300,
              ),
          ],
        ),
        const SizedBox(width: AppConstants.spacing16),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(AppConstants.spacing16),
            margin: const EdgeInsets.only(bottom: AppConstants.spacing16),
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.accent.withOpacity(0.05)
                  : AppColors.white,
              borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
              border: Border.all(
                color: isActive
                    ? AppColors.accent.withOpacity(0.3)
                    : AppColors.border,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: AppTextStyles.headlineSmall.copyWith(
                        color: isActive ? AppColors.accent : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      time,
                      style: AppTextStyles.labelSmall,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
