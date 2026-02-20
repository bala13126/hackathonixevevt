import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/country.dart';
import 'country_picker.dart';

class PhoneInput extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const PhoneInput({
    super.key,
    required this.controller,
    this.validator,
  });

  @override
  State<PhoneInput> createState() => _PhoneInputState();
}

class _PhoneInputState extends State<PhoneInput> {
  Country _selectedCountry = Country.defaultCountry;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CountryPickerWidget(
          selectedCountry: _selectedCountry,
          onCountryChanged: (country) {
            setState(() {
              _selectedCountry = country;
            });
          },
        ),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: widget.controller,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(_selectedCountry.maxLength),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone Number',
              hintText: 'Enter phone number',
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Phone number is required';
              }
              if (value.length != _selectedCountry.maxLength) {
                return 'Must be ${_selectedCountry.maxLength} digits';
              }
              return widget.validator?.call(value);
            },
          ),
        ),
      ],
    );
  }
}
