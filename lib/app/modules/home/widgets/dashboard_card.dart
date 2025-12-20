import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../data/models/todo.dart';

class DashboardCard extends StatelessWidget {
  const DashboardCard({
    super.key,
    required this.total,
    required this.completed,
    required this.rate,
    required this.priorityBreakdown,
  });

  final int total;
  final int completed;
  final double rate;
  final Map<TodoPriority, int> priorityBreakdown;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'dashboard.card.title'.tr,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CompletionInsight(
                    total: total,
                    completed: completed,
                    rate: rate,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _PriorityBreakdown(
                    data: priorityBreakdown,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _CompletionInsight extends StatelessWidget {
  const _CompletionInsight({
    required this.total,
    required this.completed,
    required this.rate,
  });

  final int total;
  final int completed;
  final double rate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percentage = (rate * 100).toStringAsFixed(0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard.completion'.tr,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 100,
              height: 100,
              child: CircularProgressIndicator(
                value: rate,
                strokeWidth: 10,
                backgroundColor: theme.colorScheme.surfaceContainerHighest,
              ),
            ),
            Column(
              children: [
                Text(
                  '$percentage%',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '$completed of $total',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PriorityBreakdown extends StatelessWidget {
  const _PriorityBreakdown({required this.data});

  final Map<TodoPriority, int> data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final maxValue =
        data.values.fold<int>(0, (max, value) => value > max ? value : max);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'dashboard.priority'.tr,
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: BarChart(
            BarChartData(
              gridData: const FlGridData(show: false),
              titlesData: FlTitlesData(
                leftTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                topTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles:
                    const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      final index = value.toInt();
                      if (index < 0 || index >= TodoPriority.values.length) {
                        return const SizedBox.shrink();
                      }
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          TodoPriority.values[index].label,
                          style: theme.textTheme.bodySmall,
                        ),
                      );
                    },
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              barGroups: [
                for (var i = 0; i < TodoPriority.values.length; i++)
                  BarChartGroupData(
                    x: i,
                    barRods: [
                      BarChartRodData(
                        toY: data[TodoPriority.values[i]]?.toDouble() ?? 0,
                        color: _priorityColor(
                          TodoPriority.values[i],
                          theme.colorScheme,
                        ),
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
              ],
              maxY: (maxValue == 0 ? 1 : maxValue).toDouble(),
            ),
          ),
        ),
      ],
    );
  }
}

Color _priorityColor(TodoPriority priority, ColorScheme scheme) {
  switch (priority) {
    case TodoPriority.low:
      return scheme.tertiary;
    case TodoPriority.medium:
      return scheme.primary;
    case TodoPriority.high:
      return scheme.error;
  }
}
