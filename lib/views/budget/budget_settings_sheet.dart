import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/budget_model.dart';
import '../../providers/app_providers.dart';

class BudgetSettingsSheet extends ConsumerStatefulWidget {
  const BudgetSettingsSheet({super.key, this.initialBudget});

  final double? initialBudget;

  @override
  ConsumerState<BudgetSettingsSheet> createState() =>
      _BudgetSettingsSheetState();
}

class _BudgetSettingsSheetState extends ConsumerState<BudgetSettingsSheet> {
  late final TextEditingController _amountController;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(
      text: widget.initialBudget?.toStringAsFixed(2) ?? '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  void _save() async {
    if (!_formKey.currentState!.validate()) return;
    final amount = double.parse(_amountController.text);
    await ref.read(budgetControllerProvider.notifier).save(amount);
    if (mounted) Navigator.pop(context, amount);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Set Monthly Budget',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat.yMMMM().format(selectedMonth),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a budget amount';
                    }
                    final amount = double.tryParse(value);
                    if (amount == null || amount <= 0) {
                      return 'Please enter a valid positive amount';
                    }
                    return null;
                  },
                  decoration: InputDecoration(
                    labelText: 'Budget Amount',
                    prefixIcon: const Icon(Icons.account_balance_wallet),
                    prefixText: ref.watch(currencySymbolProvider),
                    hintText: '0.00',
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(
                    widget.initialBudget != null
                        ? 'Update Budget'
                        : 'Set Budget',
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class BudgetAlertBanner extends ConsumerWidget {
  const BudgetAlertBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertLevel = ref.watch(budgetAlertProvider);
    final budgetController = ref.watch(budgetAlertControllerProvider.notifier);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final budget = ref.watch(currentBudgetProvider);
    final expenses = ref.watch(monthlyExpensesProvider);
    final progress = ref.watch(budgetProgressProvider);

    if (alertLevel == BudgetAlertLevel.none) {
      return const SizedBox.shrink();
    }

    Color backgroundColor;
    Color textColor;
    IconData icon;
    String title;
    String message;

    switch (alertLevel) {
      case BudgetAlertLevel.fiftyPercent:
        backgroundColor = Colors.orange.shade100;
        textColor = Colors.orange.shade900;
        icon = Icons.warning_amber_rounded;
        title = 'Budget Warning';
        message = 'You\'ve used 50% of your monthly budget!';
        break;
      case BudgetAlertLevel.ninetyPercent:
        backgroundColor = Colors.deepOrange.shade100;
        textColor = Colors.deepOrange.shade900;
        icon = Icons.error_outline;
        title = 'Budget Alert';
        message = 'You\'ve used 90% of your monthly budget!';
        break;
      case BudgetAlertLevel.exceeded:
        backgroundColor = Colors.red.shade100;
        textColor = Colors.red.shade900;
        icon = Icons.dangerous;
        title = 'Budget Exceeded';
        message = 'You\'ve exceeded your monthly budget!';
        break;
      default:
        return const SizedBox.shrink();
    }

    return Dismissible(
      key: const Key('budget_alert_banner'),
      direction: DismissDirection.up,
      onDismissed: (_) => budgetController.dismissAlert(),
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: textColor, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    message,
                    style: TextStyle(
                      color: textColor.withValues(alpha: 0.8),
                      fontSize: 13,
                    ),
                  ),
                  if (budget != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      '$currencySymbol${expenses.toStringAsFixed(2)} of $currencySymbol${budget.amount.toStringAsFixed(2)} (${(progress * 100).toStringAsFixed(0)}%)',
                      style: TextStyle(
                        color: textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: () => budgetController.dismissAlert(),
              icon: Icon(Icons.close, color: textColor),
              tooltip: 'Dismiss',
            ),
          ],
        ),
      ),
    );
  }
}
