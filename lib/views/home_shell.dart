import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/app_user.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/app_providers.dart';
import '../services/notification_service.dart';
import '../services/sms_sync_manager.dart';
import '../services/sms_sync_preference_service.dart';
import 'budget/budget_settings_sheet.dart';
import 'dashboard/dashboard_view.dart';
import 'onboarding/notification_permission_dialog.dart';
import 'onboarding/sms_sync_dialog.dart';
import '../../services/permission_service.dart';
import 'reports/reports_view.dart';
import 'settings/settings_view.dart';
import 'transactions/transaction_form_sheet.dart';
import 'transactions/transactions_view.dart';

class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key, required this.user});

  final AppUser user;

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell>
    with WidgetsBindingObserver {
  int _index = 0;
  bool _initialized = false;

  static final _pages = [
    const DashboardView(),
    const TransactionsView(),
    const ReportsView(),
    const SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _onAppResumed();
    }
  }

  Future<void> _onAppResumed() async {
    final syncManagerAsync = await ref.read(smsSyncManagerProvider.future);
    await syncManagerAsync.setLastAppOpenTime(DateTime.now());
    await syncManagerAsync.onAppOpen();
    await syncManagerAsync.checkAndSendReminder();
    await _performSmsSync(syncManagerAsync, showSnackBar: false);
  }

  Future<void> _initialize() async {
    if (_initialized) return;
    _initialized = true;
    await ref
        .read(transactionsControllerProvider.notifier)
        .load(widget.user.id);
    _checkBudgetAlerts();
    await _checkSmsSync();
    await _checkNotificationPermission();
    _onAppResumed();
  }

  Future<void> _checkNotificationPermission() async {
    final syncManagerAsync = await ref.read(smsSyncManagerProvider.future);
    final prefs = syncManagerAsync.getPreferences();

    if (!prefs.notificationPermissionAsked) {
      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => const NotificationPermissionDialog(),
      );

      if (result == true) {
        await NotificationService.instance.requestPermission();
      }

      await syncManagerAsync.setNotificationPermissionAsked(true);

      final granted = await NotificationService.instance.isPermissionGranted();
      if (!granted && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Enable notifications in Settings to receive reminders'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Settings',
              onPressed: () {
                setState(() => _index = 3);
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _checkSmsSync() async {
    final syncManagerAsync = await ref.read(smsSyncManagerProvider.future);
    final smsPermission = await Permission.sms.status;
    final prefs = syncManagerAsync.getPreferences();

    if (smsPermission.isGranted) {
      if (prefs.preference == SyncPreference.none) {
        return;
      }
      await _performSmsSync(syncManagerAsync);
    } else {
      final result = await _showSmsSyncDialog();
      if (result == null) return;

      final preference = result['preference'] as SyncPreference;
      final fromDate = result['fromDate'] as DateTime?;

      await syncManagerAsync.savePreference(preference, fromDate: fromDate);

      if (preference == SyncPreference.none) return;

      final status = await PermissionService.requestSmsPermission(context);
      if (status.isGranted) {
        await _performSmsSync(syncManagerAsync);
      }
    }
  }

  Future<Map<String, dynamic>?> _showSmsSyncDialog() async {
    return showDialog<Map<String, dynamic>>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const SmsSyncDialog(),
    );
  }

  Future<void> _performSmsSync(SmsSyncManager syncManager,
      {bool showSnackBar = true}) async {
    final isSyncing = ref.read(isSyncingProvider);
    if (isSyncing) {
      debugPrint('SMS sync already in progress, skipping');
      return;
    }

    try {
      ref.read(isSyncingProvider.notifier).state = true;

      final result = await syncManager.syncAll(widget.user.id);

      if (result.hasError && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: ${result.errorMessage}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      } else if (result.addedCount > 0 && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result.addedCount} new transaction${result.addedCount > 1 ? 's' : ''} added from SMS',
            ),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'View',
                onPressed: () {
                  setState(() => _index = 1);
                },
            ),
          ),
        );

        await syncManager.showSyncNotification(context, result.addedCount);
      }

      if (mounted) {
        await ref
            .read(transactionsControllerProvider.notifier)
            .load(widget.user.id);
      }
    } catch (e) {
      debugPrint('SMS sync error: $e');
      if (mounted && showSnackBar) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to sync: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        ref.read(isSyncingProvider.notifier).state = false;
      }
    }
  }

  void _checkBudgetAlerts() {
    final alertLevel = ref.read(budgetAlertProvider);
    final alertController = ref.read(budgetAlertControllerProvider.notifier);
    alertController.checkAndUpdateAlert(alertLevel, ref);
  }

  void _showAddTransaction() async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const TransactionFormSheet(),
    );
    if (result is! TransactionModel) return;
    await ref.read(transactionsControllerProvider.notifier).upsert(result);
    final syncManagerAsync = await ref.read(smsSyncManagerProvider.future);
    await syncManagerAsync.setLastManualTransactionTime(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showFab = _index == 0;
    final alertLevel = ref.watch(budgetAlertControllerProvider);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (alertLevel != BudgetAlertLevel.none && _index == 0)
              const BudgetAlertBanner(),
            Expanded(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(
                      position: Tween<Offset>(
                        begin: const Offset(0.02, 0),
                        end: Offset.zero,
                      ).animate(animation),
                      child: child,
                    ),
                  );
                },
                child:
                    KeyedSubtree(key: ValueKey(_index), child: _pages[_index]),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: showFab
          ? Padding(
              padding: const EdgeInsets.only(bottom: 80),
              child: FloatingActionButton.extended(
                onPressed: _showAddTransaction,
                icon: const Icon(Icons.add),
                label: const Text('Add'),
              ),
            )
          : null,
      extendBody: true,
      bottomNavigationBar: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface.withValues(alpha: 0.95),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _NavItem(
                        icon: Icons.home_outlined,
                        activeIcon: Icons.home,
                        label: 'Home',
                        isSelected: _index == 0,
                        onTap: () => setState(() => _index = 0),
                      ),
                      _NavItem(
                        icon: Icons.receipt_long_outlined,
                        activeIcon: Icons.receipt_long,
                        label: 'Transactions',
                        isSelected: _index == 1,
                        onTap: () => setState(() => _index = 1),
                      ),
                      _NavItem(
                        icon: Icons.bar_chart_outlined,
                        activeIcon: Icons.bar_chart,
                        label: 'Reports',
                        isSelected: _index == 2,
                        onTap: () => setState(() => _index = 2),
                      ),
                      _NavItem(
                        icon: Icons.settings_outlined,
                        activeIcon: Icons.settings,
                        label: 'Settings',
                        isSelected: _index == 3,
                        onTap: () => setState(() => _index = 3),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.onSurfaceVariant,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
