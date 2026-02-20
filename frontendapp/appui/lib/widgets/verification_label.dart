import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';

class VerificationLabel extends StatelessWidget {
  final bool isVerified;

  const VerificationLabel({
    super.key,
    required this.isVerified,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: isVerified
            ? AppColors.success.withOpacity(0.1)
            : AppColors.warning.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isVerified ? AppColors.success : AppColors.warning,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVerified ? Icons.verified : Icons.schedule,
            size: 14,
            color: isVerified ? AppColors.success : AppColors.warning,
          ),
          const SizedBox(width: 4),
          Text(
            isVerified ? 'Verified' : 'Under Verification',
            style: AppTextStyles.labelSmall.copyWith(
              color: isVerified ? AppColors.success : AppColors.warning,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
