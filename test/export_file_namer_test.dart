import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/services/export_file_namer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ExportConfig config(ExportFormat format, {DateTime? from, DateTime? to}) {
    return ExportConfig(
      format: format,
      dateFrom: from ?? DateTime(2026, 1, 1),
      dateTo: to ?? DateTime(2026, 3, 31, 23, 59, 59, 999),
    );
  }

  group('build', () {
    test('produces the documented CSV name', () {
      expect(
        ExportFileNamer.build(config(ExportFormat.csv)),
        'Expenses_2026-01-01_to_2026-03-31.csv',
      );
    });

    test('produces the documented XLSX name', () {
      expect(
        ExportFileNamer.build(config(ExportFormat.xlsx)),
        'Expenses_2026-01-01_to_2026-03-31.xlsx',
      );
    });

    test('produces the documented PDF name', () {
      expect(
        ExportFileNamer.build(config(ExportFormat.pdf)),
        'Expenses_2026-01-01_to_2026-03-31.pdf',
      );
    });

    test('produces the documented JSON name', () {
      expect(
        ExportFileNamer.build(config(ExportFormat.json)),
        'Expenses_2026-01-01_to_2026-03-31.json',
      );
    });
  });

  group('sanitize', () {
    test('strips filesystem-unsafe characters', () {
      expect(
        ExportFileNamer.sanitize('a<b>c:d"e/f\\g|h?i*j'),
        'a_b_c_d_e_f_g_h_i_j',
      );
    });

    test('strips control characters', () {
      expect(ExportFileNamer.sanitize('ok\x00\x1F'), 'ok');
    });

    test('collapses repeated underscores and trims the edges', () {
      expect(ExportFileNamer.sanitize('__weird___name__'), 'weird_name');
    });

    test('never yields a path separator', () {
      final result = ExportFileNamer.sanitize('../..\\etc/passwd');
      expect(result.contains('/'), isFalse);
      expect(result.contains('\\'), isFalse);
      expect(result.contains('..'), isFalse);
    });

    test('falls back when everything is stripped', () {
      expect(ExportFileNamer.sanitize('???'), 'export');
    });

    test('clamps to the maximum length', () {
      final result = ExportFileNamer.sanitize('x' * 500);
      expect(result.length, ExportFileNamer.maxBaseLength);
    });
  });
}
