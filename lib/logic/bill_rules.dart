import '../models/app_data.dart';

/// Categorías admitidas por el modelo de datos.
const int minAmountCents = 1;
const int maxAmountCents = 100000000;

/// Convierte un monto escrito por la persona usuaria a céntimos.
///
/// Se acepta punto o coma como separador decimal, pero no ambos ni
/// separadores de miles. No se pasa por `double`, de modo que el valor
/// guardado no dependa de un redondeo binario.
int parseAmountCents(String input) {
  final text = input.trim().replaceAll(',', '.');
  if (!RegExp(r'^\d{1,7}(\.\d{1,2})?$').hasMatch(text)) {
    throw const FormatException(
      'Ingresa un monto positivo con hasta dos decimales.',
    );
  }
  final parts = text.split('.');
  final whole = int.parse(parts[0]);
  final fraction = parts.length == 2 ? parts[1].padRight(2, '0') : '00';
  final cents = whole * 100 + int.parse(fraction);
  if (cents < minAmountCents || cents > maxAmountCents) {
    throw const FormatException(
      'El monto debe estar entre S/ 0.01 y S/ 1 000 000.00.',
    );
  }
  return cents;
}

/// Presenta céntimos como `S/ 1 234.56`, sin modificar el valor guardado.
String formatMoney(int cents) {
  final whole = cents ~/ 100;
  final fraction = (cents % 100).toString().padLeft(2, '0');
  final digits = whole.toString();
  final buffer = StringBuffer();
  for (var index = 0; index < digits.length; index++) {
    if (index > 0 && (digits.length - index) % 3 == 0) buffer.write(' ');
    buffer.write(digits[index]);
  }
  return 'S/ $buffer.$fraction';
}

/// Presenta céntimos sin el prefijo, para tablas y cálculos.
String formatCentsPlain(int cents) {
  final text = formatMoney(cents);
  return text.substring(3);
}

/// Monto editable, sin separadores de miles, para volver a un formulario.
String formatCentsForInput(int cents) =>
    '${cents ~/ 100}.${(cents % 100).toString().padLeft(2, '0')}';

const _monthNames = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

const _monthShort = [
  'ene',
  'feb',
  'mar',
  'abr',
  'may',
  'jun',
  'jul',
  'ago',
  'sep',
  'oct',
  'nov',
  'dic',
];

const _weekdayShort = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];

const _weekdayLong = [
  'lunes',
  'martes',
  'miércoles',
  'jueves',
  'viernes',
  'sábado',
  'domingo',
];

String monthLabel(DateTime month) =>
    '${_monthNames[month.month - 1]} de ${month.year}';

String monthShortLabel(DateTime month) =>
    '${_monthShort[month.month - 1]} ${month.year}';

String weekdayShort(int weekday) => _weekdayShort[weekday - 1];

String weekdayLong(int weekday) => _weekdayLong[weekday - 1];

/// Día civil de hoy, normalizado a UTC para evitar cambios de horario.
DateTime todayCivil([DateTime? now]) {
  final local = now ?? DateTime.now();
  return DateTime.utc(local.year, local.month, local.day);
}

DateTime monthStart(DateTime date) => DateTime.utc(date.year, date.month);

String isoDate(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Valida una fecha civil `YYYY-MM-DD` sin aceptar normalizaciones de Dart.
bool isValidIsoDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final year = int.parse(value.substring(0, 4));
  final month = int.parse(value.substring(5, 7));
  final day = int.parse(value.substring(8, 10));
  if (year < 2000 || year > 2100) return false;
  if (month < 1 || month > 12 || day < 1) return false;
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

DateTime parseIsoDate(String value) {
  if (!isValidIsoDate(value)) {
    throw FormatException('Fecha inválida: $value');
  }
  return DateTime.utc(
    int.parse(value.substring(0, 4)),
    int.parse(value.substring(5, 7)),
    int.parse(value.substring(8, 10)),
  );
}

String dateLabel(String iso) {
  final date = parseIsoDate(iso);
  return '${date.day} ${_monthShort[date.month - 1]} ${date.year}';
}

String dayMonthLabel(String iso) {
  final date = parseIsoDate(iso);
  return '${date.day} ${_monthShort[date.month - 1]}';
}

String longDateLabel(DateTime date) =>
    '${weekdayLong(date.weekday)} ${date.day} de ${_monthNames[date.month - 1]}';

int daysBetween(String fromIso, String toIso) {
  final from = parseIsoDate(fromIso);
  final to = parseIsoDate(toIso);
  return to.difference(from).inDays;
}

/// Mes calendario al que pertenece un recibo, según su vencimiento.
String billMonth(Bill bill) => bill.dueDate.substring(0, 7);

String monthKey(DateTime month) =>
    '${month.year.toString().padLeft(4, '0')}-'
    '${month.month.toString().padLeft(2, '0')}';

bool billBelongsToMonth(Bill bill, DateTime month) =>
    billMonth(bill) == monthKey(month);

enum BillStatusKind { paid, late, today, soon, pending }

class BillStatus {
  const BillStatus(this.kind, this.label);

  final BillStatusKind kind;
  final String label;
}

/// Estado de vencimiento. Un recibo pagado nunca se muestra como vencido.
BillStatus billStatus(Bill bill, DateTime today) {
  if (bill.paid) return const BillStatus(BillStatusKind.paid, 'Pagado');
  final days = daysBetween(isoDate(today), bill.dueDate);
  if (days < 0) {
    final count = -days;
    return BillStatus(
      BillStatusKind.late,
      'Vencido hace $count ${count == 1 ? 'día' : 'días'}',
    );
  }
  if (days == 0) return const BillStatus(BillStatusKind.today, 'Vence hoy');
  if (days <= 3) {
    return BillStatus(
      BillStatusKind.soon,
      'Vence en $days ${days == 1 ? 'día' : 'días'}',
    );
  }
  return BillStatus(BillStatusKind.pending, 'Vence en $days días');
}

enum VariationKind { unknown, normal, increased, unusual }

class BillComparison {
  const BillComparison({
    required this.kind,
    required this.previous,
    required this.sumCents,
    required this.averageCents,
    required this.variationPercent,
    required this.message,
  });

  final VariationKind kind;
  final List<Bill> previous;
  final int sumCents;
  final double? averageCents;
  final double? variationPercent;
  final String message;

  bool get hasBase => kind != VariationKind.unknown;
}

/// Compara un recibo con los tres recibos anteriores más recientes del
/// mismo servicio, excluyendo su propio mes y los posteriores.
BillComparison compareBill(Bill bill, Iterable<Bill> allBills) {
  final previous =
      allBills
          .where(
            (item) =>
                item.serviceId == bill.serviceId &&
                item.id != bill.id &&
                billMonth(item).compareTo(billMonth(bill)) < 0,
          )
          .toList()
        ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
  final selected = previous.take(3).toList();

  if (selected.length < 3) {
    return BillComparison(
      kind: VariationKind.unknown,
      previous: selected,
      sumCents: 0,
      averageCents: null,
      variationPercent: null,
      message:
          'Se necesitan 3 recibos anteriores de este servicio para comparar.',
    );
  }

  final sum = selected.fold<int>(0, (total, item) => total + item.amount);
  if (sum <= 0) {
    return BillComparison(
      kind: VariationKind.unknown,
      previous: selected,
      sumCents: sum,
      averageCents: null,
      variationPercent: null,
      message: 'Sin base suficiente para comparar: el promedio es cero.',
    );
  }

  // Se comparan productos enteros para que los límites del 10 % y 25 %
  // sean exactos, sin depender del porcentaje redondeado que se muestra.
  final delta = 3 * bill.amount - sum;
  final kind = delta * 100 < 10 * sum
      ? VariationKind.normal
      : delta * 100 <= 25 * sum
      ? VariationKind.increased
      : VariationKind.unusual;
  final variation = delta / sum * 100;
  final rounded = variation.round();

  final label = switch (kind) {
    VariationKind.normal => 'Dentro de lo habitual',
    VariationKind.increased => 'Monto en aumento',
    VariationKind.unusual => 'Aumento inusual',
    VariationKind.unknown => 'Sin base suficiente',
  };
  final message = rounded == 0
      ? '$label: el monto es casi igual al promedio anterior.'
      : variation > 0
      ? '$label: este recibo aumentó $rounded % frente al promedio anterior.'
      : '$label: este recibo disminuyó ${-rounded} % frente al promedio anterior.';

  return BillComparison(
    kind: kind,
    previous: selected,
    sumCents: sum,
    averageCents: sum / 3,
    variationPercent: variation,
    message: message,
  );
}

class MonthSummary {
  const MonthSummary({
    required this.bills,
    required this.totalCents,
    required this.paidCents,
    required this.pendingCents,
    required this.paidCount,
    required this.pendingCount,
  });

  final List<Bill> bills;
  final int totalCents;
  final int paidCents;
  final int pendingCents;
  final int paidCount;
  final int pendingCount;

  double get progress => totalCents == 0 ? 0 : paidCents / totalCents * 100;
}

MonthSummary summarizeMonth(AppData data, DateTime month) {
  final bills =
      data.bills.where((bill) => billBelongsToMonth(bill, month)).toList()
        ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
  var total = 0;
  var paid = 0;
  var paidCount = 0;
  for (final bill in bills) {
    total += bill.amount;
    if (bill.paid) {
      paid += bill.amount;
      paidCount++;
    }
  }
  return MonthSummary(
    bills: bills,
    totalCents: total,
    paidCents: paid,
    pendingCents: total - paid,
    paidCount: paidCount,
    pendingCount: bills.length - paidCount,
  );
}

List<Bill> billsForService(AppData data, String serviceId) =>
    data.bills.where((bill) => bill.serviceId == serviceId).toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));

List<Bill> billsForDay(AppData data, DateTime day) {
  final key = isoDate(day);
  return data.bills.where((bill) => bill.dueDate == key).toList()
    ..sort((a, b) => a.serviceId.compareTo(b.serviceId));
}

List<Bill> overdueBills(AppData data, DateTime today) {
  final key = isoDate(today);
  return data.bills
      .where((bill) => !bill.paid && bill.dueDate.compareTo(key) < 0)
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}

List<Bill> upcomingBills(AppData data, DateTime month, DateTime today) {
  final todayKey = isoDate(today);
  return data.bills
      .where(
        (bill) =>
            !bill.paid &&
            billBelongsToMonth(bill, month) &&
            bill.dueDate.compareTo(todayKey) >= 0,
      )
      .toList()
    ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
}

class CalendarMonth {
  const CalendarMonth({
    required this.month,
    required this.leadingEmpty,
    required this.days,
  });

  final DateTime month;
  final int leadingEmpty;
  final int days;

  int get rows => ((leadingEmpty + days) / 7).ceil();
}

CalendarMonth calendarMonth(DateTime month) {
  final first = monthStart(month);
  final next = DateTime.utc(first.year, first.month + 1);
  return CalendarMonth(
    month: first,
    leadingEmpty: first.weekday - 1,
    days: next.difference(first).inDays,
  );
}

/// Comparación simple usada en pruebas y por la interfaz.
int compareMonth(DateTime a, DateTime b) =>
    monthStart(a).compareTo(monthStart(b));

DateTime addMonths(DateTime month, int delta) =>
    DateTime.utc(month.year, month.month + delta);

bool isSameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

String percentLabel(double value) => '${value.round()} %';
