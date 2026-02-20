class RescueAchievement {
  final String id;
  final String title;
  final String description;
  final String icon;
  final int requiredRescues;
  final bool isUnlocked;
  final DateTime? unlockedAt;

  RescueAchievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.requiredRescues,
    required this.isUnlocked,
    this.unlockedAt,
  });
}

class Certificate {
  final String id;
  final String title;
  final String issuer;
  final DateTime issuedDate;
  final String certificateNumber;

  Certificate({
    required this.id,
    required this.title,
    required this.issuer,
    required this.issuedDate,
    required this.certificateNumber,
  });
}

class Medal {
  final String id;
  final String name;
  final String level; // Bronze, Silver, Gold, Platinum
  final String icon;
  final bool isEarned;

  Medal({
    required this.id,
    required this.name,
    required this.level,
    required this.icon,
    required this.isEarned,
  });
}
