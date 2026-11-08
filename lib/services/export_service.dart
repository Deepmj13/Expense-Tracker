import 'package:uuid/uuid.dart';

import '../models/app_user.dart';
import '../models/export_config.dart';
import '../models/export_job.dart';
import '../models/transaction_model.dart';
import 'csv_report_writer.dart';
import 'database_service.dart';
import 'export_file_namer.dart';
import 'export_storage_service.dart';
import 'json_report_writer.dart';
import 'pdf_report_writer.dart';
import 'report_builder.dart';
import 'report_writer.dart';
import 'xlsx_report_writer.dart';

class ExportThrottledException implements Exception {
  const ExportThrottledException(this.retryAfter);

  final Duration retryAfter;

  @override
  String toString() => retryAfter.inMilliseconds <= 0
      ? 'An export is already running.'
      : 'Please wait ${retryAfter.inSeconds + 1}s before exporting again.';
}

class ExportFailedException implements Exception {
  const ExportFailedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ExportService {
  ExportService({
    required this.storage,
    required this.database,
    this.throttle = const Duration(seconds: 3),
    this.maxStoredJobs = 20,
    String Function()? idGenerator,
  }) : _idGenerator = idGenerator ?? (() => const Uuid().v4());

  final ExportStorageService storage;
  final DatabaseService database;
  final Duration throttle;
  final int maxStoredJobs;
  final String Function() _idGenerator;

  static const jobsKey = 'export_jobs';

  static const _builder = ReportBuilder();

  bool _isExporting = false;
  DateTime? _lastStartedAt;

  bool get isExporting => _isExporting;

  Duration get throttleRemaining {
    final last = _lastStartedAt;
    if (last == null) return Duration.zero;
    final remaining = throttle - DateTime.now().difference(last);
    return remaining.isNegative ? Duration.zero : remaining;
  }

  ReportWriter writerFor(ExportFormat format) => switch (format) {
        ExportFormat.csv => const CsvReportWriter(),
        ExportFormat.xlsx => const XlsxReportWriter(),
        ExportFormat.pdf => const PdfReportWriter(),
        ExportFormat.json => const JsonReportWriter(),
      };

  List<ExportJob> storedJobs() {
    try {
      final raw = database.appBox().get(jobsKey);
      if (raw is! List) return const [];
      return [
        for (final entry in raw)
          if (entry is Map) ExportJob.fromMap(entry),
      ];
    } catch (_) {
      return const [];
    }
  }

  Future<ExportJob> run({
    required ExportConfig config,
    required AppUser user,
    required List<TransactionModel> items,
    required void Function(ExportJob job) onUpdate,
  }) async {
    if (_isExporting) {
      throw const ExportThrottledException(Duration.zero);
    }
    final remaining = throttleRemaining;
    if (remaining > Duration.zero) {
      throw ExportThrottledException(remaining);
    }

    _isExporting = true;
    _lastStartedAt = DateTime.now();

    var job = ExportJob(
      id: _idGenerator(),
      userId: user.id,
      format: config.format,
      config: config,
      status: ExportJobStatus.queued,
      createdAt: _lastStartedAt!,
    );
    onUpdate(job);

    try {
      job = job.copyWith(status: ExportJobStatus.processing, progress: 5);
      onUpdate(job);

      final errors = config.validate();
      if (errors.isNotEmpty) throw ExportFailedException(errors.first);

      final dataset = _builder.build(
        items: items,
        config: config,
        user: user,
        timezone: localTimeZone(),
        generatedAt: job.createdAt,
      );

      job = job.copyWith(progress: 10);
      onUpdate(job);

      final bytes = await writerFor(config.format).write(
        dataset,
        onProgress: (done, total) {
          final ratio = total <= 0 ? 1.0 : done / total;
          final progress = (10 + ratio * 80).round().clamp(10, 90);
          if (progress == job.progress) return;
          job = job.copyWith(progress: progress);
          onUpdate(job);
        },
      );

      job = job.copyWith(progress: 95);
      onUpdate(job);

      final fileName = ExportFileNamer.build(config);
      final path = await storage.save(fileName, bytes);
      final completedAt = DateTime.now();

      job = job.copyWith(
        status: ExportJobStatus.completed,
        progress: 100,
        filePath: path,
        fileName: fileName,
        fileSize: bytes.length,
        completedAt: completedAt,
        expiresAt: completedAt.add(ExportStorageService.ttl),
      );
      await _persist(job);
      onUpdate(job);
      return job;
    } catch (error) {
      final failed = job.copyWith(
        status: ExportJobStatus.failed,
        errorMessage: error.toString(),
      );
      await _persist(failed);
      onUpdate(failed);
      return failed;
    } finally {
      _isExporting = false;
    }
  }

  Future<void> startupCleanup() async {
    await storage.cleanupExpired();

    final jobs = storedJobs();
    if (jobs.isEmpty) return;

    final now = DateTime.now();
    final updated = <ExportJob>[];
    for (final job in jobs) {
      if (job.status == ExportJobStatus.completed &&
          job.expiresAt != null &&
          job.expiresAt!.isBefore(now)) {
        await storage.delete(job.filePath);
        updated.add(job.copyWith(status: ExportJobStatus.expired));
      } else {
        updated.add(job);
      }
    }
    await _saveAll(updated);
  }

  Future<void> _persist(ExportJob job) async {
    final jobs = storedJobs().where((j) => j.id != job.id).toList()
      ..add(job)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    await _saveAll(jobs.take(maxStoredJobs).toList());
  }

  Future<void> _saveAll(List<ExportJob> jobs) async {
    try {
      await database
          .appBox()
          .put(jobsKey, [for (final job in jobs) job.toMap()]);
    } catch (_) {}
  }

  static String localTimeZone() {
    final offset = DateTime.now().timeZoneOffset;
    final sign = offset.isNegative ? '-' : '+';
    final total = offset.abs();
    final hours = total.inHours.toString().padLeft(2, '0');
    final minutes = (total.inMinutes % 60).toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minutes';
  }
}
