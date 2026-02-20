enum NotificationType {
  caseUpdate,
  tipReceived,
  nearby,
  found,
  system;

  String get label {
    switch (this) {
      case NotificationType.caseUpdate:
        return 'Case Update';
      case NotificationType.tipReceived:
        return 'Tip Received';
      case NotificationType.nearby:
        return 'Nearby Alert';
      case NotificationType.found:
        return 'Found';
      case NotificationType.system:
        return 'System';
    }
  }
}

class AppNotification {
  final String id;
  final NotificationType type;
  final String title;
  final String message;
  final DateTime timestamp;
  final bool isRead;
  final String? caseId;

  AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.message,
    required this.timestamp,
    this.isRead = false,
    this.caseId,
  });
}
