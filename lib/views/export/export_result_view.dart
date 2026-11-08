import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../models/export_config.dart';
import '../../models/export_job.dart';

class ExportResultView extends ConsumerWidget {
  const ExportResultView({
    super.key,
    required this.job,
    required this.onExportAnother,
  });

  final ExportJob job;
  final VoidCallback onExportAnother;

  static const _successIcons = {
    ExportJobStatus.completed: Icons.check_circle,
    ExportJobStatus.failed: Icons.error,
    ExportJobStatus.expired: Icons.timer_off,
    ExportJobStatus.queued: Icons.hourglass_empty,
    ExportJobStatus.processing: Icons.hourglass_top,
  };

  Future<void> _share(BuildContext context) async {
    final path = job.filePath;
    if (path == null) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              path,
              mimeType: job.format.mimeType,
              name: job.fileName ?? 'export',
            ),
          ],
          title: 'Expense report',
        ),
      );
    } catch (error) {
      if (!context.mounted) return;
      _snack(context, 'Could not share the file: $error');
    }
  }

  Future<void> _save(BuildContext context) async {
    final path = job.filePath;
    if (path == null) return;
    try {
      final file = File(path);
      if (!await file.exists()) {
        if (context.mounted) {
          _snack(context, 'This export has expired. Generate a new one.');
        }
        return;
      }
      final bytes = await file.readAsBytes();
      if (!context.mounted) return;
      await FilePicker.platform.saveFile(
        dialogTitle: 'Save expense report',
        fileName: job.fileName ?? 'expense_export',
        bytes: bytes,
        type: FileType.custom,
        allowedExtensions: [job.format.extension],
      );
    } catch (error) {
      if (!context.mounted) return;
      _snack(context, 'Could not save the file: $error');
    }
  }

  Future<void> _print(BuildContext context) async {
    final path = job.filePath;
    if (path == null) return;
    try {
      final bytes = await File(path).readAsBytes();
      if (!context.mounted) return;
      await Printing.layoutPdf(
        name: job.fileName ?? 'expense_report',
        onLayout: (_) async => Uint8List.fromList(bytes),
      );
    } catch (error) {
      if (!context.mounted) return;
      _snack(context, 'Printing is not available here: $error');
    }
  }

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  String _sizeLabel(int? bytes) {
    if (bytes == null) return '--';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  String _expiryLabel(ExportJob job) {
    final expiresAt = job.expiresAt;
    if (expiresAt == null) return '';
    final remaining = expiresAt.difference(DateTime.now());
    if (remaining.isNegative) return 'Expired';
    final hours = remaining.inHours;
    if (hours >= 1) return 'Available for $hours more hours';
    return 'Available for ${remaining.inMinutes} more minutes';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final succeeded = job.status == ExportJobStatus.completed &&
        job.filePath != null;

    final icon = _successIcons[job.status] ?? Icons.error;
    final iconColor = succeeded ? Colors.green : colorScheme.error;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 48, color: iconColor),
              const SizedBox(height: 12),
              Text(
                succeeded ? 'Report ready' : 'Export failed',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              if (succeeded) ...[
                const SizedBox(height: 6),
                Text(
                  job.fileName ?? '',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${job.format.label}  ·  ${_sizeLabel(job.fileSize)}  ·  '
                  '${_expiryLabel(job)}',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
              ] else if (job.errorMessage != null) ...[
                const SizedBox(height: 8),
                Text(
                  job.errorMessage!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.error,
                      ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (succeeded) ...[
          FilledButton.icon(
            onPressed: () => _share(context),
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => _save(context),
            icon: const Icon(Icons.save_alt),
            label: const Text('Save to device'),
          ),
          if (job.format == ExportFormat.pdf) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _print(context),
              icon: const Icon(Icons.print_outlined),
              label: const Text('Print / save as PDF'),
            ),
          ],
        ] else
          FilledButton.icon(
            onPressed: onExportAnother,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        const SizedBox(height: 4),
        TextButton(
          onPressed: onExportAnother,
          child: Text(succeeded ? 'Export another' : 'Back to settings'),
        ),
      ],
    );
  }
}
