class TransactionMessageModel {
  const TransactionMessageModel({
    required this.rawText,
    required this.packageName,
    required this.receivedAt,
  });

  final String rawText;
  final String packageName;
  final DateTime receivedAt;

  @override
  String toString() {
    return 'TransactionMessageModel(packageName: $packageName, receivedAt: $receivedAt, rawText: $rawText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TransactionMessageModel &&
        other.packageName == packageName &&
        other.receivedAt == receivedAt &&
        other.rawText == rawText;
  }

  @override
  int get hashCode => Object.hash(packageName, receivedAt, rawText);
}
