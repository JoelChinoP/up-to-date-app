import 'dart:convert';

import 'package:aldia_flutter/models/app_data.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> baseJson() => {
  'version': 1,
  'demo': false,
  'services': [
    {'id': 's1', 'name': 'Luz del hogar', 'category': 'Luz'},
  ],
  'bills': [
    {
      'id': 'b1',
      'service_id': 's1',
      'amount': 8640,
      'due_date': '2026-11-15',
      'paid': false,
      'paid_at': null,
      'created_at': '2026-11-01T12:00:00.000Z',
    },
  ],
};

Map<String, dynamic> copyOf(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;

void main() {
  group('documento de datos', () {
    test('reconstruye solo campos reconocidos y conserva demo', () {
      final json = baseJson();
      json['demo'] = true;
      (json['services'] as List).first['ignored'] = 'x';
      final data = AppData.fromJson(json);
      expect(data.demo, isTrue);
      expect(data.services.single.name, 'Luz del hogar');
      expect(data.bills.single.amount, 8640);
      expect(data.toJson()['version'], 1);
      expect(
        (data.toJson()['services'] as List).first,
        isNot(contains('ignored')),
      );
      final reloaded = AppData.fromJson(data.toJson());
      expect(reloaded.services.single.id, 's1');
      expect(reloaded.bills.single.paid, isFalse);
    });

    test('rechaza versiones desconocidas en lugar de vaciar la lista', () {
      final json = baseJson()..['version'] = 2;
      expect(
        () => AppData.fromJson(json),
        throwsA(
          isA<FormatException>().having(
            (error) => error.message,
            'message',
            contains('versión'),
          ),
        ),
      );
    });

    test('rechaza servicios duplicados, categorías y nombres inválidos', () {
      final duplicate = copyOf(baseJson());
      (duplicate['services'] as List).add({
        'id': 's2',
        'name': 'luz del hogar',
        'category': 'Agua',
      });
      expect(() => AppData.fromJson(duplicate), throwsFormatException);

      final category = copyOf(baseJson());
      (category['services'] as List).first['category'] = 'Bancos';
      expect(() => AppData.fromJson(category), throwsFormatException);

      final longName = copyOf(baseJson());
      (longName['services'] as List).first['name'] = 'x' * 51;
      expect(() => AppData.fromJson(longName), throwsFormatException);

      final spaces = copyOf(baseJson());
      (spaces['services'] as List).first['name'] = ' Luz ';
      expect(() => AppData.fromJson(spaces), throwsFormatException);

      final repeatedId = copyOf(baseJson());
      (repeatedId['services'] as List).add({
        'id': 's1',
        'name': 'Agua',
        'category': 'Agua',
      });
      expect(() => AppData.fromJson(repeatedId), throwsFormatException);
    });

    test('rechaza recibos inválidos, huérfanos y meses duplicados', () {
      final orphan = copyOf(baseJson());
      (orphan['bills'] as List).first['service_id'] = 'missing';
      expect(() => AppData.fromJson(orphan), throwsFormatException);

      final duplicateMonth = copyOf(baseJson());
      (duplicateMonth['bills'] as List).add({
        ...((duplicateMonth['bills'] as List).first as Map<String, dynamic>),
        'id': 'b2',
        'due_date': '2026-11-28',
      });
      expect(() => AppData.fromJson(duplicateMonth), throwsFormatException);

      final zero = copyOf(baseJson());
      (zero['bills'] as List).first['amount'] = 0;
      expect(() => AppData.fromJson(zero), throwsFormatException);

      final textAmount = copyOf(baseJson());
      (textAmount['bills'] as List).first['amount'] = '8640';
      expect(() => AppData.fromJson(textAmount), throwsFormatException);

      final invalidDate = copyOf(baseJson());
      (invalidDate['bills'] as List).first['due_date'] = '2026-02-30';
      expect(() => AppData.fromJson(invalidDate), throwsFormatException);
    });

    test('valida la coherencia entre pago y fecha de pago', () {
      final paidWithoutDate = copyOf(baseJson());
      (paidWithoutDate['bills'] as List).first['paid'] = true;
      expect(() => AppData.fromJson(paidWithoutDate), throwsFormatException);

      final pendingWithDate = copyOf(baseJson());
      (pendingWithDate['bills'] as List).first['paid_at'] = '2026-11-10';
      expect(() => AppData.fromJson(pendingWithDate), throwsFormatException);

      final validPaid = copyOf(baseJson());
      (validPaid['bills'] as List).first['paid'] = true;
      (validPaid['bills'] as List).first['paid_at'] = '2026-11-10';
      expect(AppData.fromJson(validPaid).bills.single.paid, isTrue);
    });

    test('exige created_at UTC válido y demo booleano', () {
      final localTime = copyOf(baseJson());
      (localTime['bills'] as List).first['created_at'] = '2026-11-01T12:00:00';
      expect(() => AppData.fromJson(localTime), throwsFormatException);

      final badDemo = copyOf(baseJson())..['demo'] = 'no';
      expect(() => AppData.fromJson(badDemo), throwsFormatException);

      final badCollections = copyOf(baseJson())..['services'] = {};
      expect(() => AppData.fromJson(badCollections), throwsFormatException);
    });

    test('acepta un documento vacío y conserva el estado demo', () {
      final data = AppData.fromJson({
        'version': 1,
        'demo': false,
        'services': <Object?>[],
        'bills': <Object?>[],
      });
      expect(data.services, isEmpty);
      expect(data.bills, isEmpty);
      expect(data.demo, isFalse);
    });
  });

  group('identificadores y copias', () {
    test('genera identificadores únicos con prefijo', () {
      final ids = {for (var index = 0; index < 200; index++) newId('service')};
      expect(ids.length, 200);
      expect(ids.every((id) => id.startsWith('service-')), isTrue);
    });

    test('copyWith conserva identidad y permite limpiar paidAt', () {
      final original = Bill(
        id: 'b1',
        serviceId: 's1',
        amount: 1000,
        dueDate: '2026-11-15',
        paid: true,
        paidAt: '2026-11-10',
        createdAt: '2026-11-01T12:00:00.000Z',
      );
      final pending = original.copyWith(paid: false, paidAt: null);
      expect(pending.id, 'b1');
      expect(pending.paidAt, isNull);
      expect(original.paidAt, '2026-11-10');
      final changed = original.copyWith(amount: 2000);
      expect(changed.amount, 2000);
      expect(changed.paid, isTrue);
    });
  });
}
