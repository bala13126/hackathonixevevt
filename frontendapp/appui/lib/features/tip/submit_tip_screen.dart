import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../core/constants/app_constants.dart';
import '../../core/services/backend_api_service.dart';

class SubmitTipScreen extends StatefulWidget {
  final String caseId;

  const SubmitTipScreen({super.key, required this.caseId});

  @override
  State<SubmitTipScreen> createState() => _SubmitTipScreenState();
}

class _SubmitTipScreenState extends State<SubmitTipScreen> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _reporterNameController = TextEditingController();
  final _reporterContactController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();
  bool _isSubmitting = false;
  XFile? _attachment;
  final DateTime _capturedAt = DateTime.now();

  @override
  void dispose() {
    _descriptionController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _reporterNameController.dispose();
    _reporterContactController.dispose();
    super.dispose();
  }

  Future<void> _submitTip() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    final parsedCaseId = int.tryParse(widget.caseId);
    if (parsedCaseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid case id. Unable to submit tip.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final latitude = double.tryParse(_latitudeController.text.trim());
    final longitude = double.tryParse(_longitudeController.text.trim());
    if (latitude == null || longitude == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide valid sighting coordinates.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_attachment == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Photo evidence is required for sighting reports.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      await BackendApiService.submitSightingReport(
        caseId: parsedCaseId,
        description: _descriptionController.text.trim(),
        latitude: latitude,
        longitude: longitude,
        image: _attachment!,
        reporterName: _reporterNameController.text.trim(),
        reporterContact: _reporterContactController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Sighting report submitted. Status: Pending Review.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit tip: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }

  Future<void> _pickAttachment(ImageSource source) async {
    try {
      final selected = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (selected != null) {
        setState(() {
          _attachment = selected;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick image right now.')),
      );
    }
  }

  Future<void> _fillCoordinatesFromGps() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is needed to fetch GPS.'),
          ),
        );
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      _latitudeController.text = position.latitude.toStringAsFixed(6);
      _longitudeController.text = position.longitude.toStringAsFixed(6);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location captured.')),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch GPS location right now.')),
      );
    }
  }

  void _showPhotoSourceSheet() {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Capture photo'),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickAttachment(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
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
        title: Text('Public Sighting Report', style: AppTextStyles.headlineMedium),
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
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(
                    AppConstants.radiusMedium,
                  ),
                  border: Border.all(color: AppColors.info.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info_outline, color: AppColors.info),
                    const SizedBox(width: AppConstants.spacing12),
                    Expanded(
                      child: Text(
                        'Report what you observed. Your report will be linked to this case and marked Pending Review.',
                        style: AppTextStyles.bodySmall.copyWith(
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              Text('Observation', style: AppTextStyles.headlineSmall),

              const SizedBox(height: AppConstants.spacing16),

              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Describe what you observed',
                  alignLabelWithHint: true,
                ),
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Description is required';
                  }
                  return null;
                },
              ),

              const SizedBox(height: AppConstants.spacing24),

              Text('Photo Evidence', style: AppTextStyles.headlineSmall),

              const SizedBox(height: AppConstants.spacing16),

              GestureDetector(
                onTap: _showPhotoSourceSheet,
                child: Container(
                  height: 150,
                  decoration: BoxDecoration(
                    color: AppColors.grey100,
                    borderRadius: BorderRadius.circular(
                      AppConstants.radiusMedium,
                    ),
                    border: Border.all(
                      color: AppColors.border,
                      width: 2,
                      style: BorderStyle.solid,
                    ),
                  ),
                  child: Center(
                    child: _attachment == null
                        ? const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_a_photo,
                                size: 40,
                                color: AppColors.grey400,
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Tap to capture or upload photo',
                                style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: AppColors.success,
                                size: 28,
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _attachment!.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
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

              Text('Exact Location', style: AppTextStyles.headlineSmall),

              const SizedBox(height: AppConstants.spacing16),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _fillCoordinatesFromGps,
                      icon: const Icon(Icons.my_location),
                      label: const Text('Use GPS'),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing12),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _latitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Latitude'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: AppConstants.spacing12),
                  Expanded(
                    child: TextFormField(
                      controller: _longitudeController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                        signed: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Longitude'),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Required';
                        }
                        if (double.tryParse(value.trim()) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),

              const SizedBox(height: AppConstants.spacing24),

              Text('Reporter (Optional)', style: AppTextStyles.headlineSmall),

              const SizedBox(height: AppConstants.spacing16),

              TextFormField(
                controller: _reporterNameController,
                decoration: const InputDecoration(
                  labelText: 'Your name (optional)',
                ),
              ),

              const SizedBox(height: AppConstants.spacing12),

              TextFormField(
                controller: _reporterContactController,
                decoration: const InputDecoration(
                  labelText: 'Your contact (optional)',
                ),
              ),

              const SizedBox(height: AppConstants.spacing24),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppConstants.spacing16),
                decoration: BoxDecoration(
                  color: AppColors.grey100,
                  borderRadius: BorderRadius.circular(AppConstants.radiusMedium),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.schedule, color: AppColors.textSecondary),
                    const SizedBox(width: AppConstants.spacing8),
                    Expanded(
                      child: Text(
                        'Timestamp: ${_formatTimestamp(_capturedAt)}',
                        style: AppTextStyles.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppConstants.spacing32),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitTip,
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Submit Sighting Report'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
