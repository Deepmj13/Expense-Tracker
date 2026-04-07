import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../providers/app_providers.dart';
import '../../widgets/transaction_tile.dart';
import 'transaction_form_sheet.dart';

class TransactionsView extends ConsumerWidget {
  const TransactionsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(filteredTransactionsProvider);
    final filter = ref.watch(transactionFilterProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transactions',
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  InkWell(
                    onTap: () => _showMonthPicker(context, ref),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            DateFormat.yMMM().format(selectedMonth),
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.arrow_drop_down,
                            size: 18,
                            color: Theme.of(context)
                                .colorScheme
                                .onPrimaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              TextField(
                onChanged: (v) => ref
                    .read(transactionFilterProvider.notifier)
                    .state = filter.copyWith(search: v),
                decoration: InputDecoration(
                  hintText: 'Search title/note',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String?>(
                      initialValue: filter.category,
                      decoration: InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: [
                        const DropdownMenuItem<String?>(
                            value: null, child: Text('All')),
                        ...AppConstants.categories.map(
                          (e) => DropdownMenuItem<String?>(
                              value: e, child: Text(e)),
                        ),
                      ],
                      onChanged: (v) =>
                          ref.read(transactionFilterProvider.notifier).state =
                              filter.copyWith(
                                  clearCategory: v == null, category: v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<TransactionType?>(
                      initialValue: filter.type,
                      decoration: InputDecoration(
                        labelText: 'Type',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 12),
                      ),
                      items: const [
                        DropdownMenuItem<TransactionType?>(
                            value: null, child: Text('All')),
                        DropdownMenuItem(
                            value: TransactionType.income,
                            child: Text('Income')),
                        DropdownMenuItem(
                            value: TransactionType.expense,
                            child: Text('Expense')),
                      ],
                      onChanged: (v) =>
                          ref.read(transactionFilterProvider.notifier).state =
                              filter.copyWith(clearType: v == null, type: v),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 64,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No transactions found',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Try adjusting your filters',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (_, i) {
                    final item = items[i];
                    return TransactionTile(
                      item: item,
                      onDelete: () => ref
                          .read(transactionsControllerProvider.notifier)
                          .remove(item.id),
                      onEdit: () async {
                        final result = await showModalBottomSheet(
                          context: context,
                          isScrollControlled: true,
                          builder: (_) => TransactionFormSheet(initial: item),
                        );
                        if (result is! TransactionModel) return;
                        await ref
                            .read(transactionsControllerProvider.notifier)
                            .upsert(result);
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  void _showMonthPicker(BuildContext context, WidgetRef ref) async {
    final selectedMonth = ref.read(selectedMonthProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedMonth,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked != null) {
      ref.read(selectedMonthProvider.notifier).state = DateTime(
        picked.year,
        picked.month,
      );
    }
  }
}
