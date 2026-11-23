import 'package:aldia_flutter/app.dart';
import 'package:aldia_flutter/data/local_store.dart';
import 'package:aldia_flutter/screens/service_detail_screen.dart';
import 'package:aldia_flutter/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Recorrido de demostración con pausas para capturar la interfaz.
/// No forma parte de la batería automática; usa el almacenamiento local real
/// y carga ejemplos solo cuando el archivo está vacío.
void main() {
  final binding = IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  binding.framePolicy = LiveTestWidgetsFlutterBindingFramePolicy.fadePointers;

  Future<void> pause(WidgetTester tester, int seconds) async {
    await tester.pumpAndSettle();
    await Future<void>.delayed(Duration(seconds: seconds));
    await tester.pumpAndSettle();
  }

  testWidgets('recorrido de demostración', (tester) async {
    final store = LocalStore();
    final controller = AppController(store: store);
    await controller.load();
    if (!controller.hasData) {
      await controller.loadDemo();
    }
    await tester.pumpWidget(AlDiaApp(controller: controller));
    await pause(tester, 6);

    await tester.tap(find.text('Servicios').last);
    await pause(tester, 6);

    await tester.tap(find.text('Luz del hogar'));
    await pause(tester, 8);

    await tester.tap(find.text('Recibo de oct 2026'));
    await pause(tester, 5);

    await tester.tap(find.byType(BackButton));
    await pause(tester, 2);

    await tester.tap(find.text('Calendario').last);
    await pause(tester, 6);

    await tester.tap(find.text('3'));
    await pause(tester, 6);

    await tester.tap(find.text('Registrar recibo').first);
    await pause(tester, 6);

    await tester.tap(find.byType(BackButton));
    await pause(tester, 2);

    await tester.tap(find.text('Resumen').last);
    await pause(tester, 5);

    await tester.tap(find.text('Servicios').last);
    await pause(tester, 2);
    await tester.tap(find.text('Luz del hogar'));
    await pause(tester, 3);

    final unpaid = controller.data.bills
        .where((bill) => bill.id.startsWith('demo-luz-'))
        .where((bill) => !bill.paid)
        .toList();
    if (unpaid.isNotEmpty) {
      await tester.tap(find.byTooltip('Acciones del recibo').first);
      await pause(tester, 2);
      await tester.tap(find.text('Marcar como pagado'));
      await pause(tester, 6);
    }
    expect(find.byType(ServiceDetailScreen), findsOneWidget);
    await tester.tap(find.byType(BackButton));
    await pause(tester, 2);
    await tester.tap(find.text('Resumen').last);
    await pause(tester, 8);

    expect(controller.data.services, isNotEmpty);
    expect(controller.data.bills.any((bill) => bill.paid), isTrue);
  });
}
