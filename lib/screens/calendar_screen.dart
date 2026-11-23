import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../logic/bill_rules.dart';
import '../models/app_data.dart';
import '../widgets/bill_list_tile.dart';
import '../widgets/layout_widgets.dart';
import '../widgets/month_selector.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({
    super.key,
    required this.data,
    required this.today,
    required this.onRegisterBill,
    required this.onOpenService,
    this.busy = false,
  });

  final AppData data;
  final DateTime today;
  final VoidCallback onRegisterBill;
  final ValueChanged<Service> onOpenService;
  final bool busy;

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  late DateTime _month;
  DateTime? _selectedDay;

  @override
  void initState() {
    super.initState();
    _month = monthStart(widget.today);
  }

  void _changeMonth(DateTime month) {
    setState(() {
      _month = month;
      _selectedDay = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final calendar = calendarMonth(_month);
    final monthBills = widget.data.bills
        .where((bill) => billBelongsToMonth(bill, _month))
        .toList();
    final dayBills = _selectedDay == null
        ? const <Bill>[]
        : (billsForDay(widget.data, _selectedDay!).toList()..sort((a, b) {
            final nameA =
                widget.data.serviceById(a.serviceId)?.name ?? a.serviceId;
            final nameB =
                widget.data.serviceById(b.serviceId)?.name ?? b.serviceId;
            return nameA.compareTo(nameB);
          }));

    return SingleChildScrollView(
      child: ContentFrame(
        horizontalPadding: 12,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PageHeading(
              title: 'Calendario',
              trailing: FilledButton.icon(
                onPressed: widget.busy ? null : widget.onRegisterBill,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Registrar recibo'),
              ),
            ),
            const SizedBox(height: 12),
            MonthSelector(
              month: _month,
              today: widget.today,
              onChanged: _changeMonth,
            ),
            const SizedBox(height: 4),
            Text(
              monthBills.isEmpty
                  ? 'Este mes no tiene recibos registrados.'
                  : '${monthBills.length} '
                        '${monthBills.length == 1 ? 'recibo' : 'recibos'} en '
                        'este mes.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: mutedInk),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 760;
                final calendarPanel = _CalendarPanel(
                  month: _month,
                  calendar: calendar,
                  bills: widget.data.bills,
                  today: widget.today,
                  selectedDay: _selectedDay,
                  onSelect: (day) => setState(() => _selectedDay = day),
                );
                final dayPanel = _DayPanel(
                  data: widget.data,
                  today: widget.today,
                  selectedDay: _selectedDay,
                  bills: dayBills,
                  onOpenService: widget.onOpenService,
                );
                if (!wide) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      calendarPanel,
                      const SizedBox(height: 24),
                      dayPanel,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 5, child: calendarPanel),
                    const SizedBox(width: 24),
                    Expanded(flex: 6, child: dayPanel),
                  ],
                );
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

class _CalendarPanel extends StatelessWidget {
  const _CalendarPanel({
    required this.month,
    required this.calendar,
    required this.bills,
    required this.today,
    required this.selectedDay,
    required this.onSelect,
  });

  final DateTime month;
  final CalendarMonth calendar;
  final List<Bill> bills;
  final DateTime today;
  final DateTime? selectedDay;
  final ValueChanged<DateTime> onSelect;

  List<Bill> _billsFor(DateTime day) {
    final key = isoDate(day);
    return bills.where((bill) => bill.dueDate == key).toList();
  }

  @override
  Widget build(BuildContext context) {
    final cells = <Widget>[];
    final total = calendar.rows * 7;
    for (var index = 0; index < total; index++) {
      final dayNumber = index - calendar.leadingEmpty + 1;
      if (dayNumber < 1 || dayNumber > calendar.days) {
        cells.add(const SizedBox(height: 58));
        continue;
      }
      final day = DateTime.utc(month.year, month.month, dayNumber);
      final dayBills = _billsFor(day);
      final isToday = isoDate(day) == isoDate(today);
      final isSelected =
          selectedDay != null && isoDate(day) == isoDate(selectedDay!);
      cells.add(
        Semantics(
          button: true,
          selected: isSelected,
          label:
              '${weekdayLong(day.weekday)} ${day.day} de '
              '${monthLabel(month)}${isToday ? ', hoy' : ''}'
              '${dayBills.isEmpty ? ', sin recibos' : ', ${dayBills.length} recibos'}'
              '${isSelected ? ', seleccionado' : ''}',
          child: ExcludeSemantics(
            child: InkWell(
              onTap: () => onSelect(day),
              borderRadius: BorderRadius.circular(6),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOut,
                height: 58,
                margin: const EdgeInsets.all(1.5),
                decoration: BoxDecoration(
                  color: isSelected ? accentSoft : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? accent : Colors.transparent,
                    width: 2,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${day.day}',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: isToday || isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isToday ? accentDark : ink,
                        decoration: isToday
                            ? TextDecoration.underline
                            : TextDecoration.none,
                        decorationColor: accent,
                        decorationThickness: 2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    if (dayBills.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: _dayStatusColor(dayBills, today),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${dayBills.length}',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: paper, fontSize: 11),
                        ),
                      )
                    else if (isToday)
                      Text(
                        'hoy',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 10,
                          color: mutedInk,
                        ),
                      )
                    else
                      const SizedBox(height: 14),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var weekday = 1; weekday <= 7; weekday++)
              Expanded(
                child: Center(
                  child: Text(
                    weekdayShort(weekday),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: mutedInk),
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var row = 0; row < calendar.rows; row++)
          Row(
            children: [
              for (var column = 0; column < 7; column++)
                Expanded(child: cells[row * 7 + column]),
            ],
          ),
      ],
    );
  }
}

class _DayPanel extends StatelessWidget {
  const _DayPanel({
    required this.data,
    required this.today,
    required this.selectedDay,
    required this.bills,
    required this.onOpenService,
  });

  final AppData data;
  final DateTime today;
  final DateTime? selectedDay;
  final List<Bill> bills;
  final ValueChanged<Service> onOpenService;

  @override
  Widget build(BuildContext context) {
    final selected = selectedDay;
    if (selected == null) {
      return MoSurface(
        fill: true,
        border: false,
        padding: const EdgeInsets.all(20),
        child: EmptyState(
          icon: Icons.touch_app_outlined,
          title: 'Selecciona un día',
          message: 'Verás los recibos que vencen en esa fecha.',
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel('Día seleccionado'),
        const SizedBox(height: 6),
        Text(
          longDateLabel(selected),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 2),
        Text(
          bills.isEmpty
              ? 'Sin recibos este día.'
              : '${bills.length} '
                    '${bills.length == 1 ? 'recibo' : 'recibos'}',
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(color: mutedInk),
        ),
        const SizedBox(height: 8),
        if (bills.isEmpty)
          const SizedBox(height: 12)
        else
          for (final bill in bills)
            BillListTile(
              bill: bill,
              service: data.serviceById(bill.serviceId),
              today: today,
              showDueDate: false,
              onTap: () {
                final service = data.serviceById(bill.serviceId);
                if (service != null) onOpenService(service);
              },
            ),
      ],
    );
  }
}

Color _dayStatusColor(List<Bill> bills, DateTime today) {
  final statuses = bills.map((bill) => billStatus(bill, today).kind).toList();
  if (statuses.contains(BillStatusKind.late)) return lateInk;
  if (statuses.contains(BillStatusKind.today) ||
      statuses.contains(BillStatusKind.soon)) {
    return soonInk;
  }
  if (statuses.every((kind) => kind == BillStatusKind.paid)) return paidInk;
  return mutedInk;
}
