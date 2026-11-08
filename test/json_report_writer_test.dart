import 'dart:convert';

import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/json_report_writer.dart';
import 'package:expense_tracker/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/export_fixtures.dart';

void main() {
  const builder = ReportBuilder();
  const writer = JsonReportWriter();

  Future<Map<String, dynamic>> build(
    List<TransactionModel> items, {
    ExportConfig? config,
  }) async {
    final dataset = builder.build(
      items: items,
      config: config ??
          ExportConfig(
            datePreset: DateRangePreset.custom,
            dateFrom: DateTime(2026, 1, 1),
            dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          ),
      user: fixtureUser(),
    );
    final bytes = await writer.write(dataset);
    return jsonDecode(utf8.decode(bytes)) as Map<String, dynamic>;
  }

  List<TransactionModel> sample() => [
        fixtureTransaction(
          date: DateTime(2026, 1, 5, 9, 15),
          amount: 100,
          category: 'Food',
          note: 'with team',
        ),
        fixtureTransaction(
          date: DateTime(2026, 1, 6),
          amount: 200,
          category: 'Travel',
        ),
      ];

  test('emits a schema versioned document', () async {
    final document = await build(sample());
    expect(document['schemaVersion'], 1);
    expect(
      document.keys,
      containsAll(['schemaVersion', 'meta', 'summary', 'groups', 'transactions']),
    );
  });

  test('describes the run in meta', () async {
    final document = await build(sample());
    final meta = document['meta'] as Map<String, dynamic>;

    expect(meta['reportTitle'], 'Expense Report');
    expect(meta['userName'], 'Asha Patel');
    expect(meta['dateFrom'], '2026-01-01T00:00:00.000');
    expect(meta['datePreset'], 'custom');
    expect(meta['timezone'], isA<String>());
    expect(meta['groupBy'], 'category');

    final currency = meta['currency'] as Map<String, dynamic>;
    expect(currency['code'], 'INR');
    expect(currency['symbol'], '₹');

    final filters = meta['filters'] as Map<String, dynamic>;
    expect(filters['categories'], isEmpty);
    expect(filters['paymentMethods'], isEmpty);
  });

  test('reports totals and the category breakdown', () async {
    final document = await build(sample());
    final summary = document['summary'] as Map<String, dynamic>;

    expect(summary['transactionCount'], 2);
    expect(summary['totalExpenses'], 300);
    expect(summary['totalIncome'], 0);
    expect(summary['netBalance'], -300);

    final categories = summary['categories'] as List;
    expect(categories.length, 2);
    final first = categories.first as Map<String, dynamic>;
    expect(first.keys, containsAll(['name', 'amount', 'percentage', 'count']));
    expect(first['amount'], 200);
  });

  test('omits percentages when the config disables them', () async {
    final document = await build(
      sample(),
      config: ExportConfig(
        dateFrom: DateTime(2026, 1, 1),
        dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
        includeCategoryPercentages: false,
      ),
    );
    final summary = document['summary'] as Map<String, dynamic>;
    final first = (summary['categories'] as List).first as Map<String, dynamic>;
    expect(first.containsKey('percentage'), isFalse);
  });

  test('writes every transaction with an id', () async {
    final document = await build(sample());
    final transactions = document['transactions'] as List;
    expect(transactions.length, 2);

    final first = transactions.first as Map<String, dynamic>;
    expect(first.keys, containsAll(['date', 'description', 'amount', 'id']));
    expect(first['date'], '2026-01-05T09:15:00.000');
    expect(first['amount'], 100);
    expect(first['notes'], 'with team');
  });

  test('drops notes when the config excludes them', () async {
    final document = await build(
      sample(),
      config: ExportConfig(
        dateFrom: DateTime(2026, 1, 1),
        dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
        includeNotes: false,
      ),
    );
    final first = (document['transactions'] as List).first
        as Map<String, dynamic>;
    expect(first.containsKey('notes'), isFalse);
  });

  test('writes the grouped breakdown', () async {
    final document = await build(sample());
    final groups = document['groups'] as List;
    expect(groups.length, 2);
    final first = groups.first as Map<String, dynamic>;
    expect(first.keys, containsAll(['label', 'amount', 'percentage', 'count']));
  });

  test('round-trips an empty dataset', () async {
    final document = await build([]);
    expect(document['transactions'], isEmpty);
    expect(document['groups'], isEmpty);
    expect((document['summary'] as Map<String, dynamic>)['transactionCount'], 0);
  });
}
