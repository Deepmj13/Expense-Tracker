import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/pdf_report_writer.dart';
import 'package:expense_tracker/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/export_fixtures.dart';

void main() {
  const builder = ReportBuilder();
  const writer = PdfReportWriter();

  Future<List<int>> write(
    List<TransactionModel> items, {
    ExportConfig? config,
  }) async {
    final dataset = builder.build(
      items: items,
      config: config ??
          ExportConfig(
            format: ExportFormat.pdf,
            dateFrom: DateTime(2026, 1, 1),
            dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          ),
      user: fixtureUser(),
    );
    return writer.write(dataset);
  }

  List<TransactionModel> sample([int count = 3]) => [
        for (var i = 0; i < count; i++)
          fixtureTransaction(
            id: 't$i',
            date: DateTime(2026, 1, 5 + (i % 20)),
            amount: 100 + i * 25,
            category: i.isEven ? 'Food' : 'Travel',
            type: i % 5 == 0 ? TransactionType.income : TransactionType.expense,
            title: 'Row $i',
            note: 'Note for row $i',
          ),
      ];

  String decode(List<int> bytes) => String.fromCharCodes(bytes);
  final pageCount = RegExp(r'/Type\s*/Page\b');

  group('document structure', () {
    test('produces a well formed PDF file', () async {
      final bytes = await write(sample());
      expect(bytes.length, greaterThan(1000));
      expect(decode(bytes.sublist(0, 5)), '%PDF-');
      expect(decode(bytes).trimRight().endsWith('%%EOF'), isTrue);
    });

    test('contains at least one page', () async {
      final bytes = await write(sample());
      expect(pageCount.allMatches(decode(bytes)), isNotEmpty);
    });

    test('grows as the row count grows', () async {
      final small = await write(sample(3));
      final large = await write(sample(400));
      expect(large.length, greaterThan(small.length));
    });
  });

  group('options', () {
    test('renders without charts when they are disabled', () async {
      final bytes = await write(
        sample(),
        config: ExportConfig(
          format: ExportFormat.pdf,
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          includeCharts: false,
        ),
      );
      expect(decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('renders without the notes column when notes are excluded', () async {
      final bytes = await write(
        sample(),
        config: ExportConfig(
          format: ExportFormat.pdf,
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          includeNotes: false,
        ),
      );
      expect(decode(bytes.sublist(0, 5)), '%PDF-');
    });

    test('renders a chartable breakdown', () async {
      final bytes = await write(sample());
      expect(decode(bytes.sublist(0, 5)), '%PDF-');
    });
  });

  group('edge cases', () {
    test('an empty report still produces a valid document', () async {
      final bytes = await write([]);
      expect(decode(bytes.sublist(0, 5)), '%PDF-');
      expect(pageCount.allMatches(decode(bytes)), isNotEmpty);
    });

    test('reports a single completion tick', () async {
      final ticks = <(int, int)>[];
      final dataset = builder.build(
        items: sample(),
        config: ExportConfig(
          format: ExportFormat.pdf,
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
        ),
        user: fixtureUser(),
      );
      await writer.write(dataset, onProgress: (d, t) => ticks.add((d, t)));
      expect(ticks, [(1, 1)]);
    });
  });
}
