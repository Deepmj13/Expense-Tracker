import 'dart:convert';

import 'package:csv/csv.dart';
import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/services/csv_report_writer.dart';
import 'package:expense_tracker/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/export_fixtures.dart';

void main() {
  const builder = ReportBuilder();
  const writer = CsvReportWriter();

  Future<({String text, List<int> bytes})> buildCsv(
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
    return (text: utf8.decode(bytes.sublist(3)), bytes: bytes);
  }

  group('encoding', () {
    test('starts with a UTF-8 byte order mark', () async {
      final result = await buildCsv([
        fixtureTransaction(date: DateTime(2026, 1, 5)),
      ]);
      expect(result.bytes.sublist(0, 3), [0xEF, 0xBB, 0xBF]);
    });

    test('preserves non-ASCII characters', () async {
      final result = await buildCsv([
        fixtureTransaction(
          date: DateTime(2026, 1, 5),
          title: 'Café ☕ ₹100',
          note: 'ऑर्डर संख्या 42',
        ),
      ]);
      expect(result.text, contains('Café ☕ ₹100'));
      expect(result.text, contains('ऑर्डर संख्या 42'));
    });
  });

  group('structure', () {
    test('has exactly one header row followed by data rows', () async {
      final result = await buildCsv([
        fixtureTransaction(date: DateTime(2026, 1, 5), id: 'a'),
        fixtureTransaction(date: DateTime(2026, 1, 6), id: 'b'),
      ]);
      final lines = result.text.split('\r\n').where((l) => l.isNotEmpty);
      expect(lines.length, 3);
      expect(
        lines.first,
        'date,description,category,type,amount,currency,payment_method,notes',
      );
    });

    test('omits the notes column when notes are excluded', () async {
      final result = await buildCsv(
        [fixtureTransaction(date: DateTime(2026, 1, 5))],
        config: ExportConfig(
          dateFrom: DateTime(2026, 1, 1),
          dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
          includeNotes: false,
        ),
      );
      expect(
        result.text.split('\r\n').first,
        'date,description,category,type,amount,currency,payment_method',
      );
    });

    test('writes dates as YYYY-MM-DD', () async {
      final result = await buildCsv([
        fixtureTransaction(date: DateTime(2026, 3, 5, 14, 30)),
      ]);
      expect(result.text, contains('\r\n2026-03-05,'));
    });

    test('emits amounts as plain unquoted numbers', () async {
      final result = await buildCsv([
        fixtureTransaction(date: DateTime(2026, 1, 5), amount: 1234.5),
      ]);
      expect(result.text, contains(',1234.50,'));
      expect(result.text, isNot(contains('₹1234.50')));
    });

    test('escapes commas, quotes and newlines per RFC 4180', () async {
      final result = await buildCsv([
        fixtureTransaction(
          date: DateTime(2026, 1, 5),
          title: 'Buy "milk", bread\nand eggs',
        ),
      ]);
      expect(
        result.text,
        contains('"Buy ""milk"", bread\nand eggs"'),
      );
    });
  });

  group('formula injection protection', () {
    for (final payload in [
      '=cmd|\'/c calc\'!A0',
      '+1+1',
      '-2+3+cmd',
      '@SUM(A1)',
      ' \t=HYPERLINK("http://evil","x")',
    ]) {
    test('escapes a description starting with a dangerous character', () async {
      final result = await buildCsv([
        fixtureTransaction(date: DateTime(2026, 1, 5), title: payload),
      ]);
      final rows = const CsvToListConverter(shouldParseNumbers: false)
          .convert(result.text);
      final description = rows[1][1] as String;
      expect(description, startsWith("'"),
          reason: 'payload "$payload" must be neutralised');
      expect(description, contains(payload));
    });
    }

    test('leaves benign descriptions untouched', () async {
      final result = await buildCsv([
        fixtureTransaction(date: DateTime(2026, 1, 5), title: 'Groceries'),
      ]);
      final rows = const CsvToListConverter(shouldParseNumbers: false)
          .convert(result.text);
      expect(rows[1][1], 'Groceries');
    });
  });

  test('reports chunked progress while writing', () async {
    final items = [
      for (var i = 0; i < 600; i++)
        fixtureTransaction(date: DateTime(2026, 1, 5), id: 't$i'),
    ];
    final dataset = builder.build(
      items: items,
      config: ExportConfig(
        dateFrom: DateTime(2026, 1, 1),
        dateTo: DateTime(2026, 12, 31, 23, 59, 59, 999),
      ),
      user: fixtureUser(),
    );

    final progress = <(int, int)>[];
    await writer.write(dataset, onProgress: (done, total) => progress.add((done, total)));

    expect(progress, isNotEmpty);
    expect(progress.last.$1, 600);
    expect(progress.last.$2, 600);
    expect(progress.first.$1, lessThan(600));
  });
}
