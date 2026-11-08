import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/app_constants.dart';
import '../../models/export_config.dart';
import '../../models/report_dataset.dart';
import '../../models/transaction_model.dart';
import '../../providers/app_providers.dart';
import '../../providers/export_providers.dart';
import '../../services/export_service.dart';
import '../../services/report_builder.dart';
import 'export_result_view.dart';

enum _Stage { configure, running, result }

class ExportSheet extends ConsumerStatefulWidget {
  const ExportSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const ExportSheet(),
    );
  }

  @override
  ConsumerState<ExportSheet> createState() => _ExportSheetState();
}

class _ExportSheetState extends ConsumerState<ExportSheet> {
  static const _builder = ReportBuilder();

  late ExportConfig _config;
  _Stage _stage = _Stage.configure;

  @override
  void initState() {
    super.initState();
    _config = ExportConfig.current();
    Future.microtask(() => ref.read(exportControllerProvider.notifier).reset());
  }

  void _update(ExportConfig Function(ExportConfig) transform) {
    setState(() => _config = transform(_config));
  }

  List<String> get _categories {
    try {
      return AppConstants.allCategories;
    } catch (_) {
      return AppConstants.defaultCategories;
    }
  }

  ReportDataset? get _preview {
    final user = ref.read(authControllerProvider);
    if (user == null) return null;
    try {
      return _builder.build(
        items: ref.read(transactionsControllerProvider),
        config: _config,
        user: user,
        timezone: ExportService.localTimeZone(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _generate() async {
    final user = ref.read(authControllerProvider);
    if (user == null) return;

    final controller = ref.read(exportControllerProvider.notifier);
    final ok = await controller.generate(
      config: _config,
      user: user,
      items: ref.read(transactionsControllerProvider),
    );
    if (!mounted) return;

    if (ok) {
      setState(() => _stage = _Stage.result);
    } else {
      final error = ref.read(exportControllerProvider).error;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error ?? 'Export failed. Please try again.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickDate({required bool isFrom}) async {
    final initial = isFrom ? _config.dateFrom : _config.dateTo;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2015),
      lastDate: DateTime(2100),
    );
    if (picked == null || !mounted) return;

    _update((config) {
      if (isFrom) {
        return config.copyWith(datePreset: DateRangePreset.custom, dateFrom: picked);
      }
      final end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59, 999);
      return config.copyWith(datePreset: DateRangePreset.custom, dateTo: end);
    });
  }

  void _toggleCategory(String category) {
    final selected = [..._config.categories];
    if (selected.contains(category)) {
      selected.remove(category);
    } else {
      selected.add(category);
    }
    _update((config) => config.copyWith(categories: selected));
  }

  void _toggleMethod(PaymentMethod method) {
    final selected = [..._config.paymentMethods];
    if (selected.contains(method)) {
      selected.remove(method);
    } else {
      selected.add(method);
    }
    _update((config) => config.copyWith(paymentMethods: selected));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final exportState = ref.watch(exportControllerProvider);
    final media = MediaQuery.of(context);
    final tileWidth = (media.size.width - 56) / 2;

    final stage = switch (_stage) {
      _ when exportState.isExporting => _Stage.running,
      _Stage.result when exportState.job != null => _Stage.result,
      _ => _Stage.configure,
    };
    final job = stage == _Stage.result ? exportState.job : null;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Container(
        constraints: BoxConstraints(maxHeight: media.size.height * 0.9),
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 16,
          bottom: media.viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _handle(context),
              const SizedBox(height: 20),
              _header(context, colorScheme),
              const SizedBox(height: 24),
              if (stage == _Stage.configure) ...[
                _configure(context, colorScheme, tileWidth),
              ] else if (stage == _Stage.running)
                _running(context, colorScheme, exportState)
              else if (job != null)
                ExportResultView(
                  job: job,
                  onExportAnother: () {
                    ref.read(exportControllerProvider.notifier).reset();
                    setState(() => _stage = _Stage.configure);
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _handle(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.outlineVariant,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _header(BuildContext context, ColorScheme colorScheme) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.file_download, color: Colors.green, size: 28),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Export Report',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                'Choose a format and what to include',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
        ),
        IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.close),
          tooltip: 'Close',
        ),
      ],
    );
  }

  Widget _configure(BuildContext context, ColorScheme colorScheme, double tileWidth) {
    final errors = _config.validate();
    final exportState = ref.watch(exportControllerProvider);
    final isGenerating = exportState.isExporting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _label(context, 'Format'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final format in ExportFormat.values)
              _formatTile(context, colorScheme, format, tileWidth),
          ],
        ),
        const SizedBox(height: 20),
        _label(context, 'Date range'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final preset in DateRangePreset.values)
              ChoiceChip(
                label: Text(preset.label),
                selected: _config.datePreset == preset,
                onSelected: (_) => _update((c) => c.applyPreset(preset)),
                selectedColor: colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: _config.datePreset == preset
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurface,
                  fontWeight: _config.datePreset == preset
                      ? FontWeight.w600
                      : FontWeight.normal,
                ),
              ),
          ],
        ),
        if (_config.datePreset == DateRangePreset.custom) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: true),
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_shortDate(_config.dateFrom)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('to'),
              ),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(isFrom: false),
                  icon: const Icon(Icons.calendar_today_outlined, size: 18),
                  label: Text(_shortDate(_config.dateTo)),
                ),
              ),
            ],
          ),
        ],
        const SizedBox(height: 20),
        _label(context, 'Transactions'),
        SegmentedButton<ExportTransactionType>(
          segments: [
            for (final type in ExportTransactionType.values)
              ButtonSegment(value: type, label: Text(type.label)),
          ],
          selected: {_config.transactionType},
          showSelectedIcon: false,
          onSelectionChanged: (selection) => _update(
            (c) => c.copyWith(transactionType: selection.first),
          ),
        ),
        const SizedBox(height: 20),
        _label(context, 'Group by'),
        SegmentedButton<ExportGroupBy>(
          segments: [
            for (final group in ExportGroupBy.values)
              ButtonSegment(value: group, label: Text(group.label)),
          ],
          selected: {_config.groupBy},
          showSelectedIcon: false,
          onSelectionChanged: (selection) =>
              _update((c) => c.copyWith(groupBy: selection.first)),
        ),
        const SizedBox(height: 20),
        _label(context, 'Categories'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final category in _categories)
              FilterChip(
                label: Text(category),
                selected: _config.categories.contains(category),
                onSelected: (_) => _toggleCategory(category),
              ),
          ],
        ),
        const SizedBox(height: 20),
        _label(context, 'Payment methods'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final method in PaymentMethod.values)
              FilterChip(
                label: Text(method.label),
                selected: _config.paymentMethods.contains(method),
                onSelected: (_) => _toggleMethod(method),
              ),
          ],
        ),
        const SizedBox(height: 12),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Include notes'),
          subtitle: const Text('Adds a notes column to every row'),
          value: _config.includeNotes,
          onChanged: (value) => _update((c) => c.copyWith(includeNotes: value)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Category percentages'),
          subtitle: const Text('Share of total spend per category'),
          value: _config.includeCategoryPercentages,
          onChanged: (value) => _update(
            (c) => c.copyWith(includeCategoryPercentages: value),
          ),
        ),
        if (_config.format == ExportFormat.pdf)
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Include charts'),
            subtitle: const Text('Pie chart of spending by category'),
            value: _config.includeCharts,
            onChanged: (value) => _update((c) => c.copyWith(includeCharts: value)),
          ),
        if (errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            errors.join('\n'),
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colorScheme.error),
          ),
        ],
        const SizedBox(height: 12),
        _previewCard(context, colorScheme),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed:
              errors.isNotEmpty || isGenerating ? null : _generate,
          icon: const Icon(Icons.file_download),
          label: const Text('Generate export'),
        ),
      ],
    );
  }

  Widget _running(
    BuildContext context,
    ColorScheme colorScheme,
    ExportState state,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: state.progress <= 0 ? null : state.progress),
          const SizedBox(height: 16),
          Text(
            'Preparing your report...',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            '${(state.progress * 100).round()}%',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
          ),
        ],
      ),
    );
  }

  Widget _previewCard(BuildContext context, ColorScheme colorScheme) {
    final preview = _preview;
    if (preview == null) return const SizedBox.shrink();

    final summary = preview.summary;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview_outlined, size: 18, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Preview',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: colorScheme.primary,
                    ),
              ),
              const Spacer(),
              Text(
                '${summary.transactionCount} rows',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _stat(context, 'Spent', preview.currencySymbol, summary.totalExpenses),
              _stat(context, 'Income', preview.currencySymbol, summary.totalIncome),
              _stat(context, 'Net', preview.currencySymbol, summary.netBalance),
            ],
          ),
          if (preview.groups.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              preview.groups
                  .take(3)
                  .map((g) => '${g.label} ${preview.currencySymbol}${_amount(g.amount)}')
                  .join('  ·  '),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _stat(
    BuildContext context,
    String label,
    String symbol,
    double value,
  ) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
          const SizedBox(height: 2),
          Text(
            '$symbol${_amount(value)}',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _label(BuildContext context, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _formatTile(
    BuildContext context,
    ColorScheme colorScheme,
    ExportFormat format,
    double width,
  ) {
    final selected = _config.format == format;
    return InkWell(
      onTap: () => _update((c) => c.copyWith(format: format)),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: width,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected
              ? colorScheme.primaryContainer
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colorScheme.primary : colorScheme.outlineVariant,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              format.icon,
              size: 26,
              color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    format.label,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  Text(
                    format.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _shortDate(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-'
      '${value.month.toString().padLeft(2, '0')}-'
      '${value.day.toString().padLeft(2, '0')}';

  String _amount(double value) => value.toStringAsFixed(2);
}
