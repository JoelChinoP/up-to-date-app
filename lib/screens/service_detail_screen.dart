import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../logic/bill_rules.dart';
import '../models/app_data.dart';
import '../widgets/bill_list_tile.dart';
import '../widgets/category_icon.dart';
import '../widgets/layout_widgets.dart';

class ServiceDetailScreen extends StatefulWidget {
  const ServiceDetailScreen({
    super.key,
    required this.data,
    required this.service,
    required this.today,
    required this.onRegisterBill,
    required this.onEditService,
    required this.onDeleteService,
    required this.onEditBill,
    required this.onDeleteBill,
    required this.onTogglePaid,
    this.busy = false,
  });

  final AppData data;
  final Service service;
  final DateTime today;
  final VoidCallback onRegisterBill;
  final VoidCallback onEditService;
  final VoidCallback onDeleteService;
  final ValueChanged<Bill> onEditBill;
  final ValueChanged<Bill> onDeleteBill;
  final ValueChanged<Bill> onTogglePaid;
  final bool busy;

  @override
  State<ServiceDetailScreen> createState() => _ServiceDetailScreenState();
}

class _ServiceDetailScreenState extends State<ServiceDetailScreen> {
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _selectedId = _firstBill()?.id;
  }

  @override
  void didUpdateWidget(ServiceDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    final bills = _bills;
    if (_selectedId == null || !bills.any((bill) => bill.id == _selectedId)) {
      _selectedId = bills.isEmpty ? null : bills.first.id;
    }
  }

  List<Bill> get _bills => billsForService(widget.data, widget.service.id);

  Bill? _firstBill() {
    final bills = _bills;
    return bills.isEmpty ? null : bills.first;
  }

  Bill? get _selected {
    final bills = _bills;
    if (bills.isEmpty) return null;
    for (final bill in bills) {
      if (bill.id == _selectedId) return bill;
    }
    return bills.first;
  }

  @override
  Widget build(BuildContext context) {
    final bills = _bills;
    final selected = _selected;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.service.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              widget.service.category,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedInk),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            tooltip: 'Acciones del servicio',
            enabled: !widget.busy,
            onSelected: (value) {
              if (value == 'edit') widget.onEditService();
              if (value == 'delete') widget.onDeleteService();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'edit',
                child: ListTile(
                  leading: Icon(
                    Icons.edit_outlined,
                    size: 20,
                    color: accentDark,
                  ),
                  title: Text('Editar servicio'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'delete',
                child: ListTile(
                  leading: Icon(Icons.delete_outline, size: 20, color: lateInk),
                  title: Text('Eliminar servicio'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: SingleChildScrollView(
        child: ContentFrame(
          maxWidth: 900,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LayoutBuilder(
                builder: (context, constraints) {
                  final summary = Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: accentSoft,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          categoryIcon(widget.service.category),
                          size: 22,
                          color: accentDark,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          '${bills.length} '
                          '${bills.length == 1 ? 'recibo' : 'recibos'}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                    ],
                  );
                  final action = OutlinedButton.icon(
                    onPressed: widget.busy ? null : widget.onRegisterBill,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Registrar recibo'),
                  );
                  if (constraints.maxWidth < 520) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        summary,
                        const SizedBox(height: 10),
                        SizedBox(width: double.infinity, child: action),
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: summary),
                      const SizedBox(width: 12),
                      action,
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              if (bills.isEmpty || selected == null)
                EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Este servicio todavía no tiene recibos',
                  message: 'Registra el primer recibo de este servicio.',
                  action: FilledButton.icon(
                    onPressed: widget.busy ? null : widget.onRegisterBill,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Registrar recibo'),
                  ),
                )
              else ...[
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  transitionBuilder: (child, animation) =>
                      FadeTransition(opacity: animation, child: child),
                  child: _ComparisonPanel(
                    key: ValueKey(selected.id),
                    bill: selected,
                    allBills: bills,
                    today: widget.today,
                  ),
                ),
                const SizedBox(height: 28),
                SectionLabel(
                  'Historial de recibos',
                  trailing: Text(
                    '${bills.length} '
                    '${bills.length == 1 ? 'recibo' : 'recibos'}',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: mutedInk),
                  ),
                ),
                const SizedBox(height: 8),
                for (final bill in bills)
                  BillListTile(
                    bill: bill,
                    service: widget.service,
                    today: widget.today,
                    titleOverride:
                        'Recibo de ${monthShortLabel(parseIsoDate(bill.dueDate))}',
                    selected: bill.id == selected.id,
                    onTap: () => setState(() => _selectedId = bill.id),
                    trailing: PopupMenuButton<String>(
                      tooltip: 'Acciones del recibo',
                      enabled: !widget.busy,
                      onSelected: (value) {
                        if (value == 'edit') widget.onEditBill(bill);
                        if (value == 'toggle') widget.onTogglePaid(bill);
                        if (value == 'delete') widget.onDeleteBill(bill);
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: ListTile(
                            leading: Icon(
                              Icons.edit_outlined,
                              size: 20,
                              color: accentDark,
                            ),
                            title: Text('Editar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        PopupMenuItem(
                          value: 'toggle',
                          child: ListTile(
                            leading: Icon(
                              bill.paid
                                  ? Icons.undo_outlined
                                  : Icons.check_circle_outline,
                              size: 20,
                              color: bill.paid ? soonInk : paidInk,
                            ),
                            title: Text(
                              bill.paid
                                  ? 'Marcar como pendiente'
                                  : 'Marcar como pagado',
                            ),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: ListTile(
                            leading: Icon(
                              Icons.delete_outline,
                              size: 20,
                              color: lateInk,
                            ),
                            title: Text('Eliminar'),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _ComparisonPanel extends StatelessWidget {
  const _ComparisonPanel({
    super.key,
    required this.bill,
    required this.allBills,
    required this.today,
  });

  final Bill bill;
  final List<Bill> allBills;
  final DateTime today;

  @override
  Widget build(BuildContext context) {
    final comparison = compareBill(bill, allBills);
    final status = billStatus(bill, today);
    final variation = comparison.variationPercent;
    return MoSurface(
      fill: true,
      border: false,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionLabel('Comparación de montos'),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(statusIcon(status.kind), size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recibo de ${monthShortLabel(parseIsoDate(bill.dueDate))}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 3,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Vence el ${dateLabel(bill.dueDate)}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: mutedInk),
                        ),
                        StatusPill(status: status, compact: true),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              MoneyText(
                formatMoney(bill.amount),
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _variationSurface(comparison.kind),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  _variationIcon(comparison.kind),
                  size: 22,
                  color: _variationColor(comparison.kind),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _variationTitle(comparison.kind),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (variation != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: _variationSurface(comparison.kind),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _signedPercent(variation),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: _variationColor(comparison.kind),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          if (comparison.previous.isNotEmpty) ...[
            const SizedBox(height: 16),
            Table(
              columnWidths: const {
                0: FlexColumnWidth(),
                1: IntrinsicColumnWidth(),
              },
              children: [
                TableRow(
                  children: [
                    _tableText(context, 'Recibos anteriores', header: true),
                    _tableText(
                      context,
                      'Monto',
                      header: true,
                      align: TextAlign.end,
                    ),
                  ],
                ),
                for (final previous in comparison.previous)
                  TableRow(
                    children: [
                      _tableText(
                        context,
                        monthShortLabel(parseIsoDate(previous.dueDate)),
                      ),
                      _tableText(
                        context,
                        formatMoney(previous.amount),
                        align: TextAlign.end,
                      ),
                    ],
                  ),
                if (comparison.hasBase) ...[
                  TableRow(
                    children: [
                      _tableText(context, 'Promedio de 3', header: true),
                      _tableText(
                        context,
                        formatMoney(comparison.averageCents!.round()),
                        header: true,
                        align: TextAlign.end,
                      ),
                    ],
                  ),
                ],
              ],
            ),
            if (!comparison.hasBase) ...[
              const SizedBox(height: 8),
              Text(
                '${comparison.previous.length} de 3 antecedentes.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: mutedInk),
              ),
            ],
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 10),
          Text(
            'Variación de monto, no de consumo.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: mutedInk),
          ),
        ],
      ),
    );
  }
}

Widget _tableText(
  BuildContext context,
  String text, {
  bool header = false,
  TextAlign align = TextAlign.start,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(
      text,
      textAlign: align,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        fontWeight: header ? FontWeight.w700 : FontWeight.w400,
        color: header ? ink : mutedInk,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    ),
  );
}

IconData _variationIcon(VariationKind kind) => switch (kind) {
  VariationKind.unknown => Icons.help_outline,
  VariationKind.normal => Icons.check_circle_outline,
  VariationKind.increased => Icons.trending_up,
  VariationKind.unusual => Icons.warning_amber_outlined,
};

Color _variationColor(VariationKind kind) => switch (kind) {
  VariationKind.unknown => mutedInk,
  VariationKind.normal => paidInk,
  VariationKind.increased => soonInk,
  VariationKind.unusual => lateInk,
};

Color _variationSurface(VariationKind kind) => switch (kind) {
  VariationKind.unknown => softSurface,
  VariationKind.normal => paidSoft,
  VariationKind.increased => soonSoft,
  VariationKind.unusual => lateSoft,
};

String _variationTitle(VariationKind kind) => switch (kind) {
  VariationKind.unknown => 'Faltan antecedentes',
  VariationKind.normal => 'Dentro de lo habitual',
  VariationKind.increased => 'Monto en aumento',
  VariationKind.unusual => 'Aumento inusual',
};

String _signedPercent(double value) {
  final rounded = value.round();
  return '${rounded > 0 ? '+' : ''}$rounded %';
}
