import 'dart:io';

import 'package:aldia_flutter/app.dart';
import 'package:aldia_flutter/data/local_store.dart';
import 'package:aldia_flutter/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('recorrido servicio, recibo, pago y persistencia', (
    tester,
  ) async {
    final root = await Directory.systemTemp.createTemp('aldia_integration_');
    final store = LocalStore(documentsDirectory: () async => root);
    final controller = AppController(
      store: store,
      today: DateTime.utc(2026, 11, 12),
    );
    await controller.load();
    await tester.pumpWidget(AlDiaApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.text('Empieza por un servicio'), findsOneWidget);

    await tester.tap(find.text('Agregar servicio').first);
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextFormField).first, 'Luz de prueba');
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Agregar servicio'),
      ),
    );
    await tester.pumpAndSettle();
    expect(controller.data.services.single.name, 'Luz de prueba');

    await tester.tap(find.text('Registrar recibo').first);
    await tester.pumpAndSettle();
    expect(find.text('Registrar recibo'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monto del recibo (S/)'),
      '86.40',
    );
    await tester.tap(find.widgetWithText(TextFormField, 'Vencimiento'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aceptar'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Guardar recibo'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar recibo'));
    await tester.pumpAndSettle();
    expect(controller.data.bills.single.amount, 8640);
    expect(find.text('S/ 86.40'), findsWidgets);

    await tester.tap(find.text('Servicios').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Luz de prueba'));
    await tester.pumpAndSettle();
    expect(find.text('1 recibo'), findsWidgets);
    await tester.tap(find.byTooltip('Acciones del recibo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como pagado'));
    await tester.pumpAndSettle();
    expect(controller.data.bills.single.paid, isTrue);
    final paidAt = controller.data.bills.single.paidAt;
    expect(paidAt, isNotNull);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    final reopened = AppController(
      store: store,
      today: DateTime.utc(2026, 11, 12),
    );
    await reopened.load();
    expect(reopened.status, AppStatus.ready);
    expect(reopened.data.services.single.name, 'Luz de prueba');
    expect(reopened.data.bills.single.amount, 8640);
    expect(reopened.data.bills.single.paid, isTrue);
    expect(reopened.data.bills.single.paidAt, paidAt);
    reopened.dispose();
    await root.delete(recursive: true);
  });
}
