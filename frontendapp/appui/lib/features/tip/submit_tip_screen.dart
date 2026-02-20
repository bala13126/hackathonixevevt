import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';

class SubmitTipScreen extends StatefulWidget {
  final String caseId;

  const SubmitTipScreen({super.key, required this.caseId});

  @override
  State<SubmitTipScreen> createState() => _SubmitTipScreenState();
}

class _SubmitTipScreenState extends State<SubmitTipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  bool _isAnonymous = false;
  bool _shareLocation = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _submitTip() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tip submitted successfully. Thank you for helping!'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Submit Tip',
          style: AppTextStyles.headlineMedium,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppConstants.spacing24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Info Banner
              Container(
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(
                    color: AppColors.info.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: Text(
                        'Every tip matters. Please share any information that might help.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Message Input
              Text(
                'Your Information',
                style: AppTextStyles.headlineSmall,
              ),

              const SizedBox(height: AppConstants.spacing16),

              TextFormField(
                controller: _messageController,
                decoration: const InputDecoration(
                  labelText: 'Describe what you saw or know',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please provide some information';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing24),

              // Image Picker UI
              Text(
                'Add Photo (Optional)',
                style: AppTextStyles.headlineSmall,
              ),

              const SizedBox(height: AppConstants.spacing16),

              GestureDetector(
                onTap: () {},
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_a_photo,
                          size: 40,
                          color: AppColors.grey400,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Tap to add photo',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Options
              Text(
                'Options',
                style: AppTextStyles.headlineSmall,
              ),

              const SizedBox(height: AppConstants.spacing16),

              SwitchListTile(
                title: const Text('Share my location'),
                subtitle: const Text('Help investigators with location context'),
                value: _shareLocation,
                onChanged: (value) {
                  setState(() {
                    _shareLocation = value;
                  });
                },
                activeColor: AppColors.primary,
              ),

              SwitchListTile(
                title: const Text('Submit anonymously'),
                subtitle: const Text('Your identity will not be shared'),
                value: _isAnonymous,
                onChanged: (value) {
                  setState(() {
                    _isAnonymous = value;
                  });
                },
                activeColor: AppColors.primary,
              ),

              const SizedBox(height: AppConstants.spacing32),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _submitTip,
                  child: const Text('Submit Tip'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
