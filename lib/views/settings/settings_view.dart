import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../providers/app_providers.dart';
import '../budget/budget_settings_sheet.dart';
import 'feedback_sheet.dart';

class SettingsView extends ConsumerWidget {
  const SettingsView({super.key});

  String _getThemeTitle(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'Light';
      case ThemeMode.dark:
        return 'Dark';
      case ThemeMode.system:
        return 'System';
    }
  }

  IconData _getThemeIcon(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return Icons.light_mode;
      case ThemeMode.dark:
        return Icons.dark_mode;
      case ThemeMode.system:
        return Icons.settings_brightness;
    }
  }

  void _showFeedbackDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const FeedbackSheet(),
    );
  }

  void _showColorPicker(BuildContext context, WidgetRef ref) {
    final currentColor = ref.read(accentColorProvider);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Choose Accent Color',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Select a color that suits your style',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 16,
              runSpacing: 16,
              alignment: WrapAlignment.center,
              children: AppConstants.accentColors.entries.map((entry) {
                final color = Color(entry.value);
                final isSelected = currentColor.toARGB32() == color.toARGB32();
                return GestureDetector(
                  onTap: () {
                    ref
                        .read(accentColorProvider.notifier)
                        .setAccentColor(color);
                    Navigator.pop(context);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: isSelected
                          ? Border.all(
                              color: Theme.of(context).colorScheme.onSurface,
                              width: 3,
                            )
                          : null,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: color.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 28)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'Settings',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Appearance'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    _getThemeIcon(themeMode),
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                title: const Text('Theme'),
                subtitle: Text(_getThemeTitle(themeMode)),
                trailing: Switch(
                  value: themeMode == ThemeMode.dark,
                  onChanged: (v) => ref
                      .read(themeModeProvider.notifier)
                      .setThemeMode(v ? ThemeMode.dark : ThemeMode.light),
                ),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.palette,
                    color: accentColor,
                  ),
                ),
                title: const Text('Accent Color'),
                subtitle: const Text('Customize app color'),
                trailing: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).colorScheme.outline,
                      width: 2,
                    ),
                  ),
                ),
                onTap: () => _showColorPicker(context, ref),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Budget'),
        const SizedBox(height: 12),
        _BudgetManagementCard(ref: ref),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Data'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.file_download, color: Colors.green),
            ),
            title: const Text('Export Transactions'),
            subtitle: const Text('Save CSV file to your device'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final transactions = ref.read(transactionsControllerProvider);

              final rows = [
                ['id', 'title', 'amount', 'type', 'category', 'date', 'note'],
                ...transactions.map((t) => [
                      t.id,
                      t.title,
                      t.amount,
                      t.type.name,
                      t.category,
                      t.date.toIso8601String(),
                      t.note,
                    ]),
              ];

              final csv = const ListToCsvConverter().convert(rows);
              final timestamp =
                  DateTime.now().toIso8601String().replaceAll(':', '-');
              final bytes = Uint8List.fromList(csv.codeUnits);

              final result = await FilePicker.platform.saveFile(
                dialogTitle: 'Choose save location',
                fileName: 'expense_export_$timestamp.csv',
                type: FileType.custom,
                allowedExtensions: ['csv'],
                bytes: bytes,
              );

              if (context.mounted) {
                if (result != null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('CSV saved to: $result'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Export cancelled'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              }
            },
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Auto Import'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.sms, color: Colors.blue),
                ),
                title: const Text('Auto Import from SMS'),
                subtitle: const Text('Automatically add UPI/bank transactions'),
                trailing: Switch(
                  value: ref.watch(smsAutoImportProvider),
                  onChanged: (value) async {
                    final user = ref.read(authControllerProvider);
                    if (user == null) return;

                    final smsService = ref.read(smsListenerServiceProvider);

                    if (value) {
                      final hasPermission = await smsService.checkPermission();
                      if (!hasPermission) {
                        final granted = await smsService.requestPermission();
                        if (!granted) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('SMS permission required'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                          return;
                        }
                      }
                      await smsService.startListening(user.id);
                    } else {
                      await smsService.stopListening();
                    }

                    ref.read(smsAutoImportProvider.notifier).setEnabled(value);

                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(value
                              ? 'SMS auto-import enabled'
                              : 'SMS auto-import disabled'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  },
                ),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.purple.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.info_outline, color: Colors.purple),
                ),
                title: const Text('Supported Sources'),
                subtitle: const Text(
                    'UPI, PhonePe, Google Pay, Paytm, HDFC, ICICI, SBI, Axis'),
                trailing: const Icon(Icons.chevron_right),
              ),
              const Divider(height: 1, indent: 72),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.refresh, color: Colors.orange),
                ),
                title: const Text('Test SMS Import'),
                subtitle: const Text('Manually test SMS reading'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () async {
                  final user = ref.read(authControllerProvider);
                  if (user == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please login first'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                    return;
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Testing SMS fetch...'),
                        behavior: SnackBarBehavior.floating,
                        duration: Duration(seconds: 2),
                      ),
                    );
                  }

                  final smsService = ref.read(smsListenerServiceProvider);
                  await smsService.testFetch();

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Check console for results'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Help'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.feedback, color: Colors.orange),
            ),
            title: const Text('Send Feedback'),
            subtitle: const Text('Report bugs or suggest features'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showFeedbackDialog(context),
          ),
        ),
        const SizedBox(height: 24),
        _SectionHeader(title: 'Account'),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(16),
          ),
          child: ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.logout, color: Colors.red),
            ),
            title: const Text('Logout'),
            subtitle: const Text('Sign out of your account'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => ref.read(authControllerProvider.notifier).logout(),
          ),
        ),
        const SizedBox(height: 32),
        Center(
          child: Text(
            'Expense Tracker v1.0.0',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.primary,
          ),
    );
  }
}

class _BudgetManagementCard extends ConsumerWidget {
  const _BudgetManagementCard({required this.ref});

  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final budget = ref.watch(currentBudgetProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.account_balance_wallet,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            title: Text(
              budget != null
                  ? 'Budget for ${DateFormat.yMMMM().format(selectedMonth)}'
                  : 'No Budget Set',
            ),
            subtitle: budget != null
                ? Text(
                    '$currencySymbol${budget.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : const Text('Set a monthly budget to track spending'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final result = await showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) =>
                    BudgetSettingsSheet(initialBudget: budget?.amount),
              );
              if (result != null) {
                ref
                    .read(budgetAlertControllerProvider.notifier)
                    .resetForNewMonth();
              }
            },
          ),
          if (budget != null) ...[
            const Divider(height: 1, indent: 72),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _BudgetStat(
                    label: 'Budget',
                    value: '$currencySymbol${budget.amount.toStringAsFixed(0)}',
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  _BudgetStat(
                    label: 'Spent',
                    value:
                        '$currencySymbol${ref.watch(monthlyExpensesProvider).toStringAsFixed(0)}',
                    color: Colors.orange,
                  ),
                  _BudgetStat(
                    label: 'Remaining',
                    value:
                        '$currencySymbol${ref.watch(budgetRemainingProvider).toStringAsFixed(0)}',
                    color: ref.watch(budgetRemainingProvider) >= 0
                        ? Colors.green
                        : Colors.red,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BudgetStat extends StatelessWidget {
  const _BudgetStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
        ),
      ],
    );
  }
}
