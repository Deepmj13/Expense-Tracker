import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../models/transaction_model.dart';
import '../../models/transaction_type.dart';
import '../../providers/app_providers.dart';

class ReportsView extends ConsumerWidget {
  const ReportsView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(transactionsControllerProvider);
    final currencySymbol = ref.watch(currencySymbolProvider);
    final expenseItems =
        items.where((e) => e.type == TransactionType.expense).toList();
    final incomeItems =
        items.where((e) => e.type == TransactionType.income).toList();

    final byCategory = <String, double>{};
    final byPaymentMethod = <PaymentMethod, double>{};
    final byMonth = <int, double>{};
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];

    for (final t in expenseItems) {
      byCategory[t.category] = (byCategory[t.category] ?? 0) + t.amount;
      byPaymentMethod[t.paymentMethod] =
          (byPaymentMethod[t.paymentMethod] ?? 0) + t.amount;
    }

    for (final t in items) {
      byMonth[t.date.month] = (byMonth[t.date.month] ?? 0) + t.amount;
    }

    final currencyFormat =
        NumberFormat.currency(symbol: currencySymbol, decimalDigits: 2);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 100),
      children: [
        Text(
          'Reports',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your expense analytics',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Total Income',
                value: currencyFormat
                    .format(incomeItems.fold(0.0, (sum, t) => sum + t.amount)),
                color: Colors.green,
                icon: Icons.arrow_downward,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Total Expenses',
                value: currencyFormat
                    .format(expenseItems.fold(0.0, (sum, t) => sum + t.amount)),
                color: Colors.red,
                icon: Icons.arrow_upward,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        if (expenseItems.isNotEmpty) ...[
          _SectionHeader(title: 'Spending by Category'),
          const SizedBox(height: 16),
          _CategoryChart(
            byCategory: byCategory,
            currencyFormat: currencyFormat,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Spending by Payment Method'),
          const SizedBox(height: 16),
          _PaymentMethodChart(
            byPaymentMethod: byPaymentMethod,
            currencyFormat: currencyFormat,
          ),
          const SizedBox(height: 24),
          _SectionHeader(title: 'Monthly Overview'),
          const SizedBox(height: 16),
          _MonthlyChart(byMonth: byMonth, months: months),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(48),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.bar_chart,
                  size: 64,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(height: 16),
                Text(
                  'No data to display',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  'Add some transactions to see your reports',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
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
      style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
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
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryChart extends StatelessWidget {
  const _CategoryChart({
    required this.byCategory,
    required this.currencyFormat,
  });

  final Map<String, double> byCategory;
  final NumberFormat currencyFormat;

  static const _categoryColors = [
    Color(0xFF0D9488),
    Color(0xFF3B82F6),
    Color(0xFFF59E0B),
    Color(0xFFEF4444),
    Color(0xFF8B5CF6),
    Color(0xFF10B981),
    Color(0xFFF97316),
    Color(0xFFEC4899),
  ];

  @override
  Widget build(BuildContext context) {
    final sortedEntries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 50,
                sections: sortedEntries.asMap().entries.map((entry) {
                  final colorIndex = entry.key % _categoryColors.length;
                  return PieChartSectionData(
                    value: entry.value.value,
                    color: _categoryColors[colorIndex],
                    radius: 60,
                    title: '',
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: sortedEntries.asMap().entries.map((entry) {
              final colorIndex = entry.key % _categoryColors.length;
              return _LegendItem(
                color: _categoryColors[colorIndex],
                label: entry.value.key,
                value: currencyFormat.format(entry.value.value),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _PaymentMethodChart extends StatelessWidget {
  const _PaymentMethodChart({
    required this.byPaymentMethod,
    required this.currencyFormat,
  });

  final Map<PaymentMethod, double> byPaymentMethod;
  final NumberFormat currencyFormat;

  static const _paymentMethodColors = [
    Color(0xFF10B981),
    Color(0xFF3B82F6),
    Color(0xFF8B5CF6),
    Color(0xFFF97316),
    Color(0xFFEC4899),
    Color(0xFF6B7280),
  ];

  @override
  Widget build(BuildContext context) {
    final sortedEntries = byPaymentMethod.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sortedEntries.fold(0.0, (sum, entry) => sum + entry.value);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: total * 1.2,
                barGroups: sortedEntries.asMap().entries.map((entry) {
                  final colorIndex = entry.key % _paymentMethodColors.length;
                  return BarChartGroupData(
                    x: entry.key,
                    barRods: [
                      BarChartRodData(
                        toY: entry.value.value,
                        color: _paymentMethodColors[colorIndex],
                        width: 32,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(8),
                        ),
                      ),
                    ],
                  );
                }).toList(),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final index = value.toInt();
                        if (index >= sortedEntries.length)
                          return const SizedBox();
                        final method = sortedEntries[index].key;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Icon(
                            method.icon,
                            size: 20,
                            color: _paymentMethodColors[
                                index % _paymentMethodColors.length],
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
              ),
            ),
          ),
          const SizedBox(height: 20),
          ...sortedEntries.asMap().entries.map((entry) {
            final colorIndex = entry.key % _paymentMethodColors.length;
            final percentage =
                (entry.value.value / total * 100).toStringAsFixed(1);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _paymentMethodColors[colorIndex]
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      entry.value.key.icon,
                      color: _paymentMethodColors[colorIndex],
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.value.key.label,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w500,
                                  ),
                        ),
                        const SizedBox(height: 2),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: entry.value.value / total,
                            backgroundColor: _paymentMethodColors[colorIndex]
                                .withValues(alpha: 0.1),
                            valueColor: AlwaysStoppedAnimation(
                              _paymentMethodColors[colorIndex],
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(entry.value.value),
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        '$percentage%',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _MonthlyChart extends StatelessWidget {
  const _MonthlyChart({
    required this.byMonth,
    required this.months,
  });

  final Map<int, double> byMonth;
  final List<String> months;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: byMonth.values.isEmpty
                ? 100
                : byMonth.values.reduce((a, b) => a > b ? a : b) * 1.2,
            barGroups: List.generate(12, (i) {
              final month = i + 1;
              final value = byMonth[month] ?? 0;
              return BarChartGroupData(
                x: month,
                barRods: [
                  BarChartRodData(
                    toY: value,
                    color: Theme.of(context).colorScheme.primary,
                    width: 16,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(6)),
                  ),
                ],
              );
            }),
            titlesData: FlTitlesData(
              leftTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, _) => Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      months[(value.toInt() - 1) % 12],
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ),
                ),
              ),
            ),
            gridData: const FlGridData(show: false),
            borderData: FlBorderData(show: false),
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '$label: $value',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
