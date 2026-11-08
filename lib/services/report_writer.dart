import '../models/report_dataset.dart';

typedef ReportProgressCallback = void Function(int completed, int total);

abstract class ReportWriter {
  const ReportWriter();

  Future<List<int>> write(
    ReportDataset dataset, {
    ReportProgressCallback? onProgress,
  });
}
