class Tip {
  final String id;
  final String caseId;
  final String message;
  final String? imageUrl;
  final String? location;
  final DateTime timestamp;
  final bool isAnonymous;

  Tip({
    required this.id,
    required this.caseId,
    required this.message,
    this.imageUrl,
    this.location,
    required this.timestamp,
    this.isAnonymous = false,
  });
}
