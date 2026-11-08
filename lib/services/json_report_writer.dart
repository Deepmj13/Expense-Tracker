import 'dart:convert';

import '../models/report_dataset.dart';
import 'report_writer.dart';

class JsonReportWriter extends ReportWriter {
  const JsonReportWriter();

  @override
  Future<List<int>> write(
    ReportDataset dataset, {
    ReportProgressCallback? onProgress,
  }) async {
    final config = dataset.config;
    final summary = dataset.summary;

    final document = <String, dynamic>{
      'schemaVersion': 1,
      'meta': {
        'reportTitle': dataset.reportTitle,
        'userName': dataset.userName,
        'dateFrom': config.dateFrom.toIso8601String(),
        'dateTo': config.dateTo.toIso8601String(),
        'datePreset': config.datePreset.name,
        'generatedAt': dataset.generatedAt.toIso8601String(),
        'timezone': dataset.timezone,
        'currency': {
          'code': dataset.currencyCode,
          'symbol': dataset.currencySymbol,
        },
        'groupBy': config.groupBy.name,
        'transactionType': config.transactionType.name,
        'filters': {
          'categories': config.categories,
          'paymentMethods':
              config.paymentMethods.map((e) => e.name).toList(),
        },
      },
      'summary': {
        'transactionCount': summary.transactionCount,
        'totalExpenses': summary.totalExpenses,
        'totalIncome': summary.totalIncome,
        'netBalance': summary.netBalance,
        'categories': [
          for (final c in summary.categories)
            {
              'name': c.name,
              'amount': c.amount,
              if (config.includeCategoryPercentages)
                'percentage': c.percentage,
              'count': c.count,
            },
        ],
      },
      'groups': [
        for (final g in dataset.groups) g.toMap(includePercentage: true),
      ],
      'transactions': [
        for (final row in dataset.rows)
          row.toMap(includeNotes: config.includeNotes),
      ],
    };

    onProgress?.call(dataset.rows.length, dataset.rows.length);
    return utf8.encode(
      const JsonEncoder.withIndent('  ').convert(document),
    );
  }
}
