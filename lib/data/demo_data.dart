import '../models/app_data.dart';

/// Datos completamente ficticios para las vistas de diseño y para la carga
/// explícita de ejemplos en la aplicación funcional.
AppData demoAppData(DateTime today) {
  final month = DateTime.utc(today.year, today.month);
  final m1 = DateTime.utc(month.year, month.month - 1);
  final m2 = DateTime.utc(month.year, month.month - 2);
  final m3 = DateTime.utc(month.year, month.month - 3);
  final m4 = DateTime.utc(month.year, month.month - 4);
  final daysInMonth = DateTime.utc(month.year, month.month + 1, 0).day;
  int clamped(int day) => day.clamp(1, daysInMonth);

  final services = <Service>[
    const Service(id: 'demo-luz', name: 'Luz del hogar', category: 'Luz'),
    const Service(id: 'demo-agua', name: 'Agua', category: 'Agua'),
    const Service(id: 'demo-internet', name: 'Internet', category: 'Internet'),
    const Service(id: 'demo-telefono', name: 'Teléfono', category: 'Teléfono'),
  ];

  Bill bill(
    String service,
    DateTime month,
    int day,
    int amount, {
    bool paid = true,
  }) {
    final due = DateTime.utc(month.year, month.month, day);
    final created = due.subtract(const Duration(days: 18));
    final paidAt = paid ? due.subtract(const Duration(days: 1)) : null;
    return Bill(
      id: 'demo-$service-${month.year}-${month.month.toString().padLeft(2, '0')}',
      serviceId: 'demo-$service',
      amount: amount,
      dueDate: _iso(due),
      paid: paid,
      paidAt: paidAt == null ? null : _iso(paidAt),
      createdAt: '${_iso(created)}T15:30:00.000Z',
    );
  }

  final bills = <Bill>[
    bill('luz', m4, 18, 6300),
    bill('luz', m3, 18, 6100),
    bill('luz', m2, 18, 6800),
    bill('luz', m1, 18, 6600),
    bill('luz', month, clamped(today.day + 2), 9200, paid: false),

    bill('agua', m3, 5, 4000),
    bill('agua', m2, 5, 4200),
    bill('agua', m1, 5, 4100, paid: false),
    bill('agua', month, clamped(today.day - 5), 4210),

    bill('internet', m3, 25, 8900),
    bill('internet', m2, 25, 8900),
    bill('internet', m1, 25, 8900, paid: false),
    bill('internet', month, clamped(today.day + 14), 8990, paid: false),

    bill('telefono', m2, 12, 3500),
    bill('telefono', m1, 12, 3600),
    bill('telefono', month, today.day, 3700, paid: false),
  ];

  return AppData(services: services, bills: bills, demo: true);
}

String _iso(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
