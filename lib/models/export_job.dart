import 'export_config.dart';

enum ExportJobStatus {
  queued,
  processing,
  completed,
  failed,
  expired;

  bool get isTerminal =>
      this == ExportJobStatus.completed ||
      this == ExportJobStatus.failed ||
      this == ExportJobStatus.expired;

  String get label => switch (this) {
        ExportJobStatus.queued => 'Queued',
        ExportJobStatus.processing => 'Processing',
        ExportJobStatus.completed => 'Completed',
        ExportJobStatus.failed => 'Failed',
        ExportJobStatus.expired => 'Expired',
      };
}

class ExportJob {
  const ExportJob({
    required this.id,
    required this.userId,
    required this.format,
    required this.config,
    required this.status,
    required this.createdAt,
    this.progress = 0,
    this.filePath,
    this.fileName,
    this.fileSize,
    this.completedAt,
    this.expiresAt,
    this.errorMessage,
  });

  final String id;
  final String userId;
  final ExportFormat format;
  final ExportConfig config;
  final ExportJobStatus status;
  final int progress;
  final String? filePath;
  final String? fileName;
  final int? fileSize;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? expiresAt;
  final String? errorMessage;

  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  bool get canRetry =>
      status == ExportJobStatus.failed ||
      status == ExportJobStatus.expired ||
      status == ExportJobStatus.queued;

  ExportJob copyWith({
    ExportJobStatus? status,
    int? progress,
    String? filePath,
    String? fileName,
    int? fileSize,
    DateTime? completedAt,
    DateTime? expiresAt,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ExportJob(
      id: id,
      userId: userId,
      format: format,
      config: config,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      filePath: filePath ?? this.filePath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      completedAt: completedAt ?? this.completedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'userId': userId,
        'format': format.name,
        'filters': config.toMap(),
        'status': status.name,
        'progress': progress,
        'filePath': filePath,
        'fileName': fileName,
        'fileSize': fileSize,
        'createdAt': createdAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'expiresAt': expiresAt?.toIso8601String(),
        'errorMessage': errorMessage,
      };

  factory ExportJob.fromMap(Map<dynamic, dynamic> map) {
    DateTime? parseDate(dynamic raw) =>
        raw is String ? DateTime.tryParse(raw) : null;

    return ExportJob(
      id: map['id'] as String,
      userId: map['userId'] as String? ?? '',
      format: ExportFormat.values.firstWhere(
        (e) => e.name == map['format'],
        orElse: () => ExportFormat.csv,
      ),
      config: map['filters'] is Map
          ? ExportConfig.fromMap(map['filters'] as Map)
          : ExportConfig.current(),
      status: ExportJobStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => ExportJobStatus.failed,
      ),
      progress: (map['progress'] as num?)?.toInt() ?? 0,
      filePath: map['filePath'] as String?,
      fileName: map['fileName'] as String?,
      fileSize: (map['fileSize'] as num?)?.toInt(),
      createdAt: parseDate(map['createdAt']) ?? DateTime.now(),
      completedAt: parseDate(map['completedAt']),
      expiresAt: parseDate(map['expiresAt']),
      errorMessage: map['errorMessage'] as String?,
    );
  }
}
