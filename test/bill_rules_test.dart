import 'package:aldia_flutter/logic/bill_rules.dart';
import 'package:aldia_flutter/models/app_data.dart';
import 'package:flutter_test/flutter_test.dart';

Bill bill(
  String id,
  String dueDate,
  int amount, {
  String serviceId = 's1',
  bool paid = false,
  String? paidAt,
}) => Bill(
  id: id,
  serviceId: serviceId,
  amount: amount,
  dueDate: dueDate,
  paid: paid,
  paidAt: paid ? (paidAt ?? dueDate) : null,
  createdAt: '2026-01-01T00:00:00.000Z',
);

void main() {
  group('montos', () {
    test('T-B01 convierte punto y coma sin pasar por double', () {
      expect(parseAmountCents('86.40'), 8640);
      expect(parseAmountCents('0,01'), 1);
      expect(parseAmountCents(' 12 '), 1200);
      expect(parseAmountCents('1000000'), 100000000);
      expect(parseAmountCents('1000000.00'), 100000000);
    });

    test('T-B02 rechaza cero, negativos, exponentes y exceso de decimales', () {
      for (final value in [
        '0',
        '0.00',
        '-1',
        '1.234',
        '1e3',
        '1,234',
        '1000000.01',
        '.5',
        '1.',
        'abc',
        '',
      ]) {
        expect(
          () => parseAmountCents(value),
          throwsA(isA<FormatException>()),
          reason: value,
        );
      }
    });

    test('formatea céntimos y conserva el valor para editar', () {
      expect(formatMoney(8640), 'S/ 86.40');
      expect(formatMoney(1), 'S/ 0.01');
      expect(formatMoney(100000000), 'S/ 1 000 000.00');
      expect(formatCentsForInput(8640), '86.40');
      expect(parseAmountCents(formatCentsForInput(123456)), 123456);
    });
  });

  group('fechas', () {
    test('T-B04 valida años bisiestos y fechas imposibles', () {
      expect(isValidIsoDate('2024-02-29'), isTrue);
      expect(isValidIsoDate('2023-02-29'), isFalse);
      expect(isValidIsoDate('2026-04-31'), isFalse);
      expect(isValidIsoDate('2026-13-01'), isFalse);
      expect(isValidIsoDate('1999-12-31'), isFalse);
      expect(isValidIsoDate('2101-01-01'), isFalse);
      expect(isValidIsoDate('2100-12-31'), isTrue);
    });

    test('calcula días civiles y etiquetas en español', () {
      final today = DateTime.utc(2026, 11, 12);
      expect(isoDate(today), '2026-11-12');
      expect(daysBetween('2026-11-12', '2026-11-15'), 3);
      expect(dateLabel('2026-11-15'), '15 nov 2026');
      expect(monthLabel(today), 'noviembre de 2026');
      expect(longDateLabel(today), 'jueves 12 de noviembre');
      expect(isSameMonth(today, DateTime.utc(2026, 11, 30)), isTrue);
      expect(monthKey(addMonths(DateTime.utc(2026, 12, 1), 1)), '2027-01');
    });
  });

  group('estados de vencimiento', () {
    final today = DateTime.utc(2026, 11, 12);

    test('T-D01 a T-D05 distinguen vencido, hoy, próximo y pagado', () {
      expect(
        billStatus(bill('a', '2026-11-11', 100), today).kind,
        BillStatusKind.late,
      );
      expect(
        billStatus(bill('b', '2026-11-12', 100), today).kind,
        BillStatusKind.today,
      );
      expect(
        billStatus(bill('c', '2026-11-15', 100), today).kind,
        BillStatusKind.soon,
      );
      expect(
        billStatus(bill('d', '2026-11-16', 100), today).kind,
        BillStatusKind.pending,
      );
      expect(
        billStatus(bill('e', '2026-11-01', 100, paid: true), today).kind,
        BillStatusKind.paid,
      );
      expect(
        billStatus(bill('e', '2026-11-01', 100, paid: true), today).label,
        'Pagado',
      );
    });
  });

  group('comparación de montos', () {
    test('T-A01 exige tres antecedentes', () {
      final current = bill('current', '2026-12-15', 5000);
      final result = compareBill(current, [
        current,
        bill('a', '2026-11-15', 4000),
        bill('b', '2026-10-15', 4500),
      ]);
      expect(result.kind, VariationKind.unknown);
      expect(result.hasBase, isFalse);
      expect(result.message, contains('3 recibos anteriores'));
    });

    test('T-A02 ignora recibos futuros y del mismo mes', () {
      final current = bill('current', '2026-12-15', 5000);
      final result = compareBill(current, [
        current,
        bill('same-month', '2026-12-01', 9999),
        bill('future', '2027-01-15', 9999),
        bill('sep', '2026-09-15', 4000),
        bill('oct', '2026-10-15', 4500),
        bill('nov', '2026-11-15', 5000),
      ]);
      expect(result.hasBase, isTrue);
      expect(result.previous.map((item) => item.id), ['nov', 'oct', 'sep']);
    });

    test('T-A03 excluye antecedentes de otros servicios', () {
      final current = bill('current', '2026-12-15', 5000);
      final result = compareBill(current, [
        current,
        bill('other1', '2026-11-15', 1000, serviceId: 's2'),
        bill('other2', '2026-10-15', 1000, serviceId: 's2'),
        bill('other3', '2026-09-15', 1000, serviceId: 's2'),
        bill('a', '2026-11-15', 5000),
        bill('b', '2026-10-15', 5000),
        bill('c', '2026-09-15', 5000),
      ]);
      expect(result.previous.every((item) => item.serviceId == 's1'), isTrue);
      expect(result.variationPercent, 0);
    });

    test('T-A04 distingue 9.99 % de 10 % exacto', () {
      final previous = [
        bill('a', '2026-09-15', 10000),
        bill('b', '2026-10-15', 10000),
        bill('c', '2026-11-15', 10000),
      ];
      final almost = compareBill(
        bill('current', '2026-12-15', 10999),
        previous,
      );
      final exact = compareBill(bill('current', '2026-12-15', 11000), previous);
      expect(almost.kind, VariationKind.normal);
      expect(almost.variationPercent, closeTo(9.99, 0.001));
      expect(exact.kind, VariationKind.increased);
      expect(exact.variationPercent, 10);
    });

    test('T-A05 distingue 25 % exacto de más de 25 %', () {
      final previous = [
        bill('a', '2026-09-15', 10000),
        bill('b', '2026-10-15', 10000),
        bill('c', '2026-11-15', 10000),
      ];
      expect(
        compareBill(bill('current', '2026-12-15', 12500), previous).kind,
        VariationKind.increased,
      );
      expect(
        compareBill(bill('current', '2026-12-15', 12501), previous).kind,
        VariationKind.unusual,
      );
    });

    test('T-A06 una disminución no genera alarma', () {
      final result = compareBill(bill('current', '2026-12-15', 9000), [
        bill('a', '2026-09-15', 10000),
        bill('b', '2026-10-15', 10000),
        bill('c', '2026-11-15', 10000),
      ]);
      expect(result.kind, VariationKind.normal);
      expect(result.message, contains('disminuyó'));
    });

    test('T-A07 un promedio cero no divide', () {
      final result = compareBill(bill('current', '2026-12-15', 5000), [
        bill('a', '2026-09-15', 0),
        bill('b', '2026-10-15', 0),
        bill('c', '2026-11-15', 0),
      ]);
      expect(result.kind, VariationKind.unknown);
      expect(result.variationPercent, isNull);
      expect(result.message, contains('promedio es cero'));
    });

    test('T-A08 elige los tres anteriores más recientes no consecutivos', () {
      final result = compareBill(bill('current', '2026-12-15', 5000), [
        bill('jan', '2026-01-15', 1000),
        bill('mar', '2026-03-15', 2000),
        bill('jun', '2026-06-15', 3000),
        bill('sep', '2026-09-15', 4000),
        bill('current', '2026-12-15', 5000),
      ]);
      expect(result.previous.map((item) => item.id), ['sep', 'jun', 'mar']);
      expect(result.sumCents, 9000);
    });
  });

  group('resumen, calendario y listas', () {
    final data = AppData(
      services: const [Service(id: 's1', name: 'Luz', category: 'Luz')],
      bills: [
        bill('paid', '2026-11-05', 9000, paid: true),
        bill('pending', '2026-11-20', 1000),
        bill('other', '2026-10-05', 5000),
        bill('paid-other-month', '2026-10-10', 5000, paid: true),
      ],
      demo: false,
    );

    test('T-M01 y T-M03 calculan totales y avance por monto', () {
      final summary = summarizeMonth(data, DateTime.utc(2026, 11));
      expect(summary.totalCents, 10000);
      expect(summary.paidCents, 9000);
      expect(summary.pendingCents, 1000);
      expect(summary.progress, 90);
      expect(summary.paidCount, 1);
      expect(summary.pendingCount, 1);
    });

    test('T-M02 un mes vacío produce totales y avance cero', () {
      final summary = summarizeMonth(data, DateTime.utc(2026, 12));
      expect(summary.totalCents, 0);
      expect(summary.progress, 0);
    });

    test('T-C01 calcula febrero bisiesto y un mes de seis filas', () {
      final leap = calendarMonth(DateTime.utc(2024, 2));
      expect(leap.days, 29);
      expect(leap.leadingEmpty, 3);
      expect(leap.rows, 5);
      final sixRows = calendarMonth(DateTime.utc(2026, 8));
      expect(sixRows.days, 31);
      expect(sixRows.rows, 6);
      final yearChange = calendarMonth(DateTime.utc(2027, 1));
      expect(yearChange.days, 31);
    });

    test('T-D01 y T-D05 separan vencidos pagados y pendientes', () {
      final today = DateTime.utc(2026, 11, 12);
      final overdue = overdueBills(data, today);
      expect(overdue.map((item) => item.id), ['other']);
      expect(billStatus(data.bills.first, today).kind, BillStatusKind.paid);
    });

    test('historial y día se ordenan y filtran', () {
      final serviceBills = billsForService(data, 's1');
      expect(serviceBills.first.dueDate, '2026-11-20');
      expect(serviceBills.length, 4);
      final day = billsForDay(data, DateTime.utc(2026, 11, 5));
      expect(day.single.id, 'paid');
      final upcoming = upcomingBills(
        data,
        DateTime.utc(2026, 11),
        DateTime.utc(2026, 11, 12),
      );
      expect(upcoming.single.id, 'pending');
    });
  });
}
