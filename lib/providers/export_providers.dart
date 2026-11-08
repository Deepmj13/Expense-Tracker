import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/export_config.dart';
import '../models/export_job.dart';
import '../models/transaction_model.dart';
import '../services/export_service.dart';
import '../services/export_storage_service.dart';
import 'app_providers.dart';

final exportStorageServiceProvider =
    Provider<ExportStorageService>((_) => ExportStorageService.instance);

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(
    storage: ref.watch(exportStorageServiceProvider),
    database: ref.watch(dbServiceProvider),
  );
});

class ExportState {
  const ExportState({
    this.isExporting = false,
    this.progress = 0,
    this.job,
    this.error,
  });

  final bool isExporting;
  final double progress;
  final ExportJob? job;
  final String? error;

  bool get isDone => job?.status == ExportJobStatus.completed;
  bool get isFailed => job?.status == ExportJobStatus.failed;

  ExportState copyWith({
    bool? isExporting,
    double? progress,
    ExportJob? job,
    String? error,
    bool clearJob = false,
    bool clearError = false,
  }) {
    return ExportState(
      isExporting: isExporting ?? this.isExporting,
      progress: progress ?? this.progress,
      job: clearJob ? null : (job ?? this.job),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ExportController extends StateNotifier<ExportState> {
  ExportController(this._service) : super(const ExportState());

  final ExportService _service;

  Future<bool> generate({
    required ExportConfig config,
    required AppUser user,
    required List<TransactionModel> items,
  }) async {
    if (state.isExporting) return false;

    state = const ExportState(isExporting: true);

    try {
      final job = await _service.run(
        config: config,
        user: user,
        items: items,
        onUpdate: (job) {
          state = state.copyWith(
            job: job,
            progress: job.progress / 100,
            isExporting: !job.status.isTerminal,
            clearError: true,
          );
        },
      );
      state = state.copyWith(
        isExporting: false,
        job: job,
        progress: job.progress / 100,
      );
      return job.status == ExportJobStatus.completed;
    } catch (error) {
      state = state.copyWith(isExporting: false, error: error.toString());
      return false;
    }
  }

  void reset() => state = const ExportState();
}

final exportControllerProvider =
    StateNotifierProvider<ExportController, ExportState>((ref) {
  return ExportController(ref.watch(exportServiceProvider));
});
