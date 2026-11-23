import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../logic/bill_rules.dart';

class MonthSelector extends StatelessWidget {
  const MonthSelector({
    super.key,
    required this.month,
    required this.today,
    required this.onChanged,
  });

  final DateTime month;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final canGoBack = month.isAfter(DateTime.utc(2000, 1));
    final canGoForward = month.isBefore(DateTime.utc(2100, 12));
    final current = isSameMonth(month, today);
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 2,
      children: [
        IconButton(
          tooltip: 'Mes anterior',
          onPressed: canGoBack ? () => onChanged(addMonths(month, -1)) : null,
          icon: const Icon(Icons.chevron_left),
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(minWidth: 148),
          child: Text(
            monthLabel(month),
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: ink),
          ),
        ),
        IconButton(
          tooltip: 'Mes siguiente',
          onPressed: canGoForward ? () => onChanged(addMonths(month, 1)) : null,
          icon: const Icon(Icons.chevron_right),
        ),
        if (!current)
          TextButton(
            onPressed: () => onChanged(monthStart(today)),
            child: const Text('Mes actual'),
          ),
      ],
    );
  }
}
