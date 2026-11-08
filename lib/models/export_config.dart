import 'package:flutter/material.dart';

import '../core/constants/app_constants.dart';
import 'transaction_model.dart';

enum ExportFormat {
  csv,
  xlsx,
  pdf,
  json;

  String get label => switch (this) {
        ExportFormat.csv => 'CSV',
        ExportFormat.xlsx => 'XLSX',
        ExportFormat.pdf => 'PDF',
        ExportFormat.json => 'JSON',
      };

  IconData get icon => switch (this) {
        ExportFormat.csv => Icons.table_view,
        ExportFormat.xlsx => Icons.grid_view_outlined,
        ExportFormat.pdf => Icons.picture_as_pdf_outlined,
        ExportFormat.json => Icons.data_object_outlined,
      };

  String get extension => name;

  String get mimeType => switch (this) {
        ExportFormat.csv => 'text/csv',
        ExportFormat.xlsx =>
          'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
        ExportFormat.pdf => 'application/pdf',
        ExportFormat.json => 'application/json',
      };

  String get description => switch (this) {
        ExportFormat.csv => 'Raw data for spreadsheets & accounting tools',
        ExportFormat.xlsx => 'Formatted workbook with multiple sheets',
        ExportFormat.pdf => 'Printable, shareable report with charts',
        ExportFormat.json => 'Developer backup for APIs & integrations',
      };
}

enum DateRangePreset {
  thisMonth,
  lastMonth,
  thisQuarter,
  lastQuarter,
  thisYear,
  custom;

  String get label => switch (this) {
        DateRangePreset.thisMonth => 'This month',
        DateRangePreset.lastMonth => 'Last month',
        DateRangePreset.thisQuarter => 'This quarter',
        DateRangePreset.lastQuarter => 'Last quarter',
        DateRangePreset.thisYear => 'This year',
        DateRangePreset.custom => 'Custom',
      };

  ({DateTime from, DateTime to}) resolve(DateTime now) {
    final y = now.year;
    final m = now.month;

    switch (this) {
      case DateRangePreset.thisMonth:
        return (
          from: DateTime(y, m, 1),
          to: _endOfMonth(y, m),
        );
      case DateRangePreset.lastMonth:
        final lm = m == 1 ? 12 : m - 1;
        final ly = m == 1 ? y - 1 : y;
        return (from: DateTime(ly, lm, 1), to: _endOfMonth(ly, lm));
      case DateRangePreset.thisQuarter:
        final q = ((m - 1) ~/ 3) * 3 + 1;
        return (
          from: DateTime(y, q, 1),
          to: _endOfMonth(y, q + 2),
        );
      case DateRangePreset.lastQuarter:
        final q = ((m - 1) ~/ 3) * 3 - 2;
        final year = q <= 0 ? y - 1 : y;
        final month = q <= 0 ? q + 12 : q;
        return (
          from: DateTime(year, month, 1),
          to: _endOfMonth(year, month + 2),
        );
      case DateRangePreset.thisYear:
        return (
          from: DateTime(y, 1, 1),
          to: DateTime(y, 12, 31, 23, 59, 59, 999),
        );
      case DateRangePreset.custom:
        return (from: DateTime(y, m, 1), to: _endOfMonth(y, m));
    }
  }

  static DateTime _endOfMonth(int year, int month) {
    final nextMonthStart = DateTime(year, month + 1, 1);
    return nextMonthStart.subtract(const Duration(milliseconds: 1));
  }
}

enum ExportTransactionType {
  expenses,
  income,
  both;

  String get label => switch (this) {
        ExportTransactionType.expenses => 'Expenses only',
        ExportTransactionType.income => 'Income only',
        ExportTransactionType.both => 'Income & expenses',
      };
}

enum ExportGroupBy {
  none,
  category,
  month;

  String get label => switch (this) {
        ExportGroupBy.none => 'No grouping',
        ExportGroupBy.category => 'Category',
        ExportGroupBy.month => 'Month',
      };

  String get breakdownSheetName => switch (this) {
        ExportGroupBy.none => 'Category Breakdown',
        ExportGroupBy.category => 'Category Breakdown',
        ExportGroupBy.month => 'Monthly Breakdown',
      };
}

class ExportConfig {
  const ExportConfig({
    this.format = ExportFormat.csv,
    this.datePreset = DateRangePreset.thisMonth,
    required this.dateFrom,
    required this.dateTo,
    this.categories = const [],
    this.paymentMethods = const [],
    this.transactionType = ExportTransactionType.both,
    this.groupBy = ExportGroupBy.category,
    this.includeNotes = true,
    this.includeCategoryPercentages = true,
    this.includeCharts = true,
  });

  final ExportFormat format;
  final DateRangePreset datePreset;
  final DateTime dateFrom;
  final DateTime dateTo;
  final List<String> categories;
  final List<PaymentMethod> paymentMethods;
  final ExportTransactionType transactionType;
  final ExportGroupBy groupBy;
  final bool includeNotes;
  final bool includeCategoryPercentages;
  final bool includeCharts;

  static ExportConfig current({ExportFormat format = ExportFormat.csv}) {
    final range = DateRangePreset.thisMonth.resolve(DateTime.now());
    return ExportConfig(
      format: format,
      datePreset: DateRangePreset.thisMonth,
      dateFrom: range.from,
      dateTo: range.to,
    );
  }

  bool get hasCategoryFilter => categories.isNotEmpty;
  bool get hasPaymentMethodFilter => paymentMethods.isNotEmpty;
  bool get hasFilters => hasCategoryFilter || hasPaymentMethodFilter;

  bool get showCharts => format == ExportFormat.pdf && includeCharts;

  ExportConfig copyWith({
    ExportFormat? format,
    DateRangePreset? datePreset,
    DateTime? dateFrom,
    DateTime? dateTo,
    List<String>? categories,
    List<PaymentMethod>? paymentMethods,
    ExportTransactionType? transactionType,
    ExportGroupBy? groupBy,
    bool? includeNotes,
    bool? includeCategoryPercentages,
    bool? includeCharts,
  }) {
    return ExportConfig(
      format: format ?? this.format,
      datePreset: datePreset ?? this.datePreset,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      categories: categories ?? this.categories,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      transactionType: transactionType ?? this.transactionType,
      groupBy: groupBy ?? this.groupBy,
      includeNotes: includeNotes ?? this.includeNotes,
      includeCategoryPercentages:
          includeCategoryPercentages ?? this.includeCategoryPercentages,
      includeCharts: includeCharts ?? this.includeCharts,
    );
  }

  ExportConfig applyPreset(DateRangePreset preset, {DateTime? now}) {
    if (preset == DateRangePreset.custom) {
      return copyWith(datePreset: preset);
    }
    final range = preset.resolve(now ?? DateTime.now());
    return copyWith(
      datePreset: preset,
      dateFrom: range.from,
      dateTo: range.to,
    );
  }

  List<String> validate() {
    final errors = <String>[];

    if (dateFrom.isAfter(dateTo)) {
      errors.add('Start date must be on or before the end date.');
    }
    if (dateTo.difference(dateFrom).inDays > 366 * 5) {
      errors.add('Date range cannot be longer than 5 years.');
    }
    final knownCategories = _knownCategories();
    for (final c in categories) {
      if (!knownCategories.contains(c)) {
        errors.add('Unknown category "$c".');
      }
    }
    return errors;
  }

  Set<String> _knownCategories() {
    try {
      return AppConstants.allCategories.toSet();
    } catch (_) {
      return categories.toSet();
    }
  }

  Map<String, dynamic> toMap() => {
        'format': format.name,
        'datePreset': datePreset.name,
        'dateFrom': dateFrom.toIso8601String(),
        'dateTo': dateTo.toIso8601String(),
        'categories': categories,
        'paymentMethods': paymentMethods.map((e) => e.name).toList(),
        'transactionType': transactionType.name,
        'groupBy': groupBy.name,
        'includeNotes': includeNotes,
        'includeCategoryPercentages': includeCategoryPercentages,
        'includeCharts': includeCharts,
      };

  factory ExportConfig.fromMap(Map<dynamic, dynamic> map) {
    DateTime parseDate(String key) {
      final raw = map[key];
      if (raw is String) {
        return DateTime.tryParse(raw) ?? DateTime.now();
      }
      return DateTime.now();
    }

    return ExportConfig(
      format: ExportFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => ExportFormat.csv,
      ),
      datePreset: DateRangePreset.values.firstWhere(
        (e) => e.name == map['datePreset'],
        orElse: () => DateRangePreset.custom,
      ),
      dateFrom: parseDate('dateFrom'),
      dateTo: parseDate('dateTo'),
      categories: (map['categories'] as List?)?.cast<String>() ?? const [],
      paymentMethods: ((map['paymentMethods'] as List?) ?? const [])
          .map((e) => PaymentMethod.values.firstWhere(
                (p) => p.name == e,
                orElse: () => PaymentMethod.other,
              ))
          .toList(),
      transactionType: ExportTransactionType.values.firstWhere(
        (e) => e.name == map['transactionType'],
        orElse: () => ExportTransactionType.both,
      ),
      groupBy: ExportGroupBy.values.firstWhere(
        (e) => e.name == map['groupBy'],
        orElse: () => ExportGroupBy.category,
      ),
      includeNotes: map['includeNotes'] as bool? ?? true,
      includeCategoryPercentages:
          map['includeCategoryPercentages'] as bool? ?? true,
      includeCharts: map['includeCharts'] as bool? ?? true,
    );
  }
}
