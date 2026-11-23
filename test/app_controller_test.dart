import 'dart:io';

import 'package:aldia_flutter/data/local_store.dart';
import 'package:aldia_flutter/state/app_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory root;
  late LocalStore store;
  late AppController controller;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('aldia_controller_test_');
    store = LocalStore(documentsDirectory: () async => root);
    controller = AppController(store: store, today: DateTime.utc(2026, 11, 12));
    await controller.load();
  });

  tearDown(() async {
    controller.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('T-S01 recorta el nombre y persiste el servicio', () async {
    final service = await controller.createService(
      name: '  Luz del hogar  ',
      category: 'Luz',
    );
    expect(service.name, 'Luz del hogar');
    expect(controller.data.services.single.id, service.id);
    final other = AppController(store: store);
    await other.load();
    expect(other.data.services.single.name, 'Luz del hogar');
    other.dispose();
  });

  test(
    'T-S02 y T-S03 rechazan nombres o categorías inválidas y duplicados',
    () async {
      await controller.createService(name: 'Luz', category: 'Luz');
      await expectLater(
        controller.createService(name: '   ', category: 'Luz'),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        controller.createService(name: 'x' * 51, category: 'Luz'),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        controller.createService(name: 'Agua', category: 'Bancos'),
        throwsA(isA<AppException>()),
      );
      await expectLater(
        controller.createService(name: 'luz', category: 'Agua'),
        throwsA(isA<AppException>()),
      );
      expect(controller.data.services.length, 1);
    },
  );

  test(
    'T-S04 editar conserva identidad y eliminar arrastra sus recibos',
    () async {
      final service = await controller.createService(
        name: 'Luz',
        category: 'Luz',
      );
      final bill = await controller.saveBill(
        serviceId: service.id,
        amountText: '86.40',
        dueDate: '2026-11-15',
      );
      final updated = await controller.updateService(
        id: service.id,
        name: 'Luz del hogar',
        category: 'Luz',
      );
      expect(updated.id, service.id);
      expect(controller.data.bills.single.id, bill.id);
      await controller.deleteService(service.id);
      expect(controller.data.services, isEmpty);
      expect(controller.data.bills, isEmpty);
      await expectLater(
        controller.deleteService(service.id),
        throwsA(isA<AppException>()),
      );
    },
  );

  test('T-B01 a T-B06 validan montos, fechas, servicio y duplicados', () async {
    final service = await controller.createService(
      name: 'Luz',
      category: 'Luz',
    );
    final bill = await controller.saveBill(
      serviceId: service.id,
      amountText: '86,40',
      dueDate: '2026-11-15',
    );
    expect(bill.amount, 8640);
    expect(bill.paid, isFalse);
    expect(bill.paidAt, isNull);
    expect(DateTime.parse(bill.createdAt).isUtc, isTrue);

    await expectLater(
      controller.saveBill(
        serviceId: service.id,
        amountText: '0',
        dueDate: '2026-12-15',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      controller.saveBill(
        serviceId: 'missing',
        amountText: '10.00',
        dueDate: '2026-12-15',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      controller.saveBill(
        serviceId: service.id,
        amountText: '10.00',
        dueDate: '2026-02-30',
      ),
      throwsA(isA<AppException>()),
    );
    await expectLater(
      controller.saveBill(
        serviceId: service.id,
        amountText: '99.00',
        dueDate: '2026-11-28',
      ),
      throwsA(
        isA<AppException>().having(
          (error) => error.message,
          'message',
          contains('ya tiene un recibo'),
        ),
      ),
    );

    final other = await controller.createService(
      name: 'Agua',
      category: 'Agua',
    );
    final second = await controller.saveBill(
      serviceId: other.id,
      amountText: '40.00',
      dueDate: '2026-11-20',
    );
    expect(second.serviceId, other.id);
    expect(controller.data.bills.length, 2);
  });

  test('T-B06 y T-P03 editar no duplica ni pierde pago ni creación', () async {
    final service = await controller.createService(
      name: 'Luz',
      category: 'Luz',
    );
    final bill = await controller.saveBill(
      serviceId: service.id,
      amountText: '86.40',
      dueDate: '2026-11-15',
    );
    final paid = await controller.setBillPaid(bill.id, true);
    final edited = await controller.saveBill(
      id: bill.id,
      serviceId: service.id,
      amountText: '90.00',
      dueDate: '2026-11-16',
    );
    expect(edited.id, bill.id);
    expect(edited.amount, 9000);
    expect(edited.paid, isTrue);
    expect(edited.paidAt, paid.paidAt);
    expect(edited.createdAt, bill.createdAt);
    expect(controller.data.bills.length, 1);
    await expectLater(
      controller.saveBill(
        id: 'missing',
        serviceId: service.id,
        amountText: '10.00',
        dueDate: '2026-12-15',
      ),
      throwsA(isA<AppException>()),
    );
  });

  test('T-P01 y T-P02 cambian solo el estado y la fecha de pago', () async {
    final service = await controller.createService(
      name: 'Luz',
      category: 'Luz',
    );
    final bill = await controller.saveBill(
      serviceId: service.id,
      amountText: '86.40',
      dueDate: '2026-11-15',
    );
    final paid = await controller.setBillPaid(bill.id, true);
    expect(paid.paid, isTrue);
    expect(paid.paidAt, '2026-11-12');
    expect(paid.createdAt, bill.createdAt);
    final pending = await controller.setBillPaid(bill.id, false);
    expect(pending.paid, isFalse);
    expect(pending.paidAt, isNull);
    expect(pending.createdAt, bill.createdAt);
  });

  test('T-F02 la información sobrevive a una nueva instancia', () async {
    final service = await controller.createService(
      name: 'Internet',
      category: 'Internet',
    );
    await controller.saveBill(
      serviceId: service.id,
      amountText: '89.90',
      dueDate: '2026-11-25',
    );
    final reopened = AppController(store: store);
    await reopened.load();
    expect(reopened.status, AppStatus.ready);
    expect(reopened.data.services.single.name, 'Internet');
    expect(reopened.data.bills.single.amount, 8990);
    reopened.dispose();
  });

  test(
    'T-F03 y T-F07 un archivo inválido bloquea y exige confirmación',
    () async {
      controller.dispose();
      final file = File(
        '${root.path}${Platform.pathSeparator}${LocalStore.folderName}'
        '${Platform.pathSeparator}${LocalStore.fileName}',
      );
      await file.parent.create(recursive: true);
      await file.writeAsString('{ roto');
      controller = AppController(
        store: store,
        today: DateTime.utc(2026, 11, 12),
      );
      await controller.load();
      expect(controller.status, AppStatus.error);
      expect(controller.errorMessage, contains('dañado'));
      await expectLater(
        controller.createService(name: 'Luz', category: 'Luz'),
        throwsA(isA<AppException>()),
      );
      final backup = await controller.resetAfterError();
      expect(backup, isNotNull);
      expect(controller.status, AppStatus.ready);
      expect(controller.data.services, isEmpty);
      await controller.createService(name: 'Luz', category: 'Luz');
      expect(controller.data.services.length, 1);
    },
  );

  test(
    'T-F06 las mutaciones simultáneas se serializan sin perder cambios',
    () async {
      final results = await Future.wait([
        controller.createService(name: 'Luz', category: 'Luz'),
        controller.createService(name: 'Agua', category: 'Agua'),
      ]);
      expect(results.length, 2);
      expect(controller.data.services.length, 2);
      final reread = AppController(store: store);
      await reread.load();
      expect(reread.data.services.length, 2);
      reread.dispose();

      final service = controller.data.services.first;
      final bill = await controller.saveBill(
        serviceId: service.id,
        amountText: '10.00',
        dueDate: '2026-12-15',
      );
      await Future.wait([
        controller.setBillPaid(bill.id, true),
        controller.setBillPaid(bill.id, false),
      ]);
      expect(controller.data.bills.single.paid, isFalse);
      expect(controller.data.bills.single.paidAt, isNull);
    },
  );

  test('los datos de ejemplo solo se cargan en un estado vacío', () async {
    await controller.loadDemo();
    expect(controller.data.demo, isTrue);
    expect(controller.data.services.length, 4);
    expect(controller.data.bills, isNotEmpty);
    await expectLater(controller.loadDemo(), throwsA(isA<AppException>()));
    await controller.clearDemo();
    expect(controller.data.demo, isFalse);
    expect(controller.data.services, isEmpty);
  });

  test('eliminar un recibo actualiza el estado persistido', () async {
    final service = await controller.createService(
      name: 'Luz',
      category: 'Luz',
    );
    final bill = await controller.saveBill(
      serviceId: service.id,
      amountText: '10.00',
      dueDate: '2026-11-15',
    );
    await controller.deleteBill(bill.id);
    expect(controller.data.bills, isEmpty);
    await expectLater(
      controller.deleteBill(bill.id),
      throwsA(isA<AppException>()),
    );
  });
}
