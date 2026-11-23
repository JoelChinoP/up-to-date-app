import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../logic/bill_rules.dart';
import '../models/app_data.dart';
import 'layout_widgets.dart';

IconData statusIcon(BillStatusKind kind) => switch (kind) {
  BillStatusKind.paid => Icons.check_circle_rounded,
  BillStatusKind.late => Icons.error_rounded,
  BillStatusKind.today => Icons.schedule_rounded,
  BillStatusKind.soon => Icons.schedule_rounded,
  BillStatusKind.pending => Icons.radio_button_unchecked_rounded,
};

Color statusColor(BillStatusKind kind) => switch (kind) {
  BillStatusKind.paid => paidInk,
  BillStatusKind.late => lateInk,
  BillStatusKind.today => soonInk,
  BillStatusKind.soon => soonInk,
  BillStatusKind.pending => mutedInk,
};

Color statusSurface(BillStatusKind kind) => switch (kind) {
  BillStatusKind.paid => paidSoft,
  BillStatusKind.late => lateSoft,
  BillStatusKind.today => soonSoft,
  BillStatusKind.soon => soonSoft,
  BillStatusKind.pending => softSurface,
};

String shortStatusLabel(BillStatus status) => switch (status.kind) {
  BillStatusKind.paid => 'Pagado',
  BillStatusKind.late => 'Vencido',
  BillStatusKind.today => 'Hoy',
  BillStatusKind.soon || BillStatusKind.pending => _capitalize(
    status.label.replaceFirst('Vence ', ''),
  ),
};

String _capitalize(String text) =>
    text.isEmpty ? text : '${text[0].toUpperCase()}${text.substring(1)}';

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.status, this.compact = false});

  final BillStatus status;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 1 : 2,
      ),
      decoration: BoxDecoration(
        color: statusSurface(status.kind),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        shortStatusLabel(status),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: statusColor(status.kind),
          fontWeight: FontWeight.w600,
          fontSize: compact ? 11 : 12,
        ),
      ),
    );
  }
}

class BillListTile extends StatelessWidget {
  const BillListTile({
    super.key,
    required this.bill,
    required this.service,
    required this.today,
    this.onTap,
    this.trailing,
    this.showDueDate = true,
    this.selected = false,
    this.titleOverride,
  });

  final Bill bill;
  final Service? service;
  final DateTime today;
  final VoidCallback? onTap;
  final Widget? trailing;
  final bool showDueDate;
  final bool selected;
  final String? titleOverride;

  @override
  Widget build(BuildContext context) {
    final status = billStatus(bill, today);
    final name = titleOverride ?? service?.name ?? 'Servicio no disponible';
    final dateSource = bill.paid && bill.paidAt != null
        ? bill.paidAt!
        : bill.dueDate;
    final dateText = bill.paid
        ? _compactDate(dateSource, today)
        : showDueDate
        ? _compactDate(dateSource, today)
        : null;
    return Semantics(
      button: onTap != null,
      label: '$name, ${formatMoney(bill.amount)}, ${status.label}',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: softDivider)),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              padding: const EdgeInsets.fromLTRB(8, 12, 8, 12),
              decoration: BoxDecoration(
                color: selected ? accentSoft : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: selected ? 3 : 0,
                    height: 36,
                    decoration: BoxDecoration(
                      color: accent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  SizedBox(width: selected ? 9 : 12),
                  Icon(
                    statusIcon(status.kind),
                    size: 22,
                    color: statusColor(status.kind),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 3),
                        Wrap(
                          spacing: 6,
                          runSpacing: 2,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            if (dateText != null)
                              Text(
                                dateText,
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(color: mutedInk),
                              ),
                            StatusPill(status: status, compact: true),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  MoneyText(formatMoney(bill.amount)),
                  if (trailing != null) ...[
                    const SizedBox(width: 2),
                    trailing!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

String _compactDate(String iso, DateTime today) {
  final date = parseIsoDate(iso);
  return date.year == today.year ? dayMonthLabel(iso) : dateLabel(iso);
}
