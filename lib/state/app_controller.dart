import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';

import '../data/demo_data.dart';
import '../data/local_store.dart';
import '../logic/bill_rules.dart';
import '../models/app_data.dart';

/// Error de negocio con un mensaje apto para la interfaz.
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}

enum AppStatus { loading, ready, error }

class AppController extends ChangeNotifier {
  AppController({required this.store, DateTime? today})
    : _today = today ?? todayCivil();

  final LocalStore store;

  AppData _data = AppData.empty;
  AppStatus _status = AppStatus.loading;
  String? _errorMessage;
  bool _busy = false;
  DateTime _today;
  Future<void> _tail = Future.value();
  bool _disposed = false;

  AppData get data => _data;
  AppStatus get status => _status;
  String? get errorMessage => _errorMessage;
  bool get busy => _busy;
  DateTime get today => _today;
  bool get hasData => _data.services.isNotEmpty || _data.bills.isNotEmpty;

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  /// Carga el archivo local. Un error deja el estado bloqueado y no borra ni
  /// reemplaza el documento inválido.
  Future<void> load() async {
    _status = AppStatus.loading;
    _errorMessage = null;
    _notify();
    try {
      _data = await store.load();
      _status = AppStatus.ready;
    } on StorageException catch (error) {
      _status = AppStatus.error;
      _errorMessage = error.message;
    } on FileSystemException catch (error) {
      _status = AppStatus.error;
      _errorMessage = 'No se pudo acceder al archivo de datos: $error';
    }
    _notify();
  }

  Future<void> retryLoad() => load();

  /// Reinicio explícito tras un error de carga. Conserva una copia antes de
  /// eliminar el archivo principal.
  Future<String?> resetAfterError() => _enqueue(() async {
    if (_status != AppStatus.error) return null;
    final backup = await store.resetAfterError();
    _data = AppData.empty;
    _status = AppStatus.ready;
    _errorMessage = null;
    return backup;
  });

  /// La fecha de hoy se recalcula al volver a primer plano.
  void refreshToday() {
    final next = todayCivil();
    if (next != _today) {
      _today = next;
      _notify();
    }
  }

  Future<Service> createService({
    required String name,
    required String category,
  }) => _enqueue(() async {
    _ensureReady();
    final cleanName = name.trim();
    _validateService(cleanName, category);
    if (_data.services.any(
      (service) => service.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      throw const AppException('Ya existe un servicio con ese nombre.');
    }
    final id = _uniqueId('service', _data.services.map((item) => item.id));
    final service = Service(id: id, name: cleanName, category: category);
    await _commit(
      AppData(
        services: [..._data.services, service],
        bills: _data.bills,
        demo: _data.demo,
      ),
    );
    return service;
  });

  Future<Service> updateService({
    required String id,
    required String name,
    required String category,
  }) => _enqueue(() async {
    _ensureReady();
    final current = _data.serviceById(id);
    if (current == null) {
      throw const AppException('El servicio ya no existe.');
    }
    final cleanName = name.trim();
    _validateService(cleanName, category);
    if (_data.services.any(
      (service) =>
          service.id != id &&
          service.name.toLowerCase() == cleanName.toLowerCase(),
    )) {
      throw const AppException('Ya existe un servicio con ese nombre.');
    }
    final updated = current.copyWith(name: cleanName, category: category);
    await _commit(
      AppData(
        services: _data.services
            .map((service) => service.id == id ? updated : service)
            .toList(),
        bills: _data.bills,
        demo: _data.demo,
      ),
    );
    return updated;
  });

  Future<void> deleteService(String id) => _enqueue(() async {
    _ensureReady();
    if (_data.serviceById(id) == null) {
      throw const AppException('El servicio ya no existe.');
    }
    await _commit(
      AppData(
        services: _data.services.where((service) => service.id != id).toList(),
        bills: _data.bills.where((bill) => bill.serviceId != id).toList(),
        demo: _data.demo,
      ),
    );
  });

  Future<Bill> saveBill({
    String? id,
    required String serviceId,
    required String amountText,
    required String dueDate,
  }) => _enqueue(() async {
    _ensureReady();
    if (_data.serviceById(serviceId) == null) {
      throw const AppException('Primero registra un servicio.');
    }
    if (!isValidIsoDate(dueDate)) {
      throw const AppException(
        'Selecciona una fecha válida entre 2000 y 2100.',
      );
    }
    final int amount;
    try {
      amount = parseAmountCents(amountText);
    } on FormatException catch (error) {
      throw AppException(error.message);
    }
    final month = dueDate.substring(0, 7);
    if (_data.bills.any(
      (bill) =>
          bill.serviceId == serviceId &&
          bill.id != id &&
          bill.dueDate.substring(0, 7) == month,
    )) {
      throw const AppException(
        'Este servicio ya tiene un recibo en ese mes. Puedes editarlo desde '
        'su detalle.',
      );
    }

    final existing = id == null ? null : _billById(id);
    if (id != null && existing == null) {
      throw const AppException('El recibo que intentas editar ya no existe.');
    }
    final bill = Bill(
      id: existing?.id ?? _uniqueId('bill', _data.bills.map((item) => item.id)),
      serviceId: serviceId,
      amount: amount,
      dueDate: dueDate,
      paid: existing?.paid ?? false,
      paidAt: existing?.paidAt,
      createdAt:
          existing?.createdAt ?? DateTime.now().toUtc().toIso8601String(),
    );
    await _commit(
      AppData(
        services: _data.services,
        bills: existing == null
            ? [..._data.bills, bill]
            : _data.bills
                  .map((item) => item.id == bill.id ? bill : item)
                  .toList(),
        demo: _data.demo,
      ),
    );
    return bill;
  });

  Future<void> deleteBill(String id) => _enqueue(() async {
    _ensureReady();
    if (!_data.bills.any((bill) => bill.id == id)) {
      throw const AppException('El recibo ya no existe.');
    }
    await _commit(
      AppData(
        services: _data.services,
        bills: _data.bills.where((bill) => bill.id != id).toList(),
        demo: _data.demo,
      ),
    );
  });

  Future<Bill> setBillPaid(String id, bool paid) => _enqueue(() async {
    _ensureReady();
    final current = _billById(id);
    if (current == null) {
      throw const AppException('El recibo ya no existe.');
    }
    final updated = current.copyWith(
      paid: paid,
      paidAt: paid ? isoDate(_today) : null,
    );
    await _commit(
      AppData(
        services: _data.services,
        bills: _data.bills
            .map((bill) => bill.id == id ? updated : bill)
            .toList(),
        demo: _data.demo,
      ),
    );
    return updated;
  });

  Future<void> loadDemo() => _enqueue(() async {
    _ensureReady();
    if (hasData) {
      throw const AppException(
        'Los ejemplos solo se cargan cuando no hay datos propios.',
      );
    }
    final examples = demoAppData(_today);
    await _commit(examples);
  });

  Future<void> clearDemo() => _enqueue(() async {
    _ensureReady();
    if (!_data.demo) {
      throw const AppException('Los datos actuales no son de ejemplo.');
    }
    await _commit(AppData.empty);
  });

  Future<String> storagePath() async {
    final file = await store.mainFile();
    return file.path;
  }

  void _ensureReady() {
    if (_status != AppStatus.ready) {
      throw const AppException(
        'Primero resuelve el problema de carga de datos.',
      );
    }
  }

  Bill? _billById(String id) {
    for (final bill in _data.bills) {
      if (bill.id == id) return bill;
    }
    return null;
  }

  void _validateService(String name, String category) {
    if (name.isEmpty || name.length > 50) {
      throw const AppException('El nombre debe tener entre 1 y 50 caracteres.');
    }
    if (!serviceCategories.contains(category)) {
      throw const AppException('Selecciona una categoría válida.');
    }
  }

  String _uniqueId(String prefix, Iterable<String> used) {
    final set = used.toSet();
    var candidate = newId(prefix);
    while (set.contains(candidate)) {
      candidate = newId(prefix);
    }
    return candidate;
  }

  /// Solo notifica el nuevo estado después de que la escritura terminó.
  Future<void> _commit(AppData next) async {
    final validated = AppData.fromJson(next.toJson());
    await store.save(validated);
    _data = validated;
    _notify();
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final completer = Completer<T>();
    _tail = _tail.then((_) async {
      _busy = true;
      _notify();
      try {
        completer.complete(await action());
      } catch (error, stackTrace) {
        completer.completeError(error, stackTrace);
      } finally {
        _busy = false;
        _notify();
      }
    });
    return completer.future;
  }
}
