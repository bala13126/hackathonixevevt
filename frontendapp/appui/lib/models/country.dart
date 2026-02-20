class Country {
  final String name;
  final String code;
  final String dialCode;
  final String flag;
  final int maxLength;

  Country({
    required this.name,
    required this.code,
    required this.dialCode,
    required this.flag,
    required this.maxLength,
  });

  static List<Country> countries = [
    Country(name: 'United States', code: 'US', dialCode: '+1', flag: 'US', maxLength: 10),
    Country(name: 'India', code: 'IN', dialCode: '+91', flag: 'IN', maxLength: 10),
    Country(name: 'United Kingdom', code: 'GB', dialCode: '+44', flag: 'GB', maxLength: 10),
    Country(name: 'Canada', code: 'CA', dialCode: '+1', flag: 'CA', maxLength: 10),
    Country(name: 'Australia', code: 'AU', dialCode: '+61', flag: 'AU', maxLength: 9),
    Country(name: 'Germany', code: 'DE', dialCode: '+49', flag: 'DE', maxLength: 11),
    Country(name: 'France', code: 'FR', dialCode: '+33', flag: 'FR', maxLength: 9),
    Country(name: 'Japan', code: 'JP', dialCode: '+81', flag: 'JP', maxLength: 10),
    Country(name: 'China', code: 'CN', dialCode: '+86', flag: 'CN', maxLength: 11),
    Country(name: 'Brazil', code: 'BR', dialCode: '+55', flag: 'BR', maxLength: 11),
  ];

  static Country get defaultCountry => countries[1]; // India
}
