import 'package:excel/excel.dart';
import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/report_builder.dart';
import 'package:expense_tracker/services/xlsx_report_writer.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/export_fixtures.dart';

void main() {
  const builder = ReportBuilder();
  const writer = XlsxReportWriter();

  Future<Excel> build(
    List<TransactionModel> items, {
    ExportConfig? config,
  }) async {
    final dataset = builder.build(
      items: items,
      config: config ??
          ExportConfig(
            dateFrom: DateTime(2026, 1, 1),
            dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          ),
      user: fixtureUser(),
    );
    final bytes = await writer.write(dataset);
    expect(bytes, isNotEmpty);
    return Excel.decodeBytes(bytes);
  }

  List<TransactionModel> sample() => [
        fixtureTransaction(
          id: 'a',
          date: DateTime(2026, 1, 5, 9, 15),
          amount: 100,
          category: 'Food',
          title: 'Lunch',
          note: 'with team',
        ),
        fixtureTransaction(
          id: 'b',
          date: DateTime(2026, 1, 6),
          amount: 250.5,
          category: 'Travel',
          title: 'Cab',
          paymentMethod: PaymentMethod.upi,
        ),
        fixtureTransaction(
          id: 'c',
          date: DateTime(2026, 1, 7),
          amount: 400,
          category: 'Food',
          type: TransactionType.income,
          title: 'Refund',
        ),
      ];

  String? textOf(Data? cell) {
    final value = cell?.value;
    if (value is TextCellValue) return value.value.text;
    if (value is DoubleCellValue) return value.value.toString();
    if (value is IntCellValue) return value.value.toString();
    return null;
  }

  group('workbook structure', () {
    test('contains summary, transactions and breakdown sheets', () async {
      final excel = await build(sample());
      expect(
        excel.tables.keys,
        containsAll([
          XlsxReportWriter.summarySheet,
          XlsxReportWriter.transactionsSheet,
          'Category Breakdown',
        ]),
      );
      expect(excel.tables.containsKey('Sheet1'), isFalse);
    });

    test('uses the monthly breakdown sheet when grouping by month', () async {
      final excel = await build(
        sample(),
        config: ExportConfig(
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          groupBy: ExportGroupBy.month,
        ),
      );
      expect(excel.tables.keys, contains('Monthly Breakdown'));
    });
  });

  group('transactions sheet', () {
    test('writes a human readable header row', () async {
      final excel = await build(sample());
      final header = excel[XlsxReportWriter.transactionsSheet].rows[0]
          .map(textOf)
          .toList();
      expect(header, [
        'Date',
        'Description',
        'Category',
        'Type',
        'Amount',
        'Currency',
        'Payment Method',
        'Notes',
      ]);
    });

    test('one row per transaction plus the header', () async {
      final excel = await build(sample());
      final sheet = excel[XlsxReportWriter.transactionsSheet];
      expect(sheet.maxRows, 4);
      expect(sheet.maxColumns, 8);
    });

    test('amounts are stored as numbers, dates as text', () async {
      final excel = await build(sample());
      final rows = excel[XlsxReportWriter.transactionsSheet].rows;
      final amount = rows[1][4]!.value;
      expect(amount, isNot(isA<TextCellValue>()));
      expect(amount, anyOf(isA<DoubleCellValue>(), isA<IntCellValue>()));
      expect(num.parse(textOf(rows[1][4])!), 100);
      expect(rows[1][0]!.value, isA<TextCellValue>());
      expect(textOf(rows[1][0]), '2026-01-05');
    });

    test('cells hold unescaped original values', () async {
      final excel = await build(sample());
      final rows = excel[XlsxReportWriter.transactionsSheet].rows;
      expect(textOf(rows[1][1]), 'Lunch');
      expect(textOf(rows[1][7]), 'with team');
      expect(textOf(rows[3][6]), 'Cash');
    });

    test('drops the notes column when notes are excluded', () async {
      final excel = await build(
        sample(),
        config: ExportConfig(
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          includeNotes: false,
        ),
      );
      final sheet = excel[XlsxReportWriter.transactionsSheet];
      expect(sheet.maxColumns, 7);
      expect(textOf(sheet.rows[0][6]), 'Payment Method');
    });
  });

  group('summary sheet', () {
    test('records title, currency and totals', () async {
      final excel = await build(sample());
      final rows = excel[XlsxReportWriter.summarySheet].rows;
      final labels = rows.map((r) => textOf(r[0])).toList();

      expect(labels.first, 'Expense Report');
      expect(labels, contains('Reporting currency'));
      expect(labels, contains('Total spent'));

      String? valueFor(String label) {
        final index = labels.indexOf(label);
        return index < 0 ? null : textOf(rows[index][1]);
      }

      expect(valueFor('Reporting currency'), 'INR');
      expect(valueFor('Transactions'), '3');
      expect(double.parse(valueFor('Total spent')!), closeTo(350.5, 0.001));
      expect(double.parse(valueFor('Total income')!), closeTo(400, 0.001));
      expect(double.parse(valueFor('Net balance')!), closeTo(49.5, 0.001));
    });

    test('lists the expense breakdown with percentages summing to 100', () async {
      final excel = await build(sample());
      final rows = excel[XlsxReportWriter.summarySheet].rows;
      final labels = rows.map((r) => textOf(r[0])).toList();
      final headerIndex = labels.indexOf('Category');

      expect(headerIndex, greaterThan(0));
      expect(textOf(rows[headerIndex][2]), 'Percentage (%)');

      var total = 0.0;
      var index = headerIndex + 1;
      while (index < rows.length && rows[index][0]?.value != null) {
        final percentage = rows[index][2]!.value;
        expect(percentage, isA<DoubleCellValue>());
        total += (percentage as DoubleCellValue).value;
        index++;
      }
      expect(total, closeTo(100, 0.001));
    });
  });

  test('writes an empty workbook without throwing', () async {
    final excel = await build([]);
    expect(
      excel[XlsxReportWriter.transactionsSheet].maxRows,
      1,
      reason: 'only the header row is written',
    );
  });
}
