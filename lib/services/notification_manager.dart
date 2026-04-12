import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/transaction_model.dart';
import '../models/transaction_type.dart';
import '../services/notification_channel_service.dart';
import '../services/notification_parser_service.dart';
import '../core/constants/notification_apps.dart';
import '../providers/app_providers.dart';

class NotificationManager {
  NotificationManager(this._ref);

  final Ref _ref;
  NotificationParserService? _parserService;
  NotificationChannelService? _channelService;

  Future<void> initialize() async {
    if (_parserService != null) return;

    _channelService = NotificationChannelService();

    final isEnabled = await _channelService!.isAutoAddEnabled();
    if (!isEnabled) return;

    final hasAccess = await _channelService!.isNotificationAccessEnabled();
    if (!hasAccess) return;

    final dbService = _ref.read(dbServiceProvider);
    final transactionService = _ref.read(transactionServiceProvider);

    _parserService = NotificationParserService(
      databaseService: dbService,
      transactionService: transactionService,
    );

    await _channelService!
        .setMonitoredApps(NotificationApps.defaultPackagePatterns);

    _parserService!.onTransactionAdded = _onTransactionAdded;
    _parserService!.onTransactionError = _onTransactionError;
  }

  void _onTransactionAdded(TransactionModel transaction) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showAddedSnackbar(transaction);
    });
  }

  void _onTransactionError(String error) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showErrorSnackbar(error);
    });
  }

  void _showErrorSnackbar(String error) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final colorScheme = Theme.of(context).colorScheme;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  error,
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 8,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (_) {}
  }

  void _showAddedSnackbar(TransactionModel transaction) {
    try {
      final context = navigatorKey.currentContext;
      if (context == null) return;

      final currencySymbol = _ref.read(currencySymbolProvider);
      final colorScheme = Theme.of(context).colorScheme;
      final isIncome = transaction.type == TransactionType.income;

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (isIncome ? Colors.green : Colors.orange)
                      .withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                  color: isIncome ? Colors.green : Colors.orange,
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Transaction Added',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      '${transaction.title} - $currencySymbol${transaction.amount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          backgroundColor: colorScheme.surface,
          elevation: 8,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Undo',
            textColor: colorScheme.primary,
            onPressed: () async {
              final userId = _ref
                  .read(dbServiceProvider)
                  .appBox()
                  .get('current_user_id') as String?;
              if (userId != null) {
                await _ref
                    .read(transactionServiceProvider)
                    .delete(transaction.id);
                _ref.read(transactionsControllerProvider.notifier).load(userId);
              }
            },
          ),
        ),
      );
    } catch (_) {}
  }

  Future<void> dispose() async {
    _parserService?.dispose();
    _channelService?.dispose();
  }
}

final navigatorKey = GlobalKey<NavigatorState>();

final notificationManagerProvider = Provider<NotificationManager>((ref) {
  final manager = NotificationManager(ref);
  ref.onDispose(() => manager.dispose());
  return manager;
});
