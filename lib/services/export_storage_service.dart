import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'export_file_namer.dart';

class ExportStorageService {
  ExportStorageService({Directory? root}) : _root = root;

  static final ExportStorageService instance = ExportStorageService();

  static const folderName = 'exports';
  static const ttl = Duration(hours: 24);

  final Directory? _root;
  Future<Directory>? _resolved;

  Future<Directory> directory() => _resolved ??= _resolve();

  Future<Directory> _resolve() async {
    final root = _root;
    if (root != null) {
      if (!await root.exists()) await root.create(recursive: true);
      return root;
    }
    final base = await getApplicationDocumentsDirectory();
    final dir =
        Directory('${base.path}${Platform.pathSeparator}$folderName');
    if (!await dir.exists()) await dir.create(recursive: true);
    return dir;
  }

  Future<String> save(String fileName, List<int> bytes) async {
    final dir = await directory();
    final safeName = ExportFileNamer.safeFileName(fileName);
    final file = File('${dir.path}${Platform.pathSeparator}$safeName');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }

  Future<int?> sizeOf(String? path) async {
    if (path == null) return null;
    final file = File(path);
    if (!await file.exists()) return null;
    return file.length();
  }

  Future<bool> exists(String? path) async {
    if (path == null) return false;
    return File(path).exists();
  }

  Future<bool> delete(String? path) async {
    if (path == null) return false;
    final file = File(path);
    if (!await file.exists()) return false;
    try {
      await file.delete();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> cleanupExpired({Duration? maxAge}) async {
    final age = maxAge ?? ttl;
    final cutoff = DateTime.now().subtract(age);

    final dir = await directory();
    await for (final entity in dir.list()) {
      if (entity is! File) continue;
      try {
        final stat = await entity.stat();
        if (stat.modified.isBefore(cutoff)) {
          await entity.delete();
        }
      } catch (_) {}
    }
  }
}
