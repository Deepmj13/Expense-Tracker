import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/constants/app_constants.dart';
import '../../core/utils/validators.dart';
import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../providers/app_providers.dart';

class TransactionFormSheet extends ConsumerStatefulWidget {
  const TransactionFormSheet({super.key, this.initial});

  final TransactionModel? initial;

  @override
  ConsumerState<TransactionFormSheet> createState() =>
      _TransactionFormSheetState();
}

class _TransactionFormSheetState extends ConsumerState<TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _amount;
  late final TextEditingController _note;
  late final TextEditingController _customCategory;
  late TransactionType _type;
  late String _category;
  late DateTime _date;
  bool _recurring = false;
  bool _useCustomCategory = false;
  late PaymentMethod _paymentMethod;

  @override
  void initState() {
    super.initState();
    final i = widget.initial;
    _title = TextEditingController(text: i?.title ?? '');
    _amount = TextEditingController(text: i?.amount.toString() ?? '');
    _note = TextEditingController(text: i?.note ?? '');
    _customCategory = TextEditingController(text: '');
    _type = i?.type ?? TransactionType.expense;
    final categories = AppConstants.allCategories;
    _useCustomCategory = i != null && !categories.contains(i.category);
    _category =
        _useCustomCategory ? i!.category : (i?.category ?? categories.first);
    if (_useCustomCategory) {
      _customCategory.text = _category;
    }
    _date = i?.date ?? DateTime.now();
    _recurring = i?.isRecurring ?? false;
    _paymentMethod = i?.paymentMethod ?? PaymentMethod.cash;
  }

  @override
  void dispose() {
    _title.dispose();
    _amount.dispose();
    _note.dispose();
    _customCategory.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final categoryToSave =
        _useCustomCategory ? _customCategory.text.trim() : _category;
    if (categoryToSave.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a category')),
      );
      return;
    }

    if (_useCustomCategory && _customCategory.text.trim().isNotEmpty) {
      await AppConstants.addCustomCategory(_customCategory.text.trim());
    }

    final model = TransactionModel(
      id: widget.initial?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      title: _title.text.trim(),
      amount: double.parse(_amount.text),
      type: _type,
      category: categoryToSave,
      date: _date,
      note: _note.text.trim(),
      isRecurring: _recurring,
      paymentMethod: _paymentMethod,
    );
    if (mounted) Navigator.pop(context, model);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final categories = AppConstants.allCategories;

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
                  widget.initial == null ? 'Add' : 'Edit',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                TextFormField(
                  controller: _title,
                  validator: (v) => Validators.requiredField(v, field: 'Title'),
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Title',
                    prefixIcon: Icon(Icons.title),
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _amount,
                  validator: Validators.amount,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: '${ref.watch(currencySymbolProvider)} ',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<TransactionType>(
                        value: _type,
                        decoration: const InputDecoration(
                          labelText: 'Type',
                        ),
                        items: TransactionType.values
                            .map((e) => DropdownMenuItem(
                                value: e, child: Text(e.name.toUpperCase())))
                            .toList(),
                        onChanged: (v) => setState(() => _type = v!),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _useCustomCategory
                            ? _customCategory.text.isEmpty
                                ? 'Custom'
                                : _category
                            : _category,
                        decoration: const InputDecoration(
                          labelText: 'Category',
                        ),
                        items: [
                          ...categories.map(
                            (e) => DropdownMenuItem(value: e, child: Text(e)),
                          ),
                          const DropdownMenuItem(
                            value: 'Custom',
                            child: Row(
                              children: [
                                Icon(Icons.add, size: 18),
                                SizedBox(width: 8),
                                Text('Custom'),
                              ],
                            ),
                          ),
                        ],
                        onChanged: (v) {
                          setState(() {
                            if (v == 'Custom') {
                              _useCustomCategory = true;
                            } else {
                              _useCustomCategory = false;
                              _category = v ?? categories.first;
                            }
                          });
                        },
                      ),
                    ),
                  ],
                ),
                if (_useCustomCategory) ...[
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _customCategory,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      labelText: 'Enter custom category',
                      prefixIcon: const Icon(Icons.category_outlined),
                      hintText: 'e.g., Groceries, Entertainment',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.check_circle),
                        onPressed: () {
                          if (_customCategory.text.trim().isNotEmpty) {
                            FocusScope.of(context).unfocus();
                          }
                        },
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                DropdownButtonFormField<PaymentMethod>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    prefixIcon: Icon(Icons.payment),
                  ),
                  items: PaymentMethod.values
                      .map((e) => DropdownMenuItem(
                            value: e,
                            child: Text(e.label),
                          ))
                      .toList(),
                  onChanged: (v) => setState(() => _paymentMethod = v!),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    border: Border.all(color: colorScheme.outlineVariant),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: colorScheme.primary),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat.yMMMMd().format(_date),
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _date,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) setState(() => _date = picked);
                        },
                        child: const Text('Change'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  value: _recurring,
                  onChanged: (v) => setState(() => _recurring = v),
                  title: const Text('Recurring Transaction'),
                  subtitle: const Text('Repeat this transaction'),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: colorScheme.outlineVariant),
                  ),
                  tileColor: colorScheme.surface,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _note,
                  maxLines: 2,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(
                    labelText: 'Note (optional)',
                    prefixIcon: Icon(Icons.note),
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _save,
                  child: Text(widget.initial == null ? 'Add' : 'Save'),
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
