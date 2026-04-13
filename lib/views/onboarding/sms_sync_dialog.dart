import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/sms_sync_preference_service.dart';

enum SmsSyncOption {
  addPrevious,
  startFromToday,
  dontAdd,
}

class SmsSyncDialog extends StatefulWidget {
  const SmsSyncDialog({super.key});

  @override
  State<SmsSyncDialog> createState() => _SmsSyncDialogState();
}

class _SmsSyncDialogState extends State<SmsSyncDialog> {
  SmsSyncOption _selectedOption = SmsSyncOption.startFromToday;
  DateTime _customFromDate = DateTime.now().subtract(const Duration(days: 30));

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.sms,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Auto-Add Transactions',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        'Automatically detect transactions from bank SMS',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildOption(
              context,
              title: 'Add previous transactions',
              subtitle: 'Import transactions from past SMS messages',
              icon: Icons.history,
              value: SmsSyncOption.addPrevious,
              showDatePicker: true,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              title: 'Start from today',
              subtitle: 'Only add transactions from now onwards',
              icon: Icons.today,
              value: SmsSyncOption.startFromToday,
            ),
            const SizedBox(height: 12),
            _buildOption(
              context,
              title: "Don't auto-add",
              subtitle: 'Add transactions manually only',
              icon: Icons.block,
              value: SmsSyncOption.dontAdd,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: () => _onConfirm(context),
                  child: const Text('Continue'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOption(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required SmsSyncOption value,
    bool showDatePicker = false,
  }) {
    final isSelected = _selectedOption == value;

    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context)
                  .colorScheme
                  .primaryContainer
                  .withValues(alpha: 0.3)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Colors.transparent,
            width: 2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Radio<SmsSyncOption>(
                  value: value,
                  groupValue: _selectedOption,
                  onChanged: (v) => setState(() => _selectedOption = v!),
                ),
              ],
            ),
            if (showDatePicker && isSelected) ...[
              const SizedBox(height: 12),
              _buildDateRangeSelector(context),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Import transactions from:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w500,
              ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _buildDateChip(context, 'Last 7 days', 7),
            _buildDateChip(context, 'Last 30 days', 30),
            _buildDateChip(context, 'Last 90 days', 90),
            _buildDateChip(context, "Month's start", -1),
            _buildDateChip(context, 'Custom', -2, isCustom: true),
          ],
        ),
        if (_isCustomDateSelected()) ...[
          const SizedBox(height: 12),
          InkWell(
            onTap: () => _showDatePicker(context),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                border: Border.all(
                  color: Theme.of(context).colorScheme.outline,
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.calendar_today,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat.yMMMd().format(_customFromDate),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildDateChip(
    BuildContext context,
    String label,
    int days, {
    bool isCustom = false,
  }) {
    final isSelected =
        isCustom ? _isCustomDateSelected() : _isDaysSelected(days);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (isCustom) {
          setState(() => _selectedOption = SmsSyncOption.addPrevious);
        } else if (days == -1) {
          setState(() {
            _selectedOption = SmsSyncOption.addPrevious;
            _customFromDate = _getMonthStart();
          });
        } else {
          setState(() {
            _selectedOption = SmsSyncOption.addPrevious;
            _customFromDate = DateTime.now().subtract(Duration(days: days));
          });
        }
      },
    );
  }

  bool _isDaysSelected(int days) {
    if (days == -1) {
      final monthStart = _getMonthStart();
      return _isSameDay(_customFromDate, monthStart);
    }
    final expectedDate = DateTime.now().subtract(Duration(days: days));
    return _isSameDay(_customFromDate, expectedDate);
  }

  bool _isCustomDateSelected() {
    final sevenDays = DateTime.now().subtract(const Duration(days: 7));
    final thirtyDays = DateTime.now().subtract(const Duration(days: 30));
    final ninetyDays = DateTime.now().subtract(const Duration(days: 90));
    final monthStart = _getMonthStart();

    return !(_isSameDay(_customFromDate, sevenDays) ||
        _isSameDay(_customFromDate, thirtyDays) ||
        _isSameDay(_customFromDate, ninetyDays) ||
        _isSameDay(_customFromDate, monthStart));
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  DateTime _getMonthStart() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, 1);
  }

  Future<void> _showDatePicker(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _customFromDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _customFromDate = picked;
        _selectedOption = SmsSyncOption.addPrevious;
      });
    }
  }

  void _onConfirm(BuildContext context) {
    SyncPreference preference;
    DateTime? fromDate;

    switch (_selectedOption) {
      case SmsSyncOption.addPrevious:
        preference = SyncPreference.previous;
        fromDate = _customFromDate;
        break;
      case SmsSyncOption.startFromToday:
        preference = SyncPreference.upcoming;
        break;
      case SmsSyncOption.dontAdd:
        preference = SyncPreference.none;
        break;
    }

    Navigator.pop(context, {
      'preference': preference,
      'fromDate': fromDate,
    });
  }
}
