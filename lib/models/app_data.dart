import 'dart:math';

const int schemaVersion = 1;
const int maxServices = 500;
const int maxBills = 10000;

const List<String> serviceCategories = [
  'Luz',
  'Agua',
  'Internet',
  'Teléfono',
  'Streaming',
  'Alquiler',
  'Otros',
];

/// Identificador único sin dependencias externas.
///
/// Combina el instante en microsegundos con un valor aleatorio seguro. El
/// controlador comprueba colisiones antes de guardar.
String newId(String prefix) {
  final time = DateTime.now().toUtc().microsecondsSinceEpoch.toRadixString(36);
  final random = Random.secure().nextInt(0x7fffffff).toRadixString(36);
  return '$prefix-$time-$random';
}

class Service {
  const Service({required this.id, required this.name, required this.category});

  final String id;
  final String name;
  final String category;

  Service copyWith({String? name, String? category}) => Service(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'name': name,
    'category': category,
  };

  factory Service.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'El documento contiene un servicio inválido.',
      );
    }
    final id = value['id'];
    final name = value['name'];
    final category = value['category'];
    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
        'El documento contiene servicios sin identificador.',
      );
    }
    if (name is! String ||
        name.trim().isEmpty ||
        name.trim().length > 50 ||
        name != name.trim()) {
      throw const FormatException(
        'El documento contiene un nombre de servicio inválido.',
      );
    }
    if (category is! String || !serviceCategories.contains(category)) {
      throw const FormatException(
        'El documento contiene una categoría desconocida.',
      );
    }
    return Service(id: id, name: name, category: category);
  }

  @override
  bool operator ==(Object other) =>
      other is Service &&
      other.id == id &&
      other.name == name &&
      other.category == category;

  @override
  int get hashCode => Object.hash(id, name, category);
}

class Bill {
  const Bill({
    required this.id,
    required this.serviceId,
    required this.amount,
    required this.dueDate,
    required this.paid,
    required this.paidAt,
    required this.createdAt,
  });

  final String id;
  final String serviceId;

  /// Monto en céntimos.
  final int amount;

  /// Fecha civil `YYYY-MM-DD`.
  final String dueDate;
  final bool paid;

  /// Fecha civil de pago, o null si el recibo sigue pendiente.
  final String? paidAt;

  /// Instante UTC de creación en ISO 8601.
  final String createdAt;

  Bill copyWith({
    String? serviceId,
    int? amount,
    String? dueDate,
    bool? paid,
    Object? paidAt = _unset,
    String? createdAt,
  }) => Bill(
    id: id,
    serviceId: serviceId ?? this.serviceId,
    amount: amount ?? this.amount,
    dueDate: dueDate ?? this.dueDate,
    paid: paid ?? this.paid,
    paidAt: identical(paidAt, _unset) ? this.paidAt : paidAt as String?,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, Object?> toJson() => {
    'id': id,
    'service_id': serviceId,
    'amount': amount,
    'due_date': dueDate,
    'paid': paid,
    'paid_at': paidAt,
    'created_at': createdAt,
  };

  factory Bill.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException('El documento contiene un recibo inválido.');
    }
    final id = value['id'];
    final serviceId = value['service_id'];
    final amount = value['amount'];
    final dueDate = value['due_date'];
    final paid = value['paid'];
    final paidAt = value['paid_at'];
    final createdAt = value['created_at'];

    if (id is! String || id.trim().isEmpty) {
      throw const FormatException(
        'El documento contiene recibos sin identificador.',
      );
    }
    if (serviceId is! String || serviceId.trim().isEmpty) {
      throw const FormatException(
        'El documento contiene un recibo sin servicio.',
      );
    }
    if (amount is! int || amount < 1 || amount > 100000000) {
      throw const FormatException(
        'El documento contiene un monto fuera del rango permitido.',
      );
    }
    if (dueDate is! String || !_validDate(dueDate)) {
      throw const FormatException(
        'El documento contiene un vencimiento inválido.',
      );
    }
    if (paid is! bool) {
      throw const FormatException(
        'El documento contiene un estado de pago inválido.',
      );
    }
    if (paid) {
      if (paidAt is! String || !_validDate(paidAt)) {
        throw const FormatException(
          'El documento contiene un recibo pagado sin fecha válida.',
        );
      }
    } else if (paidAt != null) {
      throw const FormatException(
        'El documento contiene un recibo pendiente con fecha de pago.',
      );
    }
    if (createdAt is! String) {
      throw const FormatException(
        'El documento contiene una fecha de creación inválida.',
      );
    }
    final created = DateTime.tryParse(createdAt);
    if (created == null || !created.isUtc) {
      throw const FormatException(
        'El documento contiene una fecha de creación inválida.',
      );
    }

    return Bill(
      id: id,
      serviceId: serviceId,
      amount: amount,
      dueDate: dueDate,
      paid: paid,
      paidAt: paidAt as String?,
      createdAt: createdAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is Bill &&
      other.id == id &&
      other.serviceId == serviceId &&
      other.amount == amount &&
      other.dueDate == dueDate &&
      other.paid == paid &&
      other.paidAt == paidAt &&
      other.createdAt == createdAt;

  @override
  int get hashCode =>
      Object.hash(id, serviceId, amount, dueDate, paid, paidAt, createdAt);
}

const Object _unset = Object();

bool _validDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return false;
  final year = int.parse(value.substring(0, 4));
  final month = int.parse(value.substring(5, 7));
  final day = int.parse(value.substring(8, 10));
  if (year < 2000 || year > 2100 || month < 1 || month > 12 || day < 1) {
    return false;
  }
  final date = DateTime.utc(year, month, day);
  return date.year == year && date.month == month && date.day == day;
}

class AppData {
  const AppData({
    required this.services,
    required this.bills,
    required this.demo,
  });

  final List<Service> services;
  final List<Bill> bills;
  final bool demo;

  static const AppData empty = AppData(services: [], bills: [], demo: false);

  int get version => schemaVersion;

  Service? serviceById(String id) {
    for (final service in services) {
      if (service.id == id) return service;
    }
    return null;
  }

  Map<String, Object?> toJson() => {
    'version': schemaVersion,
    'demo': demo,
    'services': services.map((service) => service.toJson()).toList(),
    'bills': bills.map((bill) => bill.toJson()).toList(),
  };

  /// Valida el documento completo y construye el modelo solo con campos
  /// reconocidos. Una versión desconocida no se convierte en lista vacía.
  factory AppData.fromJson(Object? value) {
    if (value is! Map<String, dynamic>) {
      throw const FormatException(
        'El archivo no tiene el formato de datos de AlDía.',
      );
    }
    if (value['version'] != schemaVersion) {
      throw const FormatException(
        'La versión del archivo no es compatible con esta aplicación.',
      );
    }
    final demo = value['demo'];
    final rawServices = value['services'];
    final rawBills = value['bills'];
    if (demo is! bool ||
        rawServices is! List ||
        rawBills is! List ||
        rawServices.length > maxServices ||
        rawBills.length > maxBills) {
      throw const FormatException(
        'El archivo no tiene el formato de datos de AlDía.',
      );
    }

    final services = <Service>[];
    final ids = <String>{};
    final names = <String>{};
    for (final raw in rawServices) {
      final service = Service.fromJson(raw);
      final normalizedName = service.name.toLowerCase();
      if (ids.contains(service.id) || names.contains(normalizedName)) {
        throw const FormatException(
          'El documento contiene servicios duplicados.',
        );
      }
      ids.add(service.id);
      names.add(normalizedName);
      services.add(service);
    }

    final bills = <Bill>[];
    final billIds = <String>{};
    final months = <String>{};
    for (final raw in rawBills) {
      final bill = Bill.fromJson(raw);
      final month = '${bill.serviceId}:${bill.dueDate.substring(0, 7)}';
      if (!ids.contains(bill.serviceId) ||
          billIds.contains(bill.id) ||
          months.contains(month)) {
        throw const FormatException(
          'El documento contiene recibos inválidos o duplicados.',
        );
      }
      billIds.add(bill.id);
      months.add(month);
      bills.add(bill);
    }

    return AppData(services: services, bills: bills, demo: demo);
  }
}
