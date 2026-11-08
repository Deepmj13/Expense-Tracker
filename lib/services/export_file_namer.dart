import '../models/export_config.dart';

class ExportFileNamer {
  static const maxBaseLength = 100;
  static const _invalidChars = ['<', '>', ':', '"', '/', '|', '?', '*', '\\'];
  static final _controlChars = RegExp(r'[\x00-\x1F\x7F]');
  static final _collapseUnderscores = RegExp(r'_{2,}');
  static final _trimEdges = RegExp(r'^[_.\s]+|[_.\s]+$');

  static String build(ExportConfig config) {
    final base = 'Expenses_${_day(config.dateFrom)}_to_${_day(config.dateTo)}';
    return '${sanitize(base)}.${config.format.extension}';
  }

  static String safeFileName(String fileName) {
    final dot = fileName.lastIndexOf('.');
    final hasExtension = dot > 0 && dot < fileName.length - 1;
    if (!hasExtension) return sanitize(fileName);
    final extension = sanitize(fileName.substring(dot + 1));
    final base = sanitize(fileName.substring(0, dot));
    return '$base.$extension';
  }

  static String sanitize(String input) {
    var value = input;
    for (final char in _invalidChars) {
      value = value.replaceAll(char, '_');
    }
    value = value.replaceAll(_controlChars, '_');
    value = value.replaceAll(_collapseUnderscores, '_');
    value = value.replaceAll(_trimEdges, '');
    if (value.isEmpty) value = 'export';
    if (value.length > maxBaseLength) value = value.substring(0, maxBaseLength);
    return value;
  }

  static String _day(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
