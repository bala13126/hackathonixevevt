import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/missing_person.dart';
import 'urgency_badge.dart';
import 'distance_chip.dart';
import 'verification_label.dart';

class MissingPersonCard extends StatelessWidget {
  final MissingPerson person;
  final VoidCallback? onTap;

  const MissingPersonCard({
    super.key,
    required this.person,
    this.onTap,
  });

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else {
      return '${difference.inDays}d ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(
          horizontal: AppConstants.spacing16,
          vertical: AppConstants.spacing8,
        ),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
          boxShadow: [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppConstants.radiusLarge),
              ),
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  person.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 48,
                          color: AppColors.grey400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            
            // Content
            Padding(
              padding: const EdgeInsets.all(AppConstants.spacing16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badges Row
                  Row(
                    children: [
                      UrgencyBadge(urgency: person.urgency, compact: true),
                      const SizedBox(width: 8),
                      VerificationLabel(isVerified: person.isVerified),
                      const Spacer(),
                      DistanceChip(distanceKm: person.distanceKm),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacing12),
                  
                  // Name and Age
                  Text(
                    '${person.name}, ${person.age}',
                    style: AppTextStyles.headlineMedium,
                  ),
                  
                  const SizedBox(height: AppConstants.spacing8),
                  
                  // Last Seen
                  Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          person.lastSeenLocation,
                          style: AppTextStyles.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: AppConstants.spacing4),
                  
                  // Time
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 16,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _getTimeAgo(person.lastSeenTime),
                        style: AppTextStyles.bodySmall,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
