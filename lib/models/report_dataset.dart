import 'app_user.dart';
import 'export_config.dart';
import 'transaction_model.dart';
import 'transaction_type.dart';

class ReportColumns {
  static const date = 'date';
  static const description = 'description';
  static const category = 'category';
  static const type = 'type';
  static const amount = 'amount';
  static const currency = 'currency';
  static const paymentMethod = 'payment_method';
  static const notes = 'notes';
  static const id = 'id';

  static List<String> forConfig(ExportConfig config) {
    return [
      date,
      description,
      category,
      type,
      amount,
      currency,
      paymentMethod,
      if (config.includeNotes) notes,
    ];
  }

  static List<String> humanLabels(ExportConfig config) {
    return forConfig(config).map((c) => switch (c) {
          date => 'Date',
          description => 'Description',
          category => 'Category',
          type => 'Type',
          amount => 'Amount',
          currency => 'Currency',
          paymentMethod => 'Payment Method',
          notes => 'Notes',
          _ => c,
        }).toList();
  }
}

class ReportRow {
  const ReportRow({
    required this.id,
    required this.date,
    required this.description,
    required this.category,
    required this.type,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    this.note = '',
  });

  final String id;
  final DateTime date;
  final String description;
  final String category;
  final TransactionType type;
  final double amount;
  final String currency;
  final PaymentMethod paymentMethod;
  final String note;

  factory ReportRow.fromTransaction(TransactionModel t, String currency) {
    return ReportRow(
      id: t.id,
      date: t.date,
      description: t.title,
      category: t.category,
      type: t.type,
      amount: t.amount,
      currency: currency,
      paymentMethod: t.paymentMethod,
      note: t.note,
    );
  }

  Map<String, dynamic> toMap({required bool includeNotes}) => {
        ReportColumns.date: date.toIso8601String(),
        ReportColumns.description: description,
        ReportColumns.category: category,
        ReportColumns.type: type.name,
        ReportColumns.amount: amount,
        ReportColumns.currency: currency,
        ReportColumns.paymentMethod: paymentMethod.name,
        if (includeNotes) ReportColumns.notes: note,
        ReportColumns.id: id,
      };
}

class CategoryRow {
  const CategoryRow({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.count,
  });

  final String name;
  final double amount;
  final double percentage;
  final int count;
}

class ReportGroup {
  const ReportGroup({
    required this.label,
    required this.amount,
    required this.percentage,
    required this.count,
  });

  final String label;
  final double amount;
  final double percentage;
  final int count;

  Map<String, dynamic> toMap({required bool includePercentage}) => {
        'label': label,
        'amount': amount,
        if (includePercentage) 'percentage': percentage,
        'count': count,
      };
}

class ReportSummary {
  const ReportSummary({
    required this.transactionCount,
    required this.totalExpenses,
    required this.totalIncome,
    required this.netBalance,
    required this.categories,
  });

  final int transactionCount;
  final double totalExpenses;
  final double totalIncome;
  final double netBalance;
  final List<CategoryRow> categories;

  static const empty = ReportSummary(
    transactionCount: 0,
    totalExpenses: 0,
    totalIncome: 0,
    netBalance: 0,
    categories: [],
  );
}

class ReportDataset {
  const ReportDataset({
    required this.config,
    required this.currencyCode,
    required this.currencySymbol,
    required this.generatedAt,
    required this.timezone,
    required this.reportTitle,
    required this.userName,
    required this.summary,
    required this.groups,
    required this.rows,
  });

  final ExportConfig config;
  final String currencyCode;
  final String currencySymbol;
  final DateTime generatedAt;
  final String timezone;
  final String reportTitle;
  final String userName;
  final ReportSummary summary;
  final List<ReportGroup> groups;
  final List<ReportRow> rows;

  bool get hasChartableBreakdown => summary.categories.isNotEmpty;

  String get dateRangeLabel {
    String fmt(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
    return '${fmt(config.dateFrom)} to ${fmt(config.dateTo)}';
  }
}

String currencyCodeFor(AppUser user) {
  for (final c in Country.countries) {
    if (c.name == user.country) return c.currency;
  }
  return user.currencySymbol;
}
