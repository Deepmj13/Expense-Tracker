class NotificationModel {
  const NotificationModel({
    required this.rawText,
    required this.packageName,
    required this.receivedAt,
  });

  final String rawText;
  final String packageName;
  final DateTime receivedAt;

  @override
  String toString() {
    return 'NotificationModel(packageName: $packageName, receivedAt: $receivedAt, rawText: $rawText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is NotificationModel &&
        other.packageName == packageName &&
        other.receivedAt == receivedAt &&
        other.rawText == rawText;
  }

  @override
  int get hashCode => Object.hash(packageName, receivedAt, rawText);
}
