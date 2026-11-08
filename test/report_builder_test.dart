import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/transaction_model.dart';
import 'package:expense_tracker/models/transaction_type.dart';
import 'package:expense_tracker/services/report_builder.dart';
import 'package:flutter_test/flutter_test.dart';

import 'helpers/export_fixtures.dart';

void main() {
  const builder = ReportBuilder();

  ExportConfig config({
    DateTime? from,
    DateTime? to,
    DateRangePreset preset = DateRangePreset.custom,
    List<String> categories = const [],
    List<PaymentMethod> methods = const [],
    ExportTransactionType type = ExportTransactionType.both,
    ExportGroupBy groupBy = ExportGroupBy.category,
    bool includeNotes = true,
    bool includeCategoryPercentages = true,
    bool includeCharts = true,
    ExportFormat format = ExportFormat.csv,
  }) {
    return ExportConfig(
      format: format,
      datePreset: preset,
      dateFrom: from ?? DateTime(2026, 1, 1),
      dateTo: to ?? DateTime(2026, 3, 31, 23, 59, 59, 999),
      categories: categories,
      paymentMethods: methods,
      transactionType: type,
      groupBy: groupBy,
      includeNotes: includeNotes,
      includeCategoryPercentages: includeCategoryPercentages,
      includeCharts: includeCharts,
    );
  }

  group('DateRangePreset', () {
    test('thisMonth resolves to full current month inclusively', () {
      final range =
          DateRangePreset.thisMonth.resolve(DateTime(2026, 9, 17, 14, 30));
      expect(range.from, DateTime(2026, 9, 1));
      expect(range.to, DateTime(2026, 9, 30, 23, 59, 59, 999));
    });

    test('lastMonth crosses the year boundary', () {
      final range =
          DateRangePreset.lastMonth.resolve(DateTime(2026, 1, 5));
      expect(range.from, DateTime(2025, 12, 1));
      expect(range.to, DateTime(2025, 12, 31, 23, 59, 59, 999));
    });

    test('thisQuarter resolves for Q1', () {
      final range =
          DateRangePreset.thisQuarter.resolve(DateTime(2026, 2, 10));
      expect(range.from, DateTime(2026, 1, 1));
      expect(range.to, DateTime(2026, 3, 31, 23, 59, 59, 999));
    });

    test('thisQuarter resolves for Q4', () {
      final range =
          DateRangePreset.thisQuarter.resolve(DateTime(2026, 11, 2));
      expect(range.from, DateTime(2026, 10, 1));
      expect(range.to, DateTime(2026, 12, 31, 23, 59, 59, 999));
    });

    test('lastQuarter crosses the year boundary', () {
      final range =
          DateRangePreset.lastQuarter.resolve(DateTime(2026, 2, 10));
      expect(range.from, DateTime(2025, 10, 1));
      expect(range.to, DateTime(2025, 12, 31, 23, 59, 59, 999));
    });

    test('thisYear resolves to calendar year', () {
      final range =
          DateRangePreset.thisYear.resolve(DateTime(2026, 6, 1));
      expect(range.from, DateTime(2026, 1, 1));
      expect(range.to, DateTime(2026, 12, 31, 23, 59, 59, 999));
    });

    test('end of month handles leap february', () {
      final range =
          DateRangePreset.thisMonth.resolve(DateTime(2028, 2, 10));
      expect(range.to, DateTime(2028, 2, 29, 23, 59, 59, 999));
    });
  });

  group('date range filtering', () {
    final items = [
      fixtureTransaction(date: DateTime(2025, 12, 31, 23, 59, 59), id: 'before'),
      fixtureTransaction(date: DateTime(2026, 1, 1, 0, 0, 0), id: 'first'),
      fixtureTransaction(date: DateTime(2026, 2, 15, 12), id: 'middle'),
      fixtureTransaction(date: DateTime(2026, 3, 31, 23, 59, 59), id: 'last'),
      fixtureTransaction(date: DateTime(2026, 4, 1, 0, 0, 1), id: 'after'),
    ];

    test('range bounds are inclusive on both ends', () {
      final dataset = builder.build(
        items: items,
        config: config(),
        user: fixtureUser(),
      );
      expect(dataset.rows.map((r) => r.id), ['first', 'middle', 'last']);
    });
  });

  group('filters', () {
    final items = [
      fixtureTransaction(
        id: 'a',
        date: DateTime(2026, 1, 5),
        category: 'Food',
        paymentMethod: PaymentMethod.cash,
        amount: 100,
      ),
      fixtureTransaction(
        id: 'b',
        date: DateTime(2026, 1, 6),
        category: 'Travel',
        paymentMethod: PaymentMethod.upi,
        amount: 200,
      ),
      fixtureTransaction(
        id: 'c',
        date: DateTime(2026, 1, 7),
        category: 'Food',
        paymentMethod: PaymentMethod.upi,
        amount: 50,
        type: TransactionType.income,
        title: 'Refund',
      ),
    ];

    test('category filter', () {
      final dataset = builder.build(
        items: items,
        config: config(categories: ['Food']),
        user: fixtureUser(),
      );
      expect(dataset.rows.map((r) => r.id), ['a', 'c']);
    });

    test('payment method filter', () {
      final dataset = builder.build(
        items: items,
        config: config(methods: [PaymentMethod.upi]),
        user: fixtureUser(),
      );
      expect(dataset.rows.map((r) => r.id), ['b', 'c']);
    });

    test('expenses only', () {
      final dataset = builder.build(
        items: items,
        config: config(type: ExportTransactionType.expenses),
        user: fixtureUser(),
      );
      expect(dataset.rows.map((r) => r.id), ['a', 'b']);
      expect(dataset.summary.totalIncome, 0);
      expect(dataset.summary.totalExpenses, 300);
    });

    test('income only', () {
      final dataset = builder.build(
        items: items,
        config: config(type: ExportTransactionType.income),
        user: fixtureUser(),
      );
      expect(dataset.rows.map((r) => r.id), ['c']);
      expect(dataset.summary.totalIncome, 50);
      expect(dataset.summary.netBalance, 50);
    });

    test('rows are sorted ascending by date', () {
      final dataset = builder.build(
        items: items.reversed.toList(),
        config: config(),
        user: fixtureUser(),
      );
      expect(dataset.rows.map((r) => r.id), ['a', 'b', 'c']);
    });
  });

  group('summary', () {
    final items = [
      fixtureTransaction(date: DateTime(2026, 1, 5), amount: 600, category: 'Food'),
      fixtureTransaction(date: DateTime(2026, 1, 6), amount: 300, category: 'Travel'),
      fixtureTransaction(date: DateTime(2026, 1, 7), amount: 100, category: 'Food'),
      fixtureTransaction(
        date: DateTime(2026, 1, 8),
        amount: 5000,
        type: TransactionType.income,
        category: 'Salary',
        title: 'Salary',
      ),
    ];

    test('totals and net balance', () {
      final dataset = builder.build(
        items: items,
        config: config(),
        user: fixtureUser(),
      );
      expect(dataset.summary.transactionCount, 4);
      expect(dataset.summary.totalExpenses, 1000);
      expect(dataset.summary.totalIncome, 5000);
      expect(dataset.summary.netBalance, 4000);
    });

    test('category breakdown covers expenses and percentages sum to 100', () {
      final dataset = builder.build(
        items: items,
        config: config(),
        user: fixtureUser(),
      );
      final totalPercentage = dataset.summary.categories
          .fold<double>(0, (s, c) => s + c.percentage);
      expect(totalPercentage, closeTo(100, 0.0001));
      expect(dataset.summary.categories.first.name, 'Food');
      expect(dataset.summary.categories.first.amount, 700);
      expect(dataset.summary.categories.first.percentage, closeTo(70, 0.0001));
      expect(dataset.summary.categories.map((c) => c.count), [2, 1]);
    });

    test('income-only breakdown falls back to income rows', () {
      final dataset = builder.build(
        items: items,
        config: config(type: ExportTransactionType.income),
        user: fixtureUser(),
      );
      expect(dataset.summary.categories.single.name, 'Salary');
      expect(dataset.summary.categories.single.percentage, closeTo(100, 0.0001));
    });

    test('empty input produces a zeroed summary', () {
      final dataset = builder.build(
        items: const [],
        config: config(),
        user: fixtureUser(),
      );
      expect(dataset.summary.transactionCount, 0);
      expect(dataset.summary.totalExpenses, 0);
      expect(dataset.summary.netBalance, 0);
      expect(dataset.summary.categories, isEmpty);
      expect(dataset.groups, isEmpty);
      expect(dataset.rows, isEmpty);
    });
  });

  group('grouping', () {
    final items = [
      fixtureTransaction(date: DateTime(2026, 1, 5), amount: 100, category: 'Food'),
      fixtureTransaction(date: DateTime(2026, 1, 20), amount: 150, category: 'Travel'),
      fixtureTransaction(date: DateTime(2026, 2, 5), amount: 250, category: 'Food'),
    ];

    test('by category', () {
      final dataset = builder.build(
        items: items,
        config: config(groupBy: ExportGroupBy.category),
        user: fixtureUser(),
      );
      expect(dataset.groups.map((g) => g.label), ['Food', 'Travel']);
      expect(dataset.groups.first.amount, 350);
      expect(dataset.groups.first.percentage, closeTo(70, 0.0001));
    });

    test('by month preserves chronological order', () {
      final dataset = builder.build(
        items: items,
        config: config(groupBy: ExportGroupBy.month),
        user: fixtureUser(),
      );
      expect(dataset.groups.map((g) => g.label), ['Jan 2026', 'Feb 2026']);
      expect(dataset.groups.first.amount, 250);
      expect(dataset.groups.last.amount, 250);
    });

    test('none falls back to category breakdown', () {
      final dataset = builder.build(
        items: items,
        config: config(groupBy: ExportGroupBy.none),
        user: fixtureUser(),
      );
      expect(dataset.groups.map((g) => g.label), ['Food', 'Travel']);
    });
  });

  group('currency', () {
    test('resolves ISO code from the user country', () {
      final dataset = builder.build(
        items: [fixtureTransaction(date: DateTime(2026, 1, 5))],
        config: config(),
        user: fixtureUser(country: 'United States', currencySymbol: '\$'),
      );
      expect(dataset.currencyCode, 'USD');
      expect(dataset.currencySymbol, '\$');
      expect(dataset.rows.first.currency, 'USD');
    });

    test('falls back to the symbol when the country is unknown', () {
      final dataset = builder.build(
        items: [fixtureTransaction(date: DateTime(2026, 1, 5))],
        config: config(),
        user: fixtureUser(country: 'Atlantis', currencySymbol: '◈'),
      );
      expect(dataset.currencyCode, '◈');
    });
  });

  group('config validation', () {
    test('rejects an inverted date range', () {
      final errors = config(
        from: DateTime(2026, 5, 1),
        to: DateTime(2026, 1, 1),
      ).validate();
      expect(errors, isNotEmpty);
    });

    test('rejects a range longer than five years', () {
      final errors = config(
        from: DateTime(2020, 1, 1),
        to: DateTime(2026, 1, 1),
      ).validate();
      expect(errors.single, contains('5 years'));
    });

    test('accepts a well formed range', () {
      expect(config().validate(), isEmpty);
    });
  });

  test('config round-trips through a map', () {
    final original = config(
      format: ExportFormat.pdf,
      categories: const ['Food'],
      methods: const [PaymentMethod.upi],
      type: ExportTransactionType.expenses,
      groupBy: ExportGroupBy.month,
      includeCharts: false,
    );
    final restored = ExportConfig.fromMap(original.toMap());

    expect(restored.format, ExportFormat.pdf);
    expect(restored.categories, ['Food']);
    expect(restored.paymentMethods, [PaymentMethod.upi]);
    expect(restored.transactionType, ExportTransactionType.expenses);
    expect(restored.groupBy, ExportGroupBy.month);
    expect(restored.includeCharts, isFalse);
    expect(restored.dateFrom, original.dateFrom);
    expect(restored.dateTo, original.dateTo);
  });
}
