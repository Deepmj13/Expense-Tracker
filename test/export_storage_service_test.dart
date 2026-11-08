import 'dart:io';

import 'package:expense_tracker/services/export_storage_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late ExportStorageService storage;

  setUp(() {
    root = Directory.systemTemp.createTempSync('export_storage_test');
    storage = ExportStorageService(root: root);
  });

  tearDown(() {
    if (root.existsSync()) root.deleteSync(recursive: true);
  });

  test('creates the exports folder on demand', () async {
    final dir = await storage.directory();
    expect(dir.existsSync(), isTrue);
    expect(dir.path, root.path);
  });

  test('save writes the bytes and returns an absolute path', () async {
    final path = await storage.save('Expenses_2026-01-01_to_2026-01-31.csv',
        [1, 2, 3, 4]);

    expect(path, endsWith('Expenses_2026-01-01_to_2026-01-31.csv'));
    expect(File(path).existsSync(), isTrue);
    expect(File(path).readAsBytesSync(), [1, 2, 3, 4]);
    expect(await storage.sizeOf(path), 4);
  });

  test('save never lets a file name escape the exports folder', () async {
    final path = await storage.save('../../etc/passwd.csv', [9]);

    expect(path.startsWith(root.path), isTrue);
    expect(path.contains('..'), isFalse);
    expect(path.contains('/'), isFalse);
    expect(File(path).existsSync(), isTrue);
  });

  test('sizeOf returns null for a missing file', () async {
    expect(await storage.sizeOf(null), isNull);
    expect(await storage.sizeOf('${root.path}${Platform.pathSeparator}nope'),
        isNull);
    expect(await storage.exists(null), isFalse);
  });

  test('delete removes an existing file and reports it', () async {
    final path = await storage.save('report.csv', [1]);

    expect(await storage.delete(path), isTrue);
    expect(File(path).existsSync(), isFalse);
    expect(await storage.delete(path), isFalse);
    expect(await storage.delete(null), isFalse);
  });

  test('cleanupExpired only removes files older than the TTL', () async {
    final stale = await storage.save('stale.csv', [1]);
    final fresh = await storage.save('fresh.csv', [2]);

    File(stale)
        .setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 25)));

    await storage.cleanupExpired();

    expect(File(stale).existsSync(), isFalse);
    expect(File(fresh).existsSync(), isTrue);
  });

  test('cleanupExpired honours a custom max age', () async {
    final file = await storage.save('recent.csv', [1]);
    File(file)
        .setLastModifiedSync(DateTime.now().subtract(const Duration(hours: 2)));

    await storage.cleanupExpired(maxAge: const Duration(hours: 1));

    expect(File(file).existsSync(), isFalse);
  });

  test('a second root does not leak into the first', () async {
    final other = Directory.systemTemp.createTempSync('export_storage_other');
    addTearDown(() {
      if (other.existsSync()) other.deleteSync(recursive: true);
    });

    final a = await storage.save('a.csv', [1]);
    final b = await ExportStorageService(root: other).save('b.csv', [2]);

    expect(File(a).parent.path, root.path);
    expect(File(b).parent.path, other.path);
  });
}
