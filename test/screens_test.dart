import 'dart:io';

import 'package:aldia_flutter/app.dart';
import 'package:aldia_flutter/app_theme.dart';
import 'package:aldia_flutter/data/demo_data.dart';
import 'package:aldia_flutter/data/local_store.dart';
import 'package:aldia_flutter/models/app_data.dart';
import 'package:aldia_flutter/screens/bill_form_screen.dart';
import 'package:aldia_flutter/screens/calendar_screen.dart';
import 'package:aldia_flutter/screens/service_detail_screen.dart';
import 'package:aldia_flutter/screens/services_screen.dart';
import 'package:aldia_flutter/screens/summary_screen.dart';
import 'package:aldia_flutter/state/app_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

final _today = DateTime.utc(2026, 11, 12);

Widget wrap(Widget child) => MaterialApp(
  theme: buildAppTheme(),
  locale: const Locale('es'),
  supportedLocales: const [Locale('es')],
  localizationsDelegates: GlobalMaterialLocalizations.delegates,
  home: Scaffold(body: child),
);

void setSize(WidgetTester tester, Size size) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
}

void main() {
  final data = demoAppData(_today);

  testWidgets('el resumen muestra pendiente, avance y próximos vencimientos', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      wrap(
        SummaryScreen(
          data: data,
          today: _today,
          onAddService: () {},
          onRegisterBill: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('PENDIENTE ESTE MES'), findsOneWidget);
    expect(find.text('S/ 218.90'), findsOneWidget);
    expect(find.text('Registrar recibo'), findsOneWidget);
    expect(find.text('PRÓXIMOS VENCIMIENTOS'), findsOneWidget);
    expect(find.text('VENCIDOS SIN PAGAR'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el resumen vacío orienta a agregar el primer servicio', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      wrap(
        SummaryScreen(
          data: AppData.empty,
          today: _today,
          onAddService: () {},
          onRegisterBill: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Empieza por un servicio'), findsOneWidget);
    expect(find.text('Agregar servicio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('servicios lista categorías y responde a la selección', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    Service? opened;
    await tester.pumpWidget(
      wrap(
        ServicesScreen(
          data: data,
          onAddService: () {},
          onEditService: (_) {},
          onDeleteService: (_) {},
          onOpenService: (service) => opened = service,
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('4 SERVICIOS'), findsOneWidget);
    expect(find.text('Luz del hogar'), findsOneWidget);
    await tester.tap(find.text('Luz del hogar'));
    expect(opened?.id, 'demo-luz');
    expect(tester.takeException(), isNull);
  });

  testWidgets('servicios vacío explica cómo empezar', (tester) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      wrap(
        ServicesScreen(
          data: AppData.empty,
          onAddService: () {},
          onEditService: (_) {},
          onDeleteService: (_) {},
          onOpenService: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay servicios'), findsOneWidget);
    expect(find.text('Agregar servicio'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el detalle explica comparación e historial', (tester) async {
    setSize(tester, const Size(360, 800));
    final service = data.services.first;
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es')],
        home: ServiceDetailScreen(
          data: data,
          service: service,
          today: _today,
          onRegisterBill: () {},
          onEditService: () {},
          onDeleteService: () {},
          onEditBill: (_) {},
          onDeleteBill: (_) {},
          onTogglePaid: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('COMPARACIÓN DE MONTOS'), findsOneWidget);
    expect(find.text('Aumento inusual'), findsOneWidget);
    expect(find.text('HISTORIAL DE RECIBOS'), findsOneWidget);
    expect(find.text('S/ 92.00'), findsWidgets);
    await tester.ensureVisible(find.text('Recibo de oct 2026'));
    await tester.tap(find.text('Recibo de oct 2026'));
    await tester.pumpAndSettle();
    expect(find.text('Dentro de lo habitual'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el detalle sin recibos orienta a registrar el primero', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    final emptyService = AppData(
      services: data.services,
      bills: const [],
      demo: true,
    );
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es')],
        home: ServiceDetailScreen(
          data: emptyService,
          service: emptyService.services.first,
          today: _today,
          onRegisterBill: () {},
          onEditService: () {},
          onDeleteService: () {},
          onEditBill: (_) {},
          onDeleteBill: (_) {},
          onTogglePaid: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Este servicio todavía no tiene recibos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el formulario de recibo exige servicio, monto y fecha', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('es')],
        home: BillFormScreen(
          data: data,
          today: _today,
          onSave:
              ({
                String? id,
                required String serviceId,
                required String amountText,
                required String dueDate,
              }) async {
                throw const AppException(
                  'No debería guardarse en esta prueba.',
                );
              },
          onAddService: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Registrar recibo'), findsOneWidget);
    await tester.ensureVisible(find.text('Guardar recibo'));
    await tester.tap(find.text('Guardar recibo'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona el servicio del recibo.'), findsOneWidget);
    expect(find.text('Selecciona el vencimiento del recibo.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el formulario sin servicios orienta a crear uno', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      MaterialApp(
        theme: buildAppTheme(),
        home: BillFormScreen(
          data: AppData.empty,
          today: _today,
          onSave:
              ({
                String? id,
                required String serviceId,
                required String amountText,
                required String dueDate,
              }) async {
                throw const AppException('No debería guardarse.');
              },
          onAddService: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Primero agrega un servicio'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el detalle de día del calendario lista los recibos', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      wrap(
        CalendarScreen(
          data: data,
          today: _today,
          onRegisterBill: () {},
          onOpenService: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('lun'), findsOneWidget);
    expect(find.text('dom'), findsOneWidget);
    expect(find.text('Selecciona un día'), findsOneWidget);
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('DÍA SELECCIONADO'), findsOneWidget);
    expect(find.text('jueves 12 de noviembre'), findsOneWidget);
    expect(find.text('Teléfono'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('el calendario cambia de mes y limpia la selección', (
    tester,
  ) async {
    setSize(tester, const Size(360, 800));
    await tester.pumpWidget(
      wrap(
        CalendarScreen(
          data: data,
          today: _today,
          onRegisterBill: () {},
          onOpenService: (_) {},
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('12'));
    await tester.pumpAndSettle();
    expect(find.text('DÍA SELECCIONADO'), findsOneWidget);
    await tester.tap(find.byTooltip('Mes siguiente'));
    await tester.pumpAndSettle();
    expect(find.text('Selecciona un día'), findsOneWidget);
    expect(find.text('diciembre de 2026'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('la aplicación cambia entre rail y barra según el ancho', (
    tester,
  ) async {
    setSize(tester, const Size(1200, 800));
    final root = await tester.runAsync(
      () => Directory.systemTemp.createTemp('aldia_screens_'),
    );
    final controller = AppController(
      store: LocalStore(documentsDirectory: () async => root!),
      today: _today,
    );
    await tester.runAsync(controller.load);
    await tester.pumpWidget(AlDiaApp(controller: controller));
    await tester.pumpAndSettle();
    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
    expect(find.text('Empieza por un servicio'), findsOneWidget);

    tester.view.physicalSize = const Size(600, 800);
    await tester.pumpAndSettle();
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    await tester.tap(
      find.descendant(
        of: find.byType(NavigationBar),
        matching: find.text('Servicios'),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Aún no hay servicios'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox());
    controller.dispose();
    await tester.runAsync(() => root!.delete(recursive: true));
  });
}
