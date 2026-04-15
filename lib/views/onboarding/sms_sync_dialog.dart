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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.75,
        ),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 28, 24, 20),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .primaryContainer
                      .withValues(alpha: 0.3),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(28)),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Theme.of(context)
                                .colorScheme
                                .primary
                                .withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.sms,
                        color: Theme.of(context).colorScheme.onPrimary,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Auto-Add Transactions',
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Automatically detect transactions from bank SMS',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    _buildOptionCard(
                      context,
                      title: 'Add previous transactions',
                      subtitle: 'Import transactions from past SMS',
                      icon: Icons.history_rounded,
                      value: SmsSyncOption.addPrevious,
                      showDatePicker: true,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      context,
                      title: 'Start from today',
                      subtitle: 'Only add from now onwards',
                      icon: Icons.today_rounded,
                      value: SmsSyncOption.startFromToday,
                    ),
                    const SizedBox(height: 12),
                    _buildOptionCard(
                      context,
                      title: "Don't auto-add",
                      subtitle: 'Add transactions manually only',
                      icon: Icons.block_rounded,
                      value: SmsSyncOption.dontAdd,
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton(
                        onPressed: () => _onConfirm(context),
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text('Continue'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required SmsSyncOption value,
    bool showDatePicker = false,
  }) {
    final isSelected = _selectedOption == value;
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: () => setState(() => _selectedOption = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? colorScheme.primaryContainer.withValues(alpha: 0.5)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.outline.withValues(alpha: 0.2),
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: colorScheme.primary.withValues(alpha: 0.1),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary.withValues(alpha: 0.15)
                        : colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isSelected
                                      ? colorScheme.primary
                                      : colorScheme.onSurface,
                                ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color:
                        isSelected ? colorScheme.primary : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          size: 18,
                          color: colorScheme.onPrimary,
                        )
                      : null,
                ),
              ],
            ),
            if (showDatePicker && isSelected) ...[
              const SizedBox(height: 16),
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
