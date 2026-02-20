import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/missing_person.dart';

class UrgencyBadge extends StatelessWidget {
  final UrgencyLevel urgency;
  final bool compact;

  const UrgencyBadge({
    super.key,
    required this.urgency,
    this.compact = false,
  });

  Color get badgeColor {
    switch (urgency) {
      case UrgencyLevel.critical:
        return AppColors.criticalRed;
      case UrgencyLevel.high:
        return AppColors.highOrange;
      case UrgencyLevel.normal:
        return AppColors.normalGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: badgeColor,
          width: 1.5,
        ),
      ),
      child: Text(
        urgency.label,
        style: (compact ? AppTextStyles.labelSmall : AppTextStyles.labelMedium).copyWith(
          color: badgeColor,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}
