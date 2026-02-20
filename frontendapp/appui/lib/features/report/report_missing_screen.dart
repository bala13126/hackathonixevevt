import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
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

  int _currentStep = 0;
  bool _isAutoFilling = false;
  bool _isVoiceFilling = false;
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
    setState(() {
      _isAutoFilling = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _nameController.text = 'Ananya Mehta';
    await _pulseField('name');

    await Future.delayed(const Duration(milliseconds: 300));
    _ageController.text = '26';
    await _pulseField('age');

    await Future.delayed(const Duration(milliseconds: 300));
    _heightController.text = '168';
    await _pulseField('height');

    await Future.delayed(const Duration(milliseconds: 300));
    _hairColorController.text = 'Black';
    await _pulseField('hair');

    await Future.delayed(const Duration(milliseconds: 300));
    _eyeColorController.text = 'Brown';
    await _pulseField('eye');

    await Future.delayed(const Duration(milliseconds: 300));
    _clothingController.text = 'Navy jacket, blue jeans';
    await _pulseField('clothing');

    await Future.delayed(const Duration(milliseconds: 300));
    _lastSeenLocationController.text = 'Andheri Station, Mumbai';
    await _pulseField('location');

    await Future.delayed(const Duration(milliseconds: 300));
    _lastSeenTimeController.text = 'Feb 19, 7:45 PM';
    await _pulseField('time');

    await Future.delayed(const Duration(milliseconds: 300));
    _descriptionController.text = 'Last seen near the ticket counter';
    await _pulseField('description');

    await Future.delayed(const Duration(milliseconds: 300));
    _contactNameController.text = 'Rahul Mehta';
    await _pulseField('contactName');

    await Future.delayed(const Duration(milliseconds: 300));
    _contactPhoneController.text = '9876543210';
    await _pulseField('contactPhone');

    setState(() {
      _isAutoFilling = false;
    });
  }

  Future<void> _autoFillWithVoice() async {
    setState(() {
      _isVoiceFilling = true;
    });

    await Future.delayed(const Duration(milliseconds: 400));
    _nameController.text = 'Karan Shah';
    await _pulseField('name');

    await Future.delayed(const Duration(milliseconds: 300));
    _ageController.text = '31';
    await _pulseField('age');

    await Future.delayed(const Duration(milliseconds: 300));
    _heightController.text = '175';
    await _pulseField('height');

    await Future.delayed(const Duration(milliseconds: 300));
    _hairColorController.text = 'Brown';
    await _pulseField('hair');

    await Future.delayed(const Duration(milliseconds: 300));
    _eyeColorController.text = 'Black';
    await _pulseField('eye');

    await Future.delayed(const Duration(milliseconds: 300));
    _clothingController.text = 'Grey hoodie, black jeans';
    await _pulseField('clothing');

    await Future.delayed(const Duration(milliseconds: 300));
    _lastSeenLocationController.text = 'Lower Parel, Mumbai';
    await _pulseField('location');

    await Future.delayed(const Duration(milliseconds: 300));
    _lastSeenTimeController.text = 'Feb 20, 9:10 AM';
    await _pulseField('time');

    await Future.delayed(const Duration(milliseconds: 300));
    _descriptionController.text = 'Reported by family; last seen outside the mall';
    await _pulseField('description');

    await Future.delayed(const Duration(milliseconds: 300));
    _contactNameController.text = 'Neha Shah';
    await _pulseField('contactName');

    await Future.delayed(const Duration(milliseconds: 300));
    _contactPhoneController.text = '9123456780';
    await _pulseField('contactPhone');

    setState(() {
      _isVoiceFilling = false;
    });
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

  void _submitReport() {
    if (_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Report submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pop(context);
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
      showBanner: true,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          title: const Text('Report Missing Person'),
          actions: [
            IconButton(
              tooltip: 'Voice Auto Fill',
              onPressed: _isVoiceFilling || _isAutoFilling ? null : _autoFillWithVoice,
              icon: _isVoiceFilling
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.mic_none),
            ),
            TextButton.icon(
              onPressed: _isAutoFilling || _isVoiceFilling ? null : _autoFillWithAI,
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
                      onPressed: details.onStepContinue,
                      child: Text(_currentStep == 3 ? 'Submit' : 'Next'),
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
                      decoration: const InputDecoration(labelText: 'Full Name'),
                      validator: (value) => value == null || value.isEmpty
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
                      decoration: const InputDecoration(labelText: 'Age'),
                      validator: (value) => value == null || value.isEmpty
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
                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => _selectedGender = value);
                        }
                      },
                      decoration: const InputDecoration(labelText: 'Gender'),
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
                  _buildAnimatedField(
                    fieldKey: 'height',
                    child: TextFormField(
                      controller: _heightController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Height (cm)'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedField(
                    fieldKey: 'hair',
                    child: TextFormField(
                      controller: _hairColorController,
                      decoration: const InputDecoration(labelText: 'Hair Color'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedField(
                    fieldKey: 'eye',
                    child: TextFormField(
                      controller: _eyeColorController,
                      decoration: const InputDecoration(labelText: 'Eye Color'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedField(
                    fieldKey: 'clothing',
                    child: TextFormField(
                      controller: _clothingController,
                      decoration: const InputDecoration(labelText: 'Clothing'),
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
                      decoration: const InputDecoration(labelText: 'Last Seen Location'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedField(
                    fieldKey: 'time',
                    child: TextFormField(
                      controller: _lastSeenTimeController,
                      decoration: const InputDecoration(labelText: 'Last Seen Time'),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildAnimatedField(
                    fieldKey: 'description',
                    child: TextFormField(
                      controller: _descriptionController,
                      maxLines: 3,
                      decoration: const InputDecoration(labelText: 'Additional Details'),
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
                      decoration: const InputDecoration(labelText: 'Contact Name'),
                      validator: (value) => value == null || value.isEmpty
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
                      decoration: const InputDecoration(labelText: 'Contact Phone'),
                      validator: (value) => value == null || value.isEmpty
                          ? 'Contact phone is required'
                          : null,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Privacy Level', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: RadioListTile<PrivacyLevel>(
                              value: PrivacyLevel.public,
                              groupValue: _selectedPrivacy,
                              onChanged: (value) {
                                if (value != null) {
                                  setState(() => _selectedPrivacy = value);
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
                                  setState(() => _selectedPrivacy = value);
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
