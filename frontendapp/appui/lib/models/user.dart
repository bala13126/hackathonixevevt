class User {
  final String id;
  final String name;
  final String email;
  final String phone;
  final String photoUrl;
  final int honorScore;
  final int rescueCount;
  final bool hasMedal;
  final bool hasCertificate;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.photoUrl,
    required this.honorScore,
    required this.rescueCount,
    required this.hasMedal,
    required this.hasCertificate,
  });
}
