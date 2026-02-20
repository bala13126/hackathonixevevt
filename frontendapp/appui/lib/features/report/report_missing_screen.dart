import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_colors.dart';
import '../../core/services/backend_api_service.dart';
import '../../models/missing_person.dart';
import '../../widgets/secure_screen.dart';

class ReportMissingScreen extends StatefulWidget {
  const ReportMissingScreen({super.key});

  @override
  State<ReportMissingScreen> createState() => _ReportMissingScreenState();
}

class _ReportMissingScreenState extends State<ReportMissingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ageController = TextEditingController();
  final _heightController = TextEditingController();
  final _hairColorController = TextEditingController();
  final _eyeColorController = TextEditingController();
  final _clothingController = TextEditingController();
  final _lastSeenLocationController = TextEditingController();
  final _lastSeenTimeController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactNameController = TextEditingController();
  final _contactPhoneController = TextEditingController();
  final ImagePicker _imagePicker = ImagePicker();

  int _currentStep = 0;
  bool _isAutoFilling = false;
  bool _isSubmitting = false;
  XFile? _selectedPhoto;
  PrivacyLevel _selectedPrivacy = PrivacyLevel.protected;
  String _selectedGender = 'Female';
  String? _highlightField;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _hairColorController.dispose();
    _eyeColorController.dispose();
    _clothingController.dispose();
    _lastSeenLocationController.dispose();
    _lastSeenTimeController.dispose();
    _descriptionController.dispose();
    _contactNameController.dispose();
    _contactPhoneController.dispose();
    super.dispose();
  }

  Future<void> _autoFillWithAI() async {
    if (_isAutoFilling) return;
    setState(() {
      _isAutoFilling = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('latest_voice_details');
      final latestText = prefs.getString('latest_voice_text') ?? '';
      if ((raw == null || raw.trim().isEmpty) && latestText.trim().isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No AI assistant details found yet.'),
            ),
          );
        }
        return;
      }

      final decoded = raw == null || raw.trim().isEmpty
          ? <String, dynamic>{}
          : jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        if ((decoded['description'] ?? '').toString().trim().isEmpty &&
            latestText.trim().isNotEmpty) {
          decoded['description'] = latestText.trim();
        }
        await _applyParsedFields(decoded);
        if (_lastSeenLocationController.text.trim().isEmpty) {
          await _fillLocationFromDevice();
        }
      }
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Auto fill failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isAutoFilling = false;
        });
      }
    }
  }

  Future<void> _applyParsedFields(Map<String, dynamic> parsed) async {
    final name = (parsed['name'] ?? '').toString();
    if (name.isNotEmpty) {
      _nameController.text = name;
      await _pulseField('name');
    }

    final age = (parsed['age'] ?? '').toString();
    if (age.isNotEmpty) {
      _ageController.text = age;
      await _pulseField('age');
    }

    final height = (parsed['height'] ?? '').toString();
    if (height.isNotEmpty) {
      _heightController.text = height;
      await _pulseField('height');
    }

    final hair = (parsed['hairColor'] ?? '').toString();
    if (hair.isNotEmpty) {
      _hairColorController.text = hair;
      await _pulseField('hair');
    }

    final eye = (parsed['eyeColor'] ?? '').toString();
    if (eye.isNotEmpty) {
      _eyeColorController.text = eye;
      await _pulseField('eye');
    }

    final clothing = (parsed['clothing'] ?? '').toString();
    if (clothing.isNotEmpty) {
      _clothingController.text = clothing;
      await _pulseField('clothing');
    }

    final location = (parsed['lastSeenLocation'] ?? '').toString();
    if (location.isNotEmpty) {
      _lastSeenLocationController.text = location;
      await _pulseField('location');
    }

    final timeValue = (parsed['lastSeenTime'] ?? '').toString();
    if (timeValue.isNotEmpty) {
      _lastSeenTimeController.text = timeValue;
      await _pulseField('time');
    }

    final description = (parsed['description'] ?? '').toString();
    if (description.isNotEmpty) {
      _descriptionController.text = description;
      await _pulseField('description');
    }

    final contactName = (parsed['contactName'] ?? '').toString();
    if (contactName.isNotEmpty) {
      _contactNameController.text = contactName;
      await _pulseField('contactName');
    }

    final contactPhone = (parsed['contactPhone'] ?? '').toString();
    if (contactPhone.isNotEmpty) {
      _contactPhoneController.text = contactPhone;
      await _pulseField('contactPhone');
    }

    final gender = (parsed['gender'] ?? '').toString();
    if (gender.isNotEmpty) {
      setState(() {
        _selectedGender = gender;
      });
      await _pulseField('gender');
    }
  }

  Future<void> _pulseField(String fieldKey) async {
    if (!mounted) return;
    setState(() {
      _highlightField = fieldKey;
    });
    await Future.delayed(const Duration(milliseconds: 220));
    if (!mounted) return;
    setState(() {
      _highlightField = null;
    });
  }

  Future<void> _fillLocationFromDevice() async {
    try {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Location permission is needed to auto-fill location.'),
            ),
          );
        }
        return;
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );

      String location = '';
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final parts = [
          place.subLocality,
          place.locality,
          place.administrativeArea,
          place.country,
        ].where((part) => part != null && part!.trim().isNotEmpty);
        location = parts.map((part) => part!.trim()).join(', ');
      }

      if (location.isEmpty) {
        location =
            '${position.latitude.toStringAsFixed(5)}, ${position.longitude.toStringAsFixed(5)}';
      }

      _lastSeenLocationController.text = location;
      await _pulseField('location');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to fetch device location.')),
      );
    }
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final picked = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _selectedPhoto = picked;
        });
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unable to pick photo right now.')),
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
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Upload from gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () {
                Navigator.pop(context);
                _pickPhoto(ImageSource.camera);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final createdCase = await BackendApiService.createCase(
        name: _nameController.text.trim(),
        age: int.tryParse(_ageController.text.trim()) ?? 0,
        location: _lastSeenLocationController.text.trim(),
        description: _descriptionController.text.trim(),
        urgency: UrgencyLevel.high,
        photo: _selectedPhoto,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context, createdCase);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to submit report: $error'),
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

  void _continueStep() {
    if (_currentStep < 3) {
      setState(() {
        _currentStep += 1;
      });
    } else {
      _submitReport();
    }
  }

  void _backStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep -= 1;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SecureScreen(
      showBanner: false,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Text('Report Missing Person'),
          actions: [
            TextButton.icon(
              onPressed: _isAutoFilling ? null : _autoFillWithAI,
              icon: _isAutoFilling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.auto_awesome, size: 18),
              label: Text(_isAutoFilling ? 'Filling' : 'Auto Fill'),
            ),
            const SizedBox(width: 8),
          ],
        ),
        body: Form(
          key: _formKey,
          child: Column(
            children: [
              Expanded(
                child: Stepper(
                  currentStep: _currentStep,
                  onStepContinue: _continueStep,
                  onStepCancel: _backStep,
                  controlsBuilder: (context, details) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Row(
                        children: [
                          ElevatedButton(
                            onPressed: _isSubmitting
                                ? null
                                : details.onStepContinue,
                            child: _isSubmitting
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(_currentStep == 3 ? 'Submit' : 'Next'),
                          ),
                          const SizedBox(width: 12),
                          if (_currentStep > 0)
                            TextButton(
                              onPressed: details.onStepCancel,
                              child: const Text('Back'),
                            ),
                        ],
                      ),
                    );
                  },
                  steps: [
                    Step(
                      title: const Text('Basic Info'),
                      isActive: _currentStep >= 0,
                      content: Column(
                        children: [
                          _buildAnimatedField(
                            fieldKey: 'name',
                            child: TextFormField(
                              controller: _nameController,
                              decoration: const InputDecoration(
                                labelText: 'Full Name',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Name is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'age',
                            child: TextFormField(
                              controller: _ageController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Age',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Age is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'gender',
                            child: DropdownButtonFormField<String>(
                              value: _selectedGender,
                              items: const [
                                DropdownMenuItem(
                                  value: 'Female',
                                  child: Text('Female'),
                                ),
                                DropdownMenuItem(
                                  value: 'Male',
                                  child: Text('Male'),
                                ),
                                DropdownMenuItem(
                                  value: 'Other',
                                  child: Text('Other'),
                                ),
                              ],
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedGender = value);
                                }
                              },
                              decoration: const InputDecoration(
                                labelText: 'Gender',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Appearance'),
                      isActive: _currentStep >= 1,
                      content: Column(
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _showPhotoSourceSheet,
                                  icon: const Icon(Icons.upload_outlined),
                                  label: Text(
                                    _selectedPhoto == null
                                        ? 'Upload Photo'
                                        : 'Change Photo',
                                  ),
                                ),
                              ),
                              if (_selectedPhoto != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  tooltip: 'Remove photo',
                                  onPressed: () {
                                    setState(() {
                                      _selectedPhoto = null;
                                    });
                                  },
                                  icon: const Icon(Icons.delete_outline),
                                ),
                              ],
                            ],
                          ),
                          if (_selectedPhoto != null) ...[
                            const SizedBox(height: 12),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                _selectedPhoto!.path,
                                height: 180,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) =>
                                    Container(
                                      height: 180,
                                      width: double.infinity,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: AppColors.info.withOpacity(0.08),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: AppColors.info.withOpacity(
                                            0.25,
                                          ),
                                        ),
                                      ),
                                      child: const Text(
                                        'Photo preview unavailable',
                                      ),
                                    ),
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          _buildAnimatedField(
                            fieldKey: 'height',
                            child: TextFormField(
                              controller: _heightController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Height (cm)',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'hair',
                            child: TextFormField(
                              controller: _hairColorController,
                              decoration: const InputDecoration(
                                labelText: 'Hair Color',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'eye',
                            child: TextFormField(
                              controller: _eyeColorController,
                              decoration: const InputDecoration(
                                labelText: 'Eye Color',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'clothing',
                            child: TextFormField(
                              controller: _clothingController,
                              decoration: const InputDecoration(
                                labelText: 'Clothing',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Last Seen'),
                      isActive: _currentStep >= 2,
                      content: Column(
                        children: [
                          _buildAnimatedField(
                            fieldKey: 'location',
                            child: TextFormField(
                              controller: _lastSeenLocationController,
                              decoration: const InputDecoration(
                                labelText: 'Last Seen Location',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'time',
                            child: TextFormField(
                              controller: _lastSeenTimeController,
                              decoration: const InputDecoration(
                                labelText: 'Last Seen Time',
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'description',
                            child: TextFormField(
                              controller: _descriptionController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Additional Details',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Step(
                      title: const Text('Contact'),
                      isActive: _currentStep >= 3,
                      content: Column(
                        children: [
                          _buildAnimatedField(
                            fieldKey: 'contactName',
                            child: TextFormField(
                              controller: _contactNameController,
                              decoration: const InputDecoration(
                                labelText: 'Contact Name',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Contact name is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          _buildAnimatedField(
                            fieldKey: 'contactPhone',
                            child: TextFormField(
                              controller: _contactPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(
                                labelText: 'Contact Phone',
                              ),
                              validator: (value) =>
                                  value == null || value.isEmpty
                                  ? 'Contact phone is required'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Privacy Level',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: RadioListTile<PrivacyLevel>(
                                      value: PrivacyLevel.public,
                                      groupValue: _selectedPrivacy,
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedPrivacy = value,
                                          );
                                        }
                                      },
                                      title: const Text('Public'),
                                    ),
                                  ),
                                  Expanded(
                                    child: RadioListTile<PrivacyLevel>(
                                      value: PrivacyLevel.protected,
                                      groupValue: _selectedPrivacy,
                                      onChanged: (value) {
                                        if (value != null) {
                                          setState(
                                            () => _selectedPrivacy = value,
                                          );
                                        }
                                      },
                                      title: const Text('Protected'),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAnimatedField({
    required String fieldKey,
    required Widget child,
  }) {
    final isHighlighted = _highlightField == fieldKey;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighlighted ? AppColors.accent : Colors.transparent,
          width: 2,
        ),
      ),
      child: child,
    );
  }
}
