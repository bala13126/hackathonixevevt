enum UrgencyLevel {
  critical,
  high,
  normal;

  String get label {
    switch (this) {
      case UrgencyLevel.critical:
        return 'CRITICAL';
      case UrgencyLevel.high:
        return 'HIGH';
      case UrgencyLevel.normal:
        return 'NORMAL';
    }
  }
}

enum PrivacyLevel {
  public,
  protected,
  private;

  String get label {
    switch (this) {
      case PrivacyLevel.public:
        return 'Public';
      case PrivacyLevel.protected:
        return 'Protected';
      case PrivacyLevel.private:
        return 'Private';
    }
  }
}

enum CaseStatus {
  submitted,
  verified,
  active,
  found,
  archived;

  String get label {
    switch (this) {
      case CaseStatus.submitted:
        return 'Submitted';
      case CaseStatus.verified:
        return 'Verified';
      case CaseStatus.active:
        return 'Active';
      case CaseStatus.found:
        return 'Found';
      case CaseStatus.archived:
        return 'Archived';
    }
  }
}

class MissingPerson {
  final String id;
  final String name;
  final int age;
  final String photoUrl;
  final String lastSeenLocation;
  final DateTime lastSeenTime;
  final double distanceKm;
  final UrgencyLevel urgency;
  final bool isVerified;
  final String description;
  final double height;
  final String hairColor;
  final String eyeColor;
  final String clothing;
  final String contactName;
  final String contactPhone;
  final PrivacyLevel privacyLevel;
  final CaseStatus status;
  final List<String> galleryImages;

  MissingPerson({
    required this.id,
    required this.name,
    required this.age,
    required this.photoUrl,
    required this.lastSeenLocation,
    required this.lastSeenTime,
    required this.distanceKm,
    required this.urgency,
    required this.isVerified,
    required this.description,
    required this.height,
    required this.hairColor,
    required this.eyeColor,
    required this.clothing,
    required this.contactName,
    required this.contactPhone,
    required this.privacyLevel,
    required this.status,
    this.galleryImages = const [],
  });
}
