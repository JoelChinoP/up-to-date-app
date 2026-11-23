import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../logic/bill_rules.dart';
import '../models/app_data.dart';
import '../widgets/bill_list_tile.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/month_selector.dart';

class SummaryScreen extends StatefulWidget {
  const SummaryScreen({
    super.key,
    required this.data,
    required this.today,
    required this.onAddService,
    required this.onRegisterBill,
    this.onViewService,
    this.onLoadDemo,
    this.onClearDemo,
    this.onOpenStorageInfo,
  });

  final AppData data;
  final DateTime today;
  final VoidCallback onAddService;
  final VoidCallback onRegisterBill;
  final ValueChanged<Service>? onViewService;
  final Future<void> Function()? onLoadDemo;
  final Future<void> Function()? onClearDemo;
  final Future<void> Function()? onOpenStorageInfo;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  late DateTime _month;
  bool _followToday = true;

  @override
  void initState() {
    super.initState();
    _month = monthStart(widget.today);
  }

  @override
  void didUpdateWidget(SummaryScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_followToday && !isSameMonth(widget.today, _month)) {
      _month = monthStart(widget.today);
    }
  }

  Future<void> _loadDemo() async {
    final callback = widget.onLoadDemo;
    if (callback == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Cargar datos de ejemplo',
      message:
          'Se agregarán cuatro servicios y varios recibos ficticios para '
          'probar la aplicación. No se mezclarán con datos propios.',
      confirmLabel: 'Cargar ejemplo',
    );
    if (!confirmed || !mounted) return;
    try {
      await callback();
      if (mounted) showMessage(context, 'Datos de ejemplo cargados.');
    } catch (error) {
      if (mounted) showMessage(context, _messageFor(error));
    }
  }

  Future<void> _clearDemo() async {
    final callback = widget.onClearDemo;
    if (callback == null) return;
    final confirmed = await confirmAction(
      context,
      title: 'Quitar datos de ejemplo',
      message:
          'Se eliminarán los servicios y recibos de ejemplo de este '
          'dispositivo. Esta acción no afecta a datos que hayas creado tú.',
      confirmLabel: 'Quitar ejemplo',
    );
    if (!confirmed || !mounted) return;
    try {
      await callback();
      if (mounted) showMessage(context, 'Datos de ejemplo eliminados.');
    } catch (error) {
      if (mounted) showMessage(context, _messageFor(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = summarizeMonth(widget.data, _month);
    final overdue = overdueBills(widget.data, widget.today);
    final upcoming = upcomingBills(widget.data, _month, widget.today);
    final hasServices = widget.data.services.isNotEmpty;

    return SingleChildScrollView(
      child: ContentFrame(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              title: 'AlDía',
              subtitle: 'Recibos y pagos del hogar',
              compactTrailing: true,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.onOpenStorageInfo != null)
                    IconButton(
                      tooltip: 'Datos guardados en este dispositivo',
                      onPressed: widget.onOpenStorageInfo,
                      icon: const Icon(Icons.info_outline),
                    ),
                  if (widget.data.demo)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Chip(
                        label: const Text('Ejemplo'),
                        labelStyle: const TextStyle(
                          color: mutedInk,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                        backgroundColor: softSurface,
                        side: const BorderSide(color: softDivider),
                        visualDensity: VisualDensity.compact,
                        onDeleted: widget.onClearDemo == null
                            ? null
                            : _clearDemo,
                        deleteButtonTooltipMessage: 'Quitar datos de ejemplo',
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            MonthSelector(
              month: _month,
              today: widget.today,
              onChanged: (value) => setState(() {
                _month = value;
                _followToday = isSameMonth(value, widget.today);
              }),
            ),
            const SizedBox(height: 20),
            if (!hasServices)
              _EmptyStart(
                onAddService: widget.onAddService,
                onLoadDemo: widget.onLoadDemo == null ? null : _loadDemo,
              )
            else ...[
              LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 760;
                  final pending = _PendingPanel(
                    summary: summary,
                    onRegisterBill: widget.onRegisterBill,
                  );
                  final side = _SideColumn(
                    data: widget.data,
                    month: _month,
                    today: widget.today,
                    overdue: overdue,
                    upcoming: upcoming,
                    onViewService: widget.onViewService,
                  );
                  if (!wide) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [pending, const SizedBox(height: 28), side],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(flex: 5, child: pending),
                      const SizedBox(width: 24),
                      Expanded(flex: 6, child: side),
                    ],
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _EmptyStart extends StatelessWidget {
  const _EmptyStart({required this.onAddService, this.onLoadDemo});

  final VoidCallback onAddService;
  final VoidCallback? onLoadDemo;

  @override
  Widget build(BuildContext context) {
    return MoSurface(
      fill: true,
      border: false,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EmptyState(
            icon: Icons.receipt_long_outlined,
            title: 'Empieza por un servicio',
            message:
                'Agrega luz, agua o internet para registrar tu primer recibo.',
            action: FilledButton.icon(
              onPressed: onAddService,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Agregar servicio'),
            ),
          ),
          if (onLoadDemo != null) ...[
            const SizedBox(height: 18),
            TextButton.icon(
              onPressed: onLoadDemo,
              icon: const Icon(Icons.playlist_add, size: 20),
              label: const Text('Probar con datos de ejemplo'),
            ),
          ],
        ],
      ),
    );
  }
}

class _PendingPanel extends StatelessWidget {
  const _PendingPanel({required this.summary, required this.onRegisterBill});

  final MonthSummary summary;
  final VoidCallback onRegisterBill;

  @override
  Widget build(BuildContext context) {
    final emptyMonth = summary.totalCents == 0;
    return MoSurface(
      fill: true,
      border: false,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel('Pendiente este mes'),
          const SizedBox(height: 10),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 240),
            transitionBuilder: (child, animation) =>
                FadeTransition(opacity: animation, child: child),
            child: Text(
              formatMoney(summary.pendingCents),
              key: ValueKey(summary.pendingCents),
              style: Theme.of(context).textTheme.displaySmall,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 20,
            runSpacing: 4,
            children: [
              _SecondaryAmount(
                label: 'Pagado',
                value: formatMoney(summary.paidCents),
              ),
              _SecondaryAmount(
                label: 'Total',
                value: formatMoney(summary.totalCents),
              ),
            ],
          ),
          const SizedBox(height: 20),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(end: summary.progress / 100),
            duration: const Duration(milliseconds: 420),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Container(color: const Color(0xFFDDE5E0)),
                    FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: value.clamp(0.0, 1.0).toDouble(),
                      child: Container(color: accent),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${percentLabel(summary.progress)} pagado',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: mutedInk),
          ),
          const SizedBox(height: 18),
          if (emptyMonth)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Sin recibos este mes.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: mutedInk),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onRegisterBill,
              icon: const Icon(Icons.add, size: 20),
              label: const Text('Registrar recibo'),
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryAmount extends StatelessWidget {
  const _SecondaryAmount({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: mutedInk),
        ),
        MoneyText(value, style: Theme.of(context).textTheme.titleMedium),
      ],
    );
  }
}

class _SideColumn extends StatelessWidget {
  const _SideColumn({
    required this.data,
    required this.month,
    required this.today,
    required this.overdue,
    required this.upcoming,
    this.onViewService,
  });

  final AppData data;
  final DateTime month;
  final DateTime today;
  final List<Bill> overdue;
  final List<Bill> upcoming;
  final ValueChanged<Service>? onViewService;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (overdue.isNotEmpty) ...[
          SectionLabel(
            'Vencidos sin pagar',
            trailing: Text(
              '${overdue.length} '
              '${overdue.length == 1 ? 'recibo' : 'recibos'}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: mutedInk),
            ),
          ),
          const SizedBox(height: 8),
          for (final bill in overdue.take(4))
            BillListTile(
              bill: bill,
              service: data.serviceById(bill.serviceId),
              today: today,
              onTap: onViewService == null
                  ? null
                  : () {
                      final service = data.serviceById(bill.serviceId);
                      if (service != null) onViewService!(service);
                    },
            ),
          if (overdue.length > 4)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'y ${overdue.length - 4} más',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: mutedInk),
              ),
            ),
          const SizedBox(height: 20),
        ],
        SectionLabel(
          'Próximos vencimientos',
          trailing: Text(
            upcoming.isEmpty
                ? ''
                : '${upcoming.length} '
                      '${upcoming.length == 1 ? 'recibo' : 'recibos'}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: mutedInk),
          ),
        ),
        const SizedBox(height: 8),
        if (upcoming.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              'No hay vencimientos pendientes en este mes.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: mutedInk),
            ),
          )
        else
          for (final bill in upcoming.take(4))
            BillListTile(
              bill: bill,
              service: data.serviceById(bill.serviceId),
              today: today,
              onTap: onViewService == null
                  ? null
                  : () {
                      final service = data.serviceById(bill.serviceId);
                      if (service != null) onViewService!(service);
                    },
            ),
      ],
    );
  }
}

String _messageFor(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}
