import 'dart:typed_data';

import 'package:csv/csv.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/constants/notification_apps.dart';
import '../../providers/app_providers.dart';
import '../../services/notification_channel_service.dart';
import '../budget/budget_settings_sheet.dart';
import '../onboarding/notification_onboarding_view.dart';
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
        _SectionHeader(title: 'Notifications'),
        const SizedBox(height: 12),
        _NotificationSettingsCard(),
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

class _NotificationSettingsCard extends ConsumerStatefulWidget {
  const _NotificationSettingsCard();

  @override
  ConsumerState<_NotificationSettingsCard> createState() =>
      _NotificationSettingsCardState();
}

class _NotificationSettingsCardState
    extends ConsumerState<_NotificationSettingsCard> {
  bool _isAutoAddEnabled = true;
  bool _hasNotificationAccess = false;
  bool _hasBatteryOptimization = false;
  bool _isLoading = true;
  String _deviceManufacturer = 'unknown';

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final channelService = NotificationChannelService();

    final isEnabled = await channelService.isAutoAddEnabled();
    final hasAccess = await channelService.isNotificationAccessEnabled();
    final hasBattery = await channelService.isBatteryOptimizationDisabled();
    final manufacturer = await channelService.getDeviceManufacturer();

    if (mounted) {
      setState(() {
        _isAutoAddEnabled = isEnabled;
        _hasNotificationAccess = hasAccess;
        _hasBatteryOptimization = hasBattery;
        _deviceManufacturer = manufacturer;
        _isLoading = false;
      });
    }
  }

  Future<void> _toggleAutoAdd(bool value) async {
    final channelService = NotificationChannelService();
    await channelService.setAutoAddEnabled(value);
    setState(() {
      _isAutoAddEnabled = value;
    });
  }

  Future<void> _openNotificationSettings() async {
    final channelService = NotificationChannelService();
    await channelService.openNotificationSettings();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadSettings();
  }

  Future<void> _openBatterySettings() async {
    final channelService = NotificationChannelService();
    await channelService.requestBatteryOptimizationExemption();
    await Future.delayed(const Duration(milliseconds: 1000));
    await _loadSettings();
  }

  Future<void> _openAutoStartSettings() async {
    final channelService = NotificationChannelService();
    await channelService.openAutoStartSettings();
  }

  Future<void> _resetOnboarding() async {
    final box = Hive.box('app_box');
    await box.put('notification_onboarding_completed', false);
    if (mounted) {
      final result = await showNotificationOnboarding(context);
      if (result == true) {
        await _loadSettings();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Container(
        height: 120,
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    final isFullyConfigured = _hasNotificationAccess && _hasBatteryOptimization;

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
                color: _isAutoAddEnabled
                    ? Colors.green.withValues(alpha: 0.1)
                    : Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                _isAutoAddEnabled
                    ? Icons.notifications_active
                    : Icons.notifications_off,
                color: _isAutoAddEnabled ? Colors.green : Colors.grey,
              ),
            ),
            title: const Text('Auto-Detect Transactions'),
            subtitle: Text(
              _isAutoAddEnabled
                  ? 'Automatically add transactions from notifications'
                  : 'Disabled - transactions will not be auto-added',
            ),
            trailing: Switch(
              value: _isAutoAddEnabled,
              onChanged: _toggleAutoAdd,
            ),
          ),
          if (_isAutoAddEnabled) ...[
            const Divider(height: 1, indent: 72),
            _StatusTile(
              icon: Icons.notifications,
              title: 'Notification Access',
              isEnabled: _hasNotificationAccess,
              statusText: _hasNotificationAccess ? 'Enabled' : 'Disabled',
              onTap: _openNotificationSettings,
            ),
            const Divider(height: 1, indent: 72),
            _StatusTile(
              icon: Icons.battery_charging_full,
              title: 'Battery Optimization',
              isEnabled: _hasBatteryOptimization,
              statusText: _hasBatteryOptimization ? 'Disabled' : 'Active',
              onTap: _openBatterySettings,
            ),
            if (_deviceManufacturer != 'xiaomi' &&
                _deviceManufacturer != 'redmi' &&
                _deviceManufacturer != 'huawei' &&
                _deviceManufacturer != 'honor' &&
                _deviceManufacturer != 'oppo' &&
                _deviceManufacturer != 'realme' &&
                _deviceManufacturer != 'vivo' &&
                _deviceManufacturer != 'oneplus' &&
                _deviceManufacturer != 'samsung' &&
                _deviceManufacturer != 'asus') ...[
              const Divider(height: 1, indent: 72),
              _StatusTile(
                icon: Icons.power_settings_new,
                title: 'Auto-Start',
                isEnabled: true,
                statusText: 'Not required',
                onTap: null,
              ),
            ] else ...[
              const Divider(height: 1, indent: 72),
              _StatusTile(
                icon: Icons.power_settings_new,
                title: 'Auto-Start Settings',
                isEnabled: true,
                statusText: 'Configure for ${_getManufacturerName()}',
                onTap: _openAutoStartSettings,
              ),
            ],
            const Divider(height: 1, indent: 72),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        isFullyConfigured
                            ? Icons.check_circle
                            : Icons.warning_amber,
                        size: 16,
                        color: isFullyConfigured ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isFullyConfigured
                            ? 'All permissions configured'
                            : 'Some permissions need attention',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isFullyConfigured
                                  ? Colors.green
                                  : Colors.orange,
                              fontWeight: FontWeight.w500,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primaryContainer
                              .withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${NotificationApps.defaultApps.length} apps monitored',
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimaryContainer,
                                  ),
                        ),
                      ),
                      const Spacer(),
                      TextButton.icon(
                        onPressed: _resetOnboarding,
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Re-setup'),
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _getManufacturerName() {
    final manufacturer = _deviceManufacturer.toLowerCase();
    final names = {
      'xiaomi': 'Xiaomi',
      'redmi': 'Redmi',
      'samsung': 'Samsung',
      'huawei': 'Huawei',
      'honor': 'Honor',
      'oppo': 'OPPO',
      'realme': 'Realme',
      'vivo': 'Vivo',
      'oneplus': 'OnePlus',
      'asus': 'ASUS',
    };
    for (final entry in names.entries) {
      if (manufacturer.contains(entry.key)) {
        return entry.value;
      }
    }
    return _deviceManufacturer;
  }
}

class _StatusTile extends StatelessWidget {
  const _StatusTile({
    required this.icon,
    required this.title,
    required this.isEnabled,
    required this.statusText,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final bool isEnabled;
  final String statusText;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isEnabled
              ? Colors.green.withValues(alpha: 0.1)
              : Colors.orange.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          color: isEnabled ? Colors.green : Colors.orange,
          size: 20,
        ),
      ),
      title: Text(title),
      subtitle: Text(statusText),
      trailing: onTap != null
          ? TextButton(
              onPressed: onTap,
              child: Text(
                isEnabled ? 'Settings' : 'Enable',
                style: TextStyle(
                  color: isEnabled
                      ? Theme.of(context).colorScheme.primary
                      : Colors.orange,
                ),
              ),
            )
          : null,
      onTap: onTap,
    );
  }
}
