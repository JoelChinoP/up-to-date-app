import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'data/demo_data.dart';
import 'models/app_data.dart';
import 'screens/bill_form_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/services_screen.dart';
import 'screens/summary_screen.dart';
import 'state/app_controller.dart';
import 'widgets/layout_widgets.dart';

/// Entrada aislada para el hito LAB04. Cada pantalla se abre con datos
/// ficticios y sin navegación de producto ni escritura en disco.
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  const screen = String.fromEnvironment(
    'LAB04_SCREEN',
    defaultValue: 'summary',
  );
  const state = String.fromEnvironment('LAB04_STATE', defaultValue: 'sample');
  runApp(const Lab04PreviewApp(screen: screen, state: state));
}

class Lab04PreviewApp extends StatelessWidget {
  const Lab04PreviewApp({super.key, required this.screen, required this.state});

  final String screen;
  final String state;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlDía · LAB04',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: Scaffold(
        body: SafeArea(
          child: Builder(builder: (context) => _buildScreen(context)),
        ),
      ),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final fixedToday = DateTime.utc(2026, 11, 12);
    final data = state == 'empty' ? AppData.empty : demoAppData(fixedToday);
    final errorRequested =
        state == 'error' &&
        (screen == 'summary' || screen == 'services' || screen == 'calendar');
    if (errorRequested) return _PreviewError();

    switch (screen) {
      case 'services':
        return ServicesScreen(
          data: data,
          onAddService: () => _design(context),
          onEditService: (_) => _design(context),
          onDeleteService: (_) => _design(context),
          onOpenService: (_) => _design(context),
        );
      case 'service-detail':
        final service = data.services.isEmpty ? null : data.services.first;
        if (service == null) {
          return _EmptyPreview(
            message: 'No hay un servicio ficticio para mostrar el detalle.',
          );
        }
        return ServiceDetailScreen(
          data: data,
          service: service,
          today: fixedToday,
          onRegisterBill: () => _design(context),
          onEditService: () => _design(context),
          onDeleteService: () => _design(context),
          onEditBill: (_) => _design(context),
          onDeleteBill: (_) => _design(context),
          onTogglePaid: (_) => _design(context),
        );
      case 'bill-form':
        return BillFormScreen(
          data: data,
          today: fixedToday,
          onSave:
              ({
                String? id,
                required String serviceId,
                required String amountText,
                required String dueDate,
              }) async {
                throw const AppException(
                  'Vista de diseño: el guardado se habilita en la etapa '
                  'funcional.',
                );
              },
          onAddService: () => _design(context),
        );
      case 'calendar':
        return CalendarScreen(
          data: data,
          today: fixedToday,
          onRegisterBill: () => _design(context),
          onOpenService: (_) => _design(context),
        );
      case 'summary':
      default:
        return SummaryScreen(
          data: data,
          today: fixedToday,
          onAddService: () => _design(context),
          onRegisterBill: () => _design(context),
          onViewService: (_) => _design(context),
        );
    }
  }

  void _design(BuildContext context) {
    showMessage(
      context,
      'Vista de diseño: esta acción se habilita en la etapa funcional.',
    );
  }
}

class _PreviewError extends StatelessWidget {
  const _PreviewError();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: ContentFrame(
        maxWidth: 620,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 32),
            const Icon(Icons.error_outline, size: 36),
            const SizedBox(height: 12),
            Text(
              'No se pudieron cargar los datos',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'El archivo local no se pudo leer. Reintenta sin sobrescribirlo.',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => showMessage(
                context,
                'Vista de diseño: la lectura se habilita en la etapa funcional.',
              ),
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Reintentar lectura'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyPreview extends StatelessWidget {
  const _EmptyPreview({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return ContentFrame(
      maxWidth: 620,
      child: Text(message, style: Theme.of(context).textTheme.bodyLarge),
    );
  }
}
