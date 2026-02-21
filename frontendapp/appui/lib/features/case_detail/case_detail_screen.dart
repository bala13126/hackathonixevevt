import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../models/missing_person.dart';
import '../../widgets/urgency_badge.dart';
import '../../widgets/distance_chip.dart';
import '../../widgets/verification_label.dart';
import '../../widgets/secure_screen.dart';

class CaseDetailScreen extends StatelessWidget {
  final MissingPerson person;

  const CaseDetailScreen({super.key, required this.person});

  String _getTimeAgo(DateTime dateTime) {
    final difference = DateTime.now().difference(dateTime);
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SecureScreen(
      showBanner: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: CustomScrollView(
          slivers: [
            // Hero Image with App Bar
            SliverAppBar(
              expandedHeight: 400,
              pinned: true,
              backgroundColor: AppColors.white,
              leading: Container(
                margin: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppColors.white,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.arrow_back, color: AppColors.primary),
                  onPressed: () => Navigator.pop(context),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Image.network(
                  person.photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: AppColors.grey200,
                      child: const Center(
                        child: Icon(
                          Icons.person,
                          size: 100,
                          color: AppColors.grey400,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            // Content
            SliverToBoxAdapter(
              child: Container(
                color: AppColors.white,
                padding: const EdgeInsets.all(AppConstants.spacing24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badges Row
                    Wrap(
                      spacing: AppConstants.spacing8,
                      runSpacing: AppConstants.spacing8,
                      children: [
                        UrgencyBadge(urgency: person.urgency),
                        VerificationLabel(isVerified: person.isVerified),
                        DistanceChip(distanceKm: person.distanceKm),
                      ],
                    ),

                    const SizedBox(height: AppConstants.spacing20),

                    // Name and Age
                    Text(
                      '${person.name}, ${person.age}',
                      style: AppTextStyles.displayMedium,
                    ),

                    const SizedBox(height: AppConstants.spacing8),

                    // Status
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Status: ${person.status.label}',
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.accent,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Last Seen Card
            SliverToBoxAdapter(
              child: _buildInfoCard(
                context,
                'Last Seen',
                Icons.location_on,
                [
                  _buildInfoRow('Location', person.lastSeenLocation),
                  _buildInfoRow('Time', _getTimeAgo(person.lastSeenTime)),
                ],
              ),
            ),

            // Appearance Card
            SliverToBoxAdapter(
              child: _buildInfoCard(
                context,
                'Appearance',
                Icons.person_outline,
                [
                  _buildInfoRow('Height', '${person.height} cm'),
                  _buildInfoRow('Hair Color', person.hairColor),
                  _buildInfoRow('Eye Color', person.eyeColor),
                  _buildInfoRow('Clothing', person.clothing),
                ],
              ),
            ),

            // Description Card
            SliverToBoxAdapter(
              child: _buildInfoCard(
                context,
                'Description',
                Icons.description_outlined,
                [
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      person.description,
                      style: AppTextStyles.bodyMedium,
                    ),
                  ),
                ],
              ),
            ),

            // Contact Card
            SliverToBoxAdapter(
              child: _buildInfoCard(
                context,
                'Contact Information',
                Icons.contact_phone_outlined,
                [
                  _buildInfoRow('Contact', person.contactName),
                  _buildInfoRow('Phone', person.contactPhone),
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.shield_outlined,
                          size: 16,
                          color: AppColors.textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Privacy: ${person.privacyLevel.label}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Map Preview Card
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppConstants.spacing16),
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppConstants.radiusLarge),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 200,
                        color: AppColors.grey200,
                        child: const Center(
                          child: Icon(
                            Icons.map,
                            size: 64,
                            color: AppColors.grey400,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(AppConstants.spacing16),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.location_on,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Last seen area',
                                style: AppTextStyles.headlineSmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Timeline
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(AppConstants.spacing16),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.timeline,
                          color: AppColors.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Case Timeline',
                          style: AppTextStyles.headlineSmall,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppConstants.spacing16),
                    _buildTimelineItem(
                      'Report Submitted',
                      _getTimeAgo(person.lastSeenTime),
                      true,
                    ),
                    _buildTimelineItem(
                      'Under Investigation',
                      'Processing',
                      person.isVerified,
                    ),
                    _buildTimelineItem(
                      'Search Active',
                      'In Progress',
                      false,
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Padding
            const SliverToBoxAdapter(
              child: SizedBox(height: 100),
            ),
          ],
        ),

        // Found Missing Person Button
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(
              context,
              AppConstants.routeSubmitTip,
              arguments: person.id,
            );
          },
          icon: const Icon(Icons.tips_and_updates),
          label: const Text('Found Missing Person'),
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    String title,
    IconData icon,
    List<Widget> children,
  ) {
    return Container(
      margin: const EdgeInsets.all(AppConstants.spacing16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.headlineSmall,
              ),
            ],
          ),
          const SizedBox(height: AppConstants.spacing16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isCompleted ? AppColors.success : AppColors.grey300,
              shape: BoxShape.circle,
            ),
            child: isCompleted
                ? const Icon(
                    Icons.check,
                    size: 16,
                    color: AppColors.white,
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  time,
                  style: AppTextStyles.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
