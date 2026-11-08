import 'package:excel/excel.dart';
import 'package:intl/intl.dart';

import '../models/export_config.dart';
import '../models/report_dataset.dart';
import 'report_writer.dart';

class XlsxReportWriter extends ReportWriter {
  const XlsxReportWriter();

  static const summarySheet = 'Summary';
  static const transactionsSheet = 'Transactions';

  static final _isoDate = DateFormat('yyyy-MM-dd');
  static final _isoDateTime = DateFormat('yyyy-MM-dd HH:mm');

  static CellStyle headerStyle() => CellStyle(
        backgroundColorHex: ExcelColor.teal,
        fontColorHex: ExcelColor.white,
        bold: true,
        fontSize: 11,
        horizontalAlign: HorizontalAlign.Center,
      );

  static CellStyle labelStyle() => CellStyle(bold: true);

  static CellStyle titleStyle() => CellStyle(bold: true, fontSize: 16);

  static CellStyle numericStyle() =>
      CellStyle(numberFormat: NumFormat.standard_4);

  @override
  Future<List<int>> write(
    ReportDataset dataset, {
    ReportProgressCallback? onProgress,
  }) async {
    final excel = Excel.createExcel();
    final breakdownSheet = dataset.config.groupBy.breakdownSheetName;

    _writeSummary(excel, dataset);
    await _writeTransactions(excel, dataset, onProgress);
    _writeBreakdown(excel, breakdownSheet, dataset);

    final defaultSheet = excel.getDefaultSheet();
    if (defaultSheet != null &&
        defaultSheet != summarySheet &&
        defaultSheet != transactionsSheet &&
        defaultSheet != breakdownSheet) {
      excel.delete(defaultSheet);
    }
    excel.setDefaultSheet(summarySheet);

    return excel.save() ?? <int>[];
  }

  void _set(
    Excel excel,
    String sheet,
    int row,
    int column,
    CellValue? value, {
    CellStyle? style,
  }) {
    excel.updateCell(
      sheet,
      CellIndex.indexByColumnRow(columnIndex: column, rowIndex: row),
      value,
      cellStyle: style,
    );
  }

  void _writeSummary(Excel excel, ReportDataset dataset) {
    final summary = dataset.summary;
    final numberStyle = numericStyle();
    var row = 0;

    void labelValue(String label, Object value, {CellStyle? style}) {
      _set(excel, summarySheet, row, 0, TextCellValue(label),
          style: labelStyle());
      _set(excel, summarySheet, row, 1, _objectValue(value), style: style);
      row++;
    }

    _set(excel, summarySheet, row, 0, TextCellValue(dataset.reportTitle),
        style: titleStyle());
    row += 2;

    labelValue('Date range', dataset.dateRangeLabel);
    labelValue('Generated', _isoDateTime.format(dataset.generatedAt));
    if (dataset.timezone.isNotEmpty) {
      labelValue('Timezone', dataset.timezone);
    }
    labelValue('Reporting currency', dataset.currencyCode);
    labelValue('Transactions', summary.transactionCount);
    row++;

    labelValue('Total spent', summary.totalExpenses, style: numberStyle);
    labelValue('Total income', summary.totalIncome, style: numberStyle);
    labelValue('Net balance', summary.netBalance, style: numberStyle);
    row++;

    _writeCategoryTable(excel, summarySheet, row, dataset);
    excel[summarySheet].setDefaultColumnWidth(24);
  }

  CellValue _objectValue(Object value) {
    if (value is int) return IntCellValue(value);
    if (value is double) return DoubleCellValue(value);
    return TextCellValue('$value');
  }

  void _writeCategoryTable(
    Excel excel,
    String sheetName,
    int startRow,
    ReportDataset dataset,
  ) {
    final showPercent = dataset.config.includeCategoryPercentages;
    final header = headerStyle();
    final numberStyle = numericStyle();

    final headers = <CellValue?>[
      TextCellValue('Category'),
      TextCellValue('Amount'),
      if (showPercent) TextCellValue('Percentage (%)'),
      TextCellValue('Count'),
    ];
    for (var c = 0; c < headers.length; c++) {
      _set(excel, sheetName, startRow, c, headers[c], style: header);
    }

    var rowIndex = startRow + 1;
    for (final category in dataset.summary.categories) {
      _set(excel, sheetName, rowIndex, 0, TextCellValue(category.name));
      _set(excel, sheetName, rowIndex, 1, DoubleCellValue(category.amount),
          style: numberStyle);
      var column = 2;
      if (showPercent) {
        _set(excel, sheetName, rowIndex, column,
            DoubleCellValue(category.percentage),
            style: numberStyle);
        column++;
      }
      _set(excel, sheetName, rowIndex, column,
          IntCellValue(category.count));
      rowIndex++;
    }
  }

  Future<void> _writeTransactions(
    Excel excel,
    ReportDataset dataset,
    ReportProgressCallback? onProgress,
  ) async {
    final config = dataset.config;
    final columns = ReportColumns.forConfig(config);
    final header = headerStyle();
    final numberStyle = numericStyle();

    final headers = ReportColumns.humanLabels(config);
    for (var c = 0; c < headers.length; c++) {
      _set(excel, transactionsSheet, 0, c, TextCellValue(headers[c]),
          style: header);
    }

    final amountColumn = columns.indexOf(ReportColumns.amount);
    final total = dataset.rows.length;

    for (var i = 0; i < total; i++) {
      final row = dataset.rows[i];
      final rowIndex = i + 1;
      for (var c = 0; c < columns.length; c++) {
        _set(
          excel,
          transactionsSheet,
          rowIndex,
          c,
          _cellValue(row, columns[c]),
          style: c == amountColumn ? numberStyle : null,
        );
      }
      if ((i + 1) % 200 == 0) {
        onProgress?.call(i + 1, total);
        await Future<void>.delayed(Duration.zero);
      }
    }
    onProgress?.call(total, total);
    excel[transactionsSheet].setDefaultColumnWidth(20);
  }

  void _writeBreakdown(
    Excel excel,
    String sheetName,
    ReportDataset dataset,
  ) {
    final isMonthly = dataset.config.groupBy == ExportGroupBy.month;
    _set(
      excel,
      sheetName,
      0,
      0,
      TextCellValue(isMonthly ? 'Monthly Breakdown' : 'Category Breakdown'),
      style: titleStyle(),
    );
    _writeCategoryTable(excel, sheetName, 2, dataset);
    excel[sheetName].setDefaultColumnWidth(22);
  }

  CellValue? _cellValue(ReportRow row, String column) {
    switch (column) {
      case ReportColumns.date:
        return TextCellValue(_isoDate.format(row.date));
      case ReportColumns.amount:
        return DoubleCellValue(row.amount);
      case ReportColumns.type:
        return TextCellValue(row.type.name);
      case ReportColumns.description:
        return TextCellValue(row.description);
      case ReportColumns.category:
        return TextCellValue(row.category);
      case ReportColumns.currency:
        return TextCellValue(row.currency);
      case ReportColumns.paymentMethod:
        return TextCellValue(row.paymentMethod.label);
      case ReportColumns.notes:
        return TextCellValue(row.note);
      case ReportColumns.id:
        return TextCellValue(row.id);
      default:
        return null;
    }
  }
}
