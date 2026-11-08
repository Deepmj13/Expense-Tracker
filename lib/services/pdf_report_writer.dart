import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/report_dataset.dart';
import 'report_writer.dart';

class PdfReportWriter extends ReportWriter {
  const PdfReportWriter();

  static const _accent = PdfColors.teal;
  static const _palette = <PdfColor>[
    PdfColors.teal,
    PdfColors.blue,
    PdfColors.amber,
    PdfColors.purple,
    PdfColors.deepOrange,
    PdfColors.cyan,
    PdfColors.pink,
    PdfColors.green,
  ];

  static final _number = NumberFormat('#,##0.00', 'en_US');
  static final _isoDate = DateFormat('yyyy-MM-dd');
  static final _friendlyDate = DateFormat.yMMMd();

  @override
  Future<List<int>> write(
    ReportDataset dataset, {
    ReportProgressCallback? onProgress,
  }) async {
    final doc = pw.Document(
      title: dataset.reportTitle,
      author: dataset.userName,
      creator: 'Expense Tracker',
    );

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          _header(dataset),
          _metaTable(dataset),
          _kpis(dataset),
          _sectionTitle('Category Breakdown'),
          _breakdownTable(context, dataset),
          if (dataset.config.showCharts && dataset.hasChartableBreakdown) ...[
            _sectionTitle('Spending by category'),
            _pieChart(dataset),
          ],
          _sectionTitle('Transactions'),
          _transactionsTable(context, dataset),
        ],
        footer: (context) => _footer(context, dataset),
      ),
    );

    onProgress?.call(1, 1);
    return doc.save();
  }

  String money(ReportDataset dataset, double value) =>
      '${dataset.currencyCode} ${_number.format(value)}';

  String _clip(String value, int max) {
    if (value.length <= max) return value;
    return '${value.substring(0, max)}...';
  }

  pw.Widget _header(ReportDataset dataset) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(16),
      decoration: const pw.BoxDecoration(
        color: _accent,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(10)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            dataset.reportTitle,
            style: pw.TextStyle(
              fontSize: 20,
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            '${_friendlyDate.format(dataset.config.dateFrom)} - '
            '${_friendlyDate.format(dataset.config.dateTo)}',
            style: const pw.TextStyle(
              fontSize: 11,
              color: PdfColors.white,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _metaTable(ReportDataset dataset) {
    final rows = <List<String>>[
      ['Prepared for', dataset.userName],
      ['Generated', DateFormat.yMMMd().add_jm().format(dataset.generatedAt)],
      if (dataset.timezone.isNotEmpty) ['Timezone', dataset.timezone],
      ['Reporting currency', dataset.currencyCode],
      ['Transactions', '${dataset.summary.transactionCount}'],
    ];

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 14, bottom: 4),
      child: pw.Column(
        children: [
          for (final row in rows)
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 2),
              child: pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.SizedBox(
                    width: 130,
                    child: pw.Text(
                      row[0],
                      style: const pw.TextStyle(
                        fontSize: 9,
                        color: PdfColors.grey600,
                      ),
                    ),
                  ),
                  pw.Expanded(
                    child: pw.Text(
                      row[1],
                      style: const pw.TextStyle(fontSize: 9),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  pw.Widget _kpis(ReportDataset dataset) {
    final summary = dataset.summary;

    pw.Widget card(String label, String value, PdfColor color) {
      return pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 8),
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                label,
                style:
                    const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                value,
                style: pw.TextStyle(
                  fontSize: 12,
                  color: color,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 10, bottom: 6),
      child: pw.Row(
        children: [
          card('TOTAL SPENT', money(dataset, summary.totalExpenses),
              PdfColors.red),
          card('TOTAL INCOME', money(dataset, summary.totalIncome),
              PdfColors.green),
          card('NET BALANCE', money(dataset, summary.netBalance),
              summary.netBalance < 0 ? PdfColors.red : PdfColors.blue),
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(top: 16, bottom: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 13,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.teal800,
        ),
      ),
    );
  }

  pw.Widget _breakdownTable(pw.Context context, ReportDataset dataset) {
    final showPercent = dataset.config.includeCategoryPercentages;
    final headers = <dynamic>[
      'Category',
      'Amount',
      if (showPercent) 'Percentage (%)',
      'Count',
    ];
    final data = [
      for (final c in dataset.summary.categories)
        <dynamic>[
          c.name,
          _number.format(c.amount),
          if (showPercent) c.percentage.toStringAsFixed(1),
          '${c.count}',
        ],
    ];

    if (data.isEmpty) {
      return pw.Text(
        'No transactions in the selected range.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }

    final alignments = <int, pw.Alignment>{};
    for (var i = 1; i < headers.length; i++) {
      alignments[i] = pw.Alignment.centerRight;
    }

    return pw.TableHelper.fromTextArray(
      context: context,
      headers: headers,
      data: data,
      headerCount: 1,
      headerDecoration: const pw.BoxDecoration(color: _accent),
      headerStyle: pw.TextStyle(
        fontSize: 9,
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 9),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FixedColumnWidth(110),
        if (showPercent) 2: const pw.FixedColumnWidth(90),
        if (showPercent) 3: const pw.FixedColumnWidth(60),
        if (!showPercent) 2: const pw.FixedColumnWidth(60),
      },
      cellAlignments: alignments,
    );
  }

  pw.Widget _pieChart(ReportDataset dataset) {
    final categories = dataset.summary.categories;
    final limited = categories.length > 6
        ? categories.sublist(0, 6)
        : categories;

    return pw.SizedBox(
      height: 210,
      child: pw.Chart(
        grid: pw.PieGrid(),
        datasets: [
          for (var i = 0; i < limited.length; i++)
            pw.PieDataSet(
              value: limited[i].amount <= 0 ? 0.001 : limited[i].amount,
              legend:
                  '${limited[i].name} ${limited[i].percentage.toStringAsFixed(1)}%',
              color: _palette[i % _palette.length],
            ),
        ],
      ),
    );
  }

  pw.Widget _transactionsTable(pw.Context context, ReportDataset dataset) {
    final config = dataset.config;
    final columns = ReportColumns.forConfig(config);
    final headers = ReportColumns.humanLabels(config);

    if (dataset.rows.isEmpty) {
      return pw.Text(
        'No transactions in the selected range.',
        style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
      );
    }

    final alignments = <int, pw.Alignment>{};
    final amountIndex = columns.indexOf(ReportColumns.amount);
    if (amountIndex >= 0) alignments[amountIndex] = pw.Alignment.centerRight;

    final data = [
      for (final row in dataset.rows)
        <dynamic>[
          for (final column in columns) _transactionCell(row, column),
        ],
    ];

    return pw.TableHelper.fromTextArray(
      context: context,
      headers: headers,
      data: data,
      headerCount: 1,
      headerDecoration: const pw.BoxDecoration(color: _accent),
      headerStyle: pw.TextStyle(
        fontSize: 7.5,
        color: PdfColors.white,
        fontWeight: pw.FontWeight.bold,
      ),
      cellStyle: const pw.TextStyle(fontSize: 7.5),
      oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey100),
      headerPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 4),
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 3, vertical: 3),
      columnWidths: _columnWidths(columns),
      cellAlignments: alignments,
      defaultColumnWidth: const pw.FlexColumnWidth(),
    );
  }

  Map<int, pw.TableColumnWidth> _columnWidths(List<String> columns) {
    final widths = <int, pw.TableColumnWidth>{};
    for (var i = 0; i < columns.length; i++) {
      widths[i] = switch (columns[i]) {
        ReportColumns.date => const pw.FixedColumnWidth(54),
        ReportColumns.category => const pw.FixedColumnWidth(64),
        ReportColumns.type => const pw.FixedColumnWidth(44),
        ReportColumns.amount => const pw.FixedColumnWidth(78),
        ReportColumns.currency => const pw.FixedColumnWidth(44),
        ReportColumns.paymentMethod => const pw.FixedColumnWidth(68),
        ReportColumns.notes => const pw.FlexColumnWidth(2),
        ReportColumns.description => const pw.FlexColumnWidth(3),
        _ => const pw.FlexColumnWidth(),
      };
    }
    return widths;
  }

  String _transactionCell(ReportRow row, String column) {
    switch (column) {
      case ReportColumns.date:
        return _isoDate.format(row.date);
      case ReportColumns.amount:
        return _number.format(row.amount);
      case ReportColumns.type:
        return row.type.name;
      case ReportColumns.description:
        return _clip(row.description, 70);
      case ReportColumns.category:
        return row.category;
      case ReportColumns.currency:
        return row.currency;
      case ReportColumns.paymentMethod:
        return row.paymentMethod.label;
      case ReportColumns.notes:
        return _clip(row.note, 160);
      default:
        return '';
    }
  }

  pw.Widget _footer(pw.Context context, ReportDataset dataset) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Expanded(
            child: pw.Text(
              'Contains sensitive financial information. Store and share securely.',
              style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey500),
          ),
        ],
      ),
    );
  }
}
