import 'dart:convert';
import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:intl/intl.dart';

import '../models/export_config.dart';
import '../models/report_dataset.dart';
import 'report_writer.dart';

class CsvSanitizer {
  static final _formulaTrigger =
      RegExp(r'^\s*[=+\-@\t\r]');

  static String escape(String value) {
    if (value.isEmpty) return value;
    if (_formulaTrigger.hasMatch(value)) return "'$value";
    return value;
  }
}

class CsvReportWriter extends ReportWriter {
  const CsvReportWriter();

  static const utf8Bom = <int>[0xEF, 0xBB, 0xBF];
  static const eol = '\r\n';
  static const _chunkSize = 250;

  static final _isoDate = DateFormat('yyyy-MM-dd');

  @override
  Future<List<int>> write(
    ReportDataset dataset, {
    ReportProgressCallback? onProgress,
  }) async {
    final config = dataset.config;
    final labels = ReportColumns.forConfig(config);
    const converter = ListToCsvConverter(eol: eol);

    final out = BytesBuilder(copy: false)..add(utf8Bom);

    final header = StringBuffer();
    converter.convertSingleRow(header, labels);
    out
      ..add(utf8.encode(header.toString()))
      ..add(utf8.encode(eol));

    final total = dataset.rows.length;
    final buffer = StringBuffer();
    var bufferedRows = 0;
    var wroteAnyRow = false;

    for (var i = 0; i < total; i++) {
      if (wroteAnyRow) buffer.write(eol);
      converter.convertSingleRow(
        buffer,
        _cells(dataset.rows[i], config),
      );
      wroteAnyRow = true;
      bufferedRows++;

      if (bufferedRows >= _chunkSize) {
        out.add(utf8.encode(buffer.toString()));
        buffer.clear();
        bufferedRows = 0;
        onProgress?.call(i + 1, total);
        await Future<void>.delayed(Duration.zero);
      }
    }

    if (bufferedRows > 0) out.add(utf8.encode(buffer.toString()));
    onProgress?.call(total, total);
    return out.takeBytes();
  }

  List<dynamic> _cells(ReportRow row, ExportConfig config) {
    return [
      for (final column in ReportColumns.forConfig(config))
        _cell(row, column),
    ];
  }

  dynamic _cell(ReportRow row, String column) {
    switch (column) {
      case ReportColumns.date:
        return _isoDate.format(row.date);
      case ReportColumns.amount:
        // Left raw on purpose: it is a number, not a formula-capable text
        // cell, and escaping it would force Excel to treat it as text.
        return row.amount.toStringAsFixed(2);
      case ReportColumns.type:
        return row.type.name;
      case ReportColumns.description:
        return CsvSanitizer.escape(row.description);
      case ReportColumns.category:
        return CsvSanitizer.escape(row.category);
      case ReportColumns.currency:
        return CsvSanitizer.escape(row.currency);
      case ReportColumns.paymentMethod:
        return CsvSanitizer.escape(row.paymentMethod.label);
      case ReportColumns.notes:
        return CsvSanitizer.escape(row.note);
      case ReportColumns.id:
        return CsvSanitizer.escape(row.id);
      default:
        return '';
    }
  }
}
