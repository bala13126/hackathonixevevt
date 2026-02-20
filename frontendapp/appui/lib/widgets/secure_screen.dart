import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class SecureScreen extends StatelessWidget {
  final Widget child;
  final bool showBanner;

  const SecureScreen({
    super.key,
    required this.child,
    this.showBanner = true,
  });

  @override
  Widget build(BuildContext context) {
    // Note: Flutter web doesn't support screenshot blocking
    // This is a visual indicator only
    return Stack(
      children: [
        child,
        if (showBanner)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: AppColors.primary.withOpacity(0.9),
              child: const SafeArea(
                bottom: false,
                child: Row(
                  children: [
                    Icon(
                      Icons.security,
                      size: 16,
                      color: AppColors.white,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Screen capture disabled for privacy',
                        style: TextStyle(
                          color: AppColors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
