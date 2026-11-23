import 'package:aldia_flutter/app.dart';
import 'package:aldia_flutter/data/local_store.dart';
import 'package:aldia_flutter/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Recorrido real desde una instalación vacía. Se usa para el video de uso
/// cuando el almacenamiento local ya fue limpiado de forma explícita.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fadePointers;

  Future<void> pause(WidgetTester tester, int seconds) async {
    await tester.pumpAndSettle();
    await Future<void>.delayed(Duration(seconds: seconds));
    await tester.pumpAndSettle();
  }

  testWidgets('video: alta de servicio, recibo y pago', (tester) async {
    final controller = AppController(store: LocalStore());
    await controller.load();
    expect(controller.hasData, isFalse);
    await tester.pumpWidget(AlDiaApp(controller: controller));
    await pause(tester, 5);

    await tester.tap(find.text('Agregar servicio').first);
    await pause(tester, 3);
    await tester.enterText(find.byType(TextFormField).first, 'Luz de prueba');
    await pause(tester, 2);
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(FilledButton, 'Agregar servicio'),
      ),
    );
    await pause(tester, 4);

    await tester.tap(find.text('Registrar recibo').first);
    await pause(tester, 3);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'Monto del recibo (S/)'),
      '86.40',
    );
    await pause(tester, 2);
    await tester.tapAt(const Offset(20, 500));
    await pause(tester, 2);
    await tester.tap(find.widgetWithText(TextFormField, 'Vencimiento'));
    await pause(tester, 2);
    await tester.tap(find.text('Aceptar'));
    await pause(tester, 2);
    await tester.ensureVisible(
      find.widgetWithText(FilledButton, 'Guardar recibo'),
    );
    await tester.tap(find.widgetWithText(FilledButton, 'Guardar recibo'));
    await pause(tester, 6);
    expect(controller.data.bills.single.amount, 8640);

    await tester.tap(find.text('Servicios').last);
    await pause(tester, 3);
    await tester.tap(find.text('Luz de prueba'));
    await pause(tester, 5);
    await tester.tap(find.byTooltip('Acciones del recibo'));
    await pause(tester, 2);
    await tester.tap(find.text('Marcar como pagado'));
    await pause(tester, 5);
    expect(controller.data.bills.single.paid, isTrue);
    await tester.tap(find.byType(BackButton));
    await pause(tester, 2);

    await tester.tap(find.text('Resumen').last);
    await pause(tester, 5);
    expect(find.text('S/ 86.40'), findsWidgets);

    await tester.tap(find.text('Calendario').last);
    await pause(tester, 4);
    final day = '${DateTime.now().day}';
    await tester.tap(find.text(day).first);
    await pause(tester, 6);

    expect(controller.data.services.single.name, 'Luz de prueba');
    expect(controller.data.bills.single.paid, isTrue);
  });
}
