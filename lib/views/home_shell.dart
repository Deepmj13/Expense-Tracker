import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../models/budget_model.dart';
import '../models/transaction_model.dart';
import '../providers/app_providers.dart';
import 'budget/budget_settings_sheet.dart';
import 'dashboard/dashboard_view.dart';
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

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _initialized = false;

  final _pages = const [
    DashboardView(),
    TransactionsView(),
    ReportsView(),
    SettingsView(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialize();
    });
  }

  void _initialize() {
    if (_initialized) return;
    _initialized = true;
    ref.read(transactionsControllerProvider.notifier).load(widget.user.id);
    _checkBudgetAlerts();
    _initSmsListener();
  }

  void _initSmsListener() async {
    final isEnabled = ref.read(smsAutoImportProvider);
    if (isEnabled) {
      final smsService = ref.read(smsListenerServiceProvider);
      await smsService.startListening(widget.user.id);
    }
  }

  void _checkBudgetAlerts() {
    final alertLevel = ref.read(budgetAlertProvider);
    final alertController = ref.read(budgetAlertControllerProvider.notifier);
    alertController.checkAndUpdateAlert(alertLevel);
  }

  @override
  void didUpdateWidget(HomeShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    final oldEnabled = ref.read(smsAutoImportProvider);
    final newEnabled = ref.watch(smsAutoImportProvider);
    if (oldEnabled != newEnabled) {
      _handleSmsToggleChange(newEnabled);
    }
  }

  void _handleSmsToggleChange(bool enabled) async {
    final smsService = ref.read(smsListenerServiceProvider);
    if (enabled) {
      await smsService.startListening(widget.user.id);
    } else {
      await smsService.stopListening();
    }
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
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final showFab = _index == 0;
    final alertLevel = ref.watch(budgetAlertProvider);

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
