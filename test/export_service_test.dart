import 'dart:io';

import 'package:expense_tracker/models/export_config.dart';
import 'package:expense_tracker/models/export_job.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/export_service.dart';
import 'package:expense_tracker/services/export_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

import 'helpers/export_fixtures.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory temp;
  late DatabaseService db;
  late ExportStorageService storage;
  late ExportService service;

  ExportConfig config({
    ExportFormat format = ExportFormat.csv,
    DateTime? from,
    DateTime? to,
  }) {
    return ExportConfig(
      format: format,
      datePreset: DateRangePreset.custom,
      dateFrom: from ?? DateTime(2026, 1, 1),
      dateTo: to ?? DateTime(2026, 12, 31, 23, 59, 59, 999),
    );
  }

  setUp(() async {
    temp = Directory.systemTemp.createTempSync('export_service_test');
    Hive.init(temp.path);
    db = DatabaseService();
    await db.init();
    storage = ExportStorageService(
      root: Directory('${temp.path}${Platform.pathSeparator}exports'),
    );
    service = ExportService(
      storage: storage,
      database: db,
      throttle: Duration.zero,
      idGenerator: () => 'job-1',
    );
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    if (temp.existsSync()) temp.deleteSync(recursive: true);
  });

  Future<ExportJob> run({ExportConfig? formatConfig}) async {
    return service.run(
      config: formatConfig ?? config(),
      user: fixtureUser(),
      items: [
        fixtureTransaction(date: DateTime(2026, 1, 5), amount: 100),
        fixtureTransaction(
          id: 't2',
          date: DateTime(2026, 1, 6),
          amount: 250.5,
          category: 'Travel',
        ),
      ],
      onUpdate: (_) {},
    );
  }

  group('successful runs', () {
    test('writes a CSV file and reports a completed job', () async {
      final job = await run();

      expect(job.status, ExportJobStatus.completed);
      expect(job.id, 'job-1');
      expect(job.progress, 100);
      expect(job.fileName, 'Expenses_2026-01-01_to_2026-12-31.csv');
      expect(job.fileSize, greaterThan(0));
      expect(job.completedAt, isNotNull);
      expect(job.expiresAt!.difference(job.completedAt!),
          ExportStorageService.ttl);
      expect(await storage.exists(job.filePath), isTrue);
    });

    for (final format in ExportFormat.values) {
      test('produces a ${format.label} file', () async {
        final job = await run(formatConfig: config(format: format));

        expect(job.status, ExportJobStatus.completed);
        expect(job.fileName, endsWith('.${format.extension}'));
        expect(await storage.exists(job.filePath), isTrue);
        expect(job.fileSize, greaterThan(0));
      });
    }

    test('reports monotonically increasing progress that ends at 100',
        () async {
      final updates = <int>[];
      await service.run(
        config: config(),
        user: fixtureUser(),
        items: [
          for (var i = 0; i < 500; i++)
            fixtureTransaction(date: DateTime(2026, 1, 5), id: 't$i'),
        ],
        onUpdate: (job) => updates.add(job.progress),
      );

      expect(updates, isNotEmpty);
      expect(updates, orderedEquals([...updates]..sort()));
      expect(updates.last, 100);
      expect(updates.first, lessThanOrEqualTo(updates.last));
    });

    test('persists the job record', () async {
      await run();

      final stored = service.storedJobs();
      expect(stored, hasLength(1));
      expect(stored.first.id, 'job-1');
      expect(stored.first.status, ExportJobStatus.completed);
      expect(stored.first.fileName, endsWith('.csv'));
    });
  });

  group('failures', () {
    test('an invalid date range produces a failed job', () async {
      final job = await run(
        formatConfig: config(from: DateTime(2026, 5, 1), to: DateTime(2026, 1, 1)),
      );

      expect(job.status, ExportJobStatus.failed);
      expect(job.errorMessage, contains('Start date'));
      expect(job.filePath, isNull);
      expect(service.storedJobs().single.status, ExportJobStatus.failed);
    });

    test('the service is released after a failure', () async {
      await run(
        formatConfig: config(from: DateTime(2026, 5, 1), to: DateTime(2026, 1, 1)),
      );

      expect(service.isExporting, isFalse);
      expect(service.throttleRemaining, Duration.zero);
    });

    test('a failed run leaves no orphan file', () async {
      final job = await run(
        formatConfig: config(from: DateTime(2026, 5, 1), to: DateTime(2026, 1, 1)),
      );

      expect(await storage.exists(job.filePath), isFalse);
      final leftovers = await (await storage.directory()).list().toList();
      expect(leftovers, isEmpty);
    });
  });

  group('throttling', () {
    test('rejects a second export inside the throttle window', () async {
      final throttled = ExportService(
        storage: storage,
        database: db,
        throttle: const Duration(seconds: 30),
        idGenerator: () => 'job-x',
      );

      await throttled.run(
        config: config(),
        user: fixtureUser(),
        items: [fixtureTransaction(date: DateTime(2026, 1, 5))],
        onUpdate: (_) {},
      );

      expect(throttled.throttleRemaining, greaterThan(Duration.zero));

      await expectLater(
        throttled.run(
          config: config(),
          user: fixtureUser(),
          items: [fixtureTransaction(date: DateTime(2026, 1, 5))],
          onUpdate: (_) {},
        ),
        throwsA(isA<ExportThrottledException>()),
      );
    });

    test('a zero throttle allows back to back exports', () async {
      final first = await run();
      final second = await run();

      expect(first.status, ExportJobStatus.completed);
      expect(second.status, ExportJobStatus.completed);
      expect(service.storedJobs(), hasLength(1),
          reason: 'the newer job replaces the older record');
    });
  });

  group('startupCleanup', () {
    test('deletes expired files and marks their jobs expired', () async {
      final job = await run();
      final path = job.filePath!;

      final expired = ExportJob(
        id: 'old-job',
        userId: 'user-1',
        format: ExportFormat.csv,
        config: config(),
        status: ExportJobStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        filePath: path,
        fileName: job.fileName,
        fileSize: job.fileSize,
        completedAt: DateTime.now().subtract(const Duration(days: 3)),
        expiresAt: DateTime.now().subtract(const Duration(days: 2)),
      );
      await db.appBox().put(ExportService.jobsKey, [expired.toMap()]);

      await service.startupCleanup();

      expect(await storage.exists(path), isFalse);
      final stored = service.storedJobs().single;
      expect(stored.status, ExportJobStatus.expired);
      expect(stored.id, 'old-job');
    });

    test('keeps files and jobs that are still within the TTL', () async {
      final job = await run();

      await service.startupCleanup();

      expect(await storage.exists(job.filePath), isTrue);
      final stored = service.storedJobs().single;
      expect(stored.status, ExportJobStatus.completed);
      expect(stored.id, 'job-1');
    });

    test('is a no-op when nothing has been exported', () async {
      await service.startupCleanup();
      expect(service.storedJobs(), isEmpty);
    });
  });

  test('localTimeZone renders a UTC offset', () {
    expect(ExportService.localTimeZone(), matches(RegExp(r'^UTC[+-]\d{2}:\d{2}$')));
  });
}
