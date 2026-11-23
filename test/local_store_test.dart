import 'dart:convert';
import 'dart:io';

import 'package:aldia_flutter/data/local_store.dart';
import 'package:aldia_flutter/models/app_data.dart';
import 'package:flutter_test/flutter_test.dart';

AppData sampleData({int amount = 8640, bool demo = false}) => AppData(
  services: const [Service(id: 's1', name: 'Luz del hogar', category: 'Luz')],
  bills: [
    Bill(
      id: 'b1',
      serviceId: 's1',
      amount: amount,
      dueDate: '2026-11-15',
      paid: false,
      paidAt: null,
      createdAt: '2026-11-01T12:00:00.000Z',
    ),
  ],
  demo: demo,
);

void main() {
  late Directory root;
  late LocalStore store;
  late File mainFile;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('aldia_store_test_');
    store = LocalStore(documentsDirectory: () async => root);
    mainFile = File(
      '${root.path}${Platform.pathSeparator}${LocalStore.folderName}'
      '${Platform.pathSeparator}${LocalStore.fileName}',
    );
  });

  tearDown(() async {
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('T-F01 un archivo inexistente produce estado vacío', () async {
    final data = await store.load();
    expect(data.services, isEmpty);
    expect(data.bills, isEmpty);
    expect(data.demo, isFalse);
  });

  test('T-F02 guarda, crea otra instancia y recupera el contenido', () async {
    await store.save(sampleData(demo: true));
    expect(await mainFile.exists(), isTrue);
    final reread = await LocalStore(
      documentsDirectory: () async => root,
    ).load();
    expect(reread.demo, isTrue);
    expect(reread.services.single.name, 'Luz del hogar');
    expect(reread.bills.single.amount, 8640);
    final temporary = File('${mainFile.path}.tmp');
    expect(await temporary.exists(), isFalse);
  });

  test('T-F03 conserva un JSON corrupto y lo informa', () async {
    await mainFile.parent.create(recursive: true);
    await mainFile.writeAsString('{ esto no es JSON');
    await expectLater(
      store.load(),
      throwsA(
        isA<StorageException>().having(
          (error) => error.message,
          'message',
          contains('dañado'),
        ),
      ),
    );
    expect(await mainFile.readAsString(), '{ esto no es JSON');
  });

  test('T-F03 una versión desconocida no se convierte en Vacío', () async {
    await mainFile.parent.create(recursive: true);
    final content = jsonEncode({
      'version': 2,
      'demo': false,
      'services': <Object?>[],
      'bills': <Object?>[],
    });
    await mainFile.writeAsString(content);
    await expectLater(
      store.load(),
      throwsA(
        isA<StorageException>().having(
          (error) => error.message,
          'message',
          contains('versión'),
        ),
      ),
    );
    expect(await mainFile.readAsString(), content);
  });

  test('T-F04 rechaza relaciones y duplicados del documento', () async {
    await mainFile.parent.create(recursive: true);
    await mainFile.writeAsString(
      jsonEncode({
        'version': 1,
        'demo': false,
        'services': [
          {'id': 's1', 'name': 'Luz', 'category': 'Luz'},
        ],
        'bills': [
          {
            'id': 'b1',
            'service_id': 'missing',
            'amount': 1000,
            'due_date': '2026-11-15',
            'paid': false,
            'paid_at': null,
            'created_at': '2026-11-01T12:00:00.000Z',
          },
        ],
      }),
    );
    await expectLater(store.load(), throwsA(isA<StorageException>()));
  });

  test('T-F05 una escritura fallida conserva el archivo anterior', () async {
    await store.save(sampleData());
    final temporary = Directory('${mainFile.path}.tmp');
    await temporary.create(recursive: true);
    await expectLater(
      store.save(sampleData(amount: 9999)),
      throwsA(isA<StorageException>()),
    );
    final reread = await store.load();
    expect(reread.bills.single.amount, 8640);
  });

  test('T-F07 el reinicio conserva una copia antes de borrar', () async {
    await mainFile.parent.create(recursive: true);
    const corrupt = '{ roto';
    await mainFile.writeAsString(corrupt);
    final backupPath = await store.resetAfterError();
    expect(backupPath, isNotNull);
    expect(await mainFile.exists(), isFalse);
    final backup = File(backupPath!);
    expect(await backup.exists(), isTrue);
    expect(await backup.readAsString(), corrupt);
    expect((await store.load()).services, isEmpty);
  });

  test('el reinicio sin archivo no exige copia', () async {
    expect(await store.resetAfterError(), isNull);
    expect((await store.load()).services, isEmpty);
  });

  test('el límite de 5 MB se comprueba antes de decodificar', () async {
    await mainFile.parent.create(recursive: true);
    await mainFile.writeAsString('a' * (LocalStore.maxFileBytes + 16));
    await expectLater(
      store.load(),
      throwsA(
        isA<StorageException>().having(
          (error) => error.message,
          'message',
          contains('5 MB'),
        ),
      ),
    );
  });

  test('save valida el documento antes de tocar el disco', () async {
    final invalid = AppData(
      services: const [
        Service(id: 's1', name: 'Luz', category: 'Luz'),
        Service(id: 's1', name: 'Agua', category: 'Agua'),
      ],
      bills: const [],
      demo: false,
    );
    await expectLater(store.save(invalid), throwsA(isA<FormatException>()));
    expect(await mainFile.exists(), isFalse);
  });
}
