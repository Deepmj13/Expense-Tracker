import '../models/notification_model.dart';

class NotificationPipelineService {
  const NotificationPipelineService();

  static NotificationModel processNotification({
    required String title,
    required String text,
    required String packageName,
    int? timestamp,
  }) {
    final rawText = normalizeInput(title: title, text: text);
    final receivedAt = timestamp != null
        ? DateTime.fromMillisecondsSinceEpoch(timestamp)
        : DateTime.now();

    return NotificationModel(
      rawText: rawText,
      packageName: packageName,
      receivedAt: receivedAt,
    );
  }

  static String normalizeInput({
    required String title,
    required String text,
  }) {
    final combined = '$title $text';

    final withoutLineBreaks = combined.replaceAll(RegExp(r'[\n\r\t]'), ' ');

    final collapsedSpaces = withoutLineBreaks.replaceAll(RegExp(r'\s+'), ' ');

    final normalized = collapsedSpaces.trim().toLowerCase();

    return normalized;
  }
}
