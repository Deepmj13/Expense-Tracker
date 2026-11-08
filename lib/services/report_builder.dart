import 'package:intl/intl.dart';

import '../models/app_user.dart';
import '../models/export_config.dart';
import '../models/report_dataset.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';

class ReportBuilder {
  const ReportBuilder();

  ReportDataset build({
    required List<TransactionModel> items,
    required ExportConfig config,
    required AppUser user,
    String timezone = '',
    DateTime? generatedAt,
  }) {
    final rows = _filter(items, config, user);
    final summary = _summarise(rows, config);
    final groups = _group(rows, config, summary);
    final currency = currencyCodeFor(user);

    return ReportDataset(
      config: config,
      currencyCode: currency,
      currencySymbol: user.currencySymbol,
      generatedAt: generatedAt ?? DateTime.now(),
      timezone: timezone,
      reportTitle: 'Expense Report',
      userName: user.name,
      summary: summary,
      groups: groups,
      rows: rows,
    );
  }

  List<ReportRow> _filter(
    List<TransactionModel> items,
    ExportConfig config,
    AppUser user,
  ) {
    final currency = currencyCodeFor(user);

    final filtered = items.where((t) {
      if (t.date.isBefore(config.dateFrom)) return false;
      if (t.date.isAfter(config.dateTo)) return false;

      if (config.hasCategoryFilter && !config.categories.contains(t.category)) {
        return false;
      }
      if (config.hasPaymentMethodFilter &&
          !config.paymentMethods.contains(t.paymentMethod)) {
        return false;
      }
      switch (config.transactionType) {
        case ExportTransactionType.expenses:
          if (t.type != TransactionType.expense) return false;
        case ExportTransactionType.income:
          if (t.type != TransactionType.income) return false;
        case ExportTransactionType.both:
          break;
      }
      return true;
    }).toList();

    filtered.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.id.compareTo(b.id);
    });

    return filtered
        .map((t) => ReportRow.fromTransaction(t, currency))
        .toList();
  }

  ReportSummary _summarise(List<ReportRow> rows, ExportConfig config) {
    var expenses = 0.0;
    var income = 0.0;
    for (final r in rows) {
      if (r.type == TransactionType.expense) {
        expenses += r.amount;
      } else {
        income += r.amount;
      }
    }

    final basis = _breakdownBasis(rows, config);
    final basisTotal = basis.fold<double>(0, (s, r) => s + r.amount);

    final byCategory = <String, double>{};
    final counts = <String, int>{};
    for (final r in basis) {
      byCategory[r.category] = (byCategory[r.category] ?? 0) + r.amount;
      counts[r.category] = (counts[r.category] ?? 0) + 1;
    }

    final categories = byCategory.entries.map((e) {
      return CategoryRow(
        name: e.key,
        amount: e.value,
        percentage: basisTotal == 0 ? 0 : (e.value / basisTotal) * 100,
        count: counts[e.key] ?? 0,
      );
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return ReportSummary(
      transactionCount: rows.length,
      totalExpenses: expenses,
      totalIncome: income,
      netBalance: income - expenses,
      categories: categories,
    );
  }

  List<ReportRow> _breakdownBasis(
    List<ReportRow> rows,
    ExportConfig config,
  ) {
    if (config.transactionType == ExportTransactionType.income) {
      return rows.where((r) => r.type == TransactionType.income).toList();
    }
    final expenses =
        rows.where((r) => r.type == TransactionType.expense).toList();
    return expenses.isEmpty ? rows : expenses;
  }

  List<ReportGroup> _group(
    List<ReportRow> rows,
    ExportConfig config,
    ReportSummary summary,
  ) {
    if (rows.isEmpty) return const [];

    if (config.groupBy == ExportGroupBy.month) {
      final total =
          summary.totalExpenses + summary.totalIncome;
      final byMonth = <String, double>{};
      final counts = <String, int>{};
      final order = <String>[];
      for (final r in rows) {
        final key = DateFormat('MMM yyyy').format(
          DateTime(r.date.year, r.date.month, 1),
        );
        if (!byMonth.containsKey(key)) order.add(key);
        byMonth[key] = (byMonth[key] ?? 0) + r.amount;
        counts[key] = (counts[key] ?? 0) + 1;
      }
      return order.map((label) {
        final amount = byMonth[label] ?? 0;
        return ReportGroup(
          label: label,
          amount: amount,
          percentage: total == 0 ? 0 : (amount / total) * 100,
          count: counts[label] ?? 0,
        );
      }).toList();
    }

    return summary.categories
        .map((c) => ReportGroup(
              label: c.name,
              amount: c.amount,
              percentage: c.percentage,
              count: c.count,
            ))
        .toList();
  }
}
