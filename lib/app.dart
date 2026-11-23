import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_theme.dart';
import 'data/local_store.dart';
import 'logic/bill_rules.dart';
import 'models/app_data.dart';
import 'screens/bill_form_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/service_detail_screen.dart';
import 'screens/services_screen.dart';
import 'screens/summary_screen.dart';
import 'state/app_controller.dart';
import 'widgets/layout_widgets.dart';
import 'widgets/service_form.dart';

class AlDiaApp extends StatefulWidget {
  const AlDiaApp({super.key, this.controller});

  final AppController? controller;

  @override
  State<AlDiaApp> createState() => _AlDiaAppState();
}

class _AlDiaAppState extends State<AlDiaApp> {
  late final AppController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? AppController(store: LocalStore());
    if (_controller.status != AppStatus.ready) {
      _controller.load();
    }
  }

  @override
  void dispose() {
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AlDía',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      home: _AppGate(controller: _controller),
    );
  }
}

class _AppGate extends StatefulWidget {
  const _AppGate({required this.controller});

  final AppController controller;

  @override
  State<_AppGate> createState() => _AppGateState();
}

class _AppGateState extends State<_AppGate> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      widget.controller.refreshToday();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, _) {
        return switch (widget.controller.status) {
          AppStatus.loading => const _LoadingScreen(),
          AppStatus.error => _LoadErrorScreen(controller: widget.controller),
          AppStatus.ready => _HomeShell(controller: widget.controller),
        };
      },
    );
  }
}

class _LoadingScreen extends StatelessWidget {
  const _LoadingScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('AlDía', style: Theme.of(context).textTheme.headlineMedium),
            const SizedBox(height: 6),
            Text(
              'Recibos y pagos del hogar',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: mutedInk),
            ),
            const SizedBox(height: 24),
            const SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
            const SizedBox(height: 12),
            Text(
              'Cargando datos…',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: mutedInk),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadErrorScreen extends StatelessWidget {
  const _LoadErrorScreen({required this.controller});

  final AppController controller;

  Future<void> _reset(BuildContext context) async {
    final confirmed = await confirmAction(
      context,
      title: 'Reiniciar datos',
      message:
          'El archivo actual no se pudo leer. Antes de reiniciar se '
          'conservará una copia del archivo inválido; después la aplicación '
          'empezará sin datos. Esta acción requiere tu confirmación.',
      confirmLabel: 'Conservar copia y reiniciar',
    );
    if (!confirmed || !context.mounted) return;
    try {
      final backup = await controller.resetAfterError();
      if (!context.mounted) return;
      showMessage(
        context,
        backup == null
            ? 'Datos reiniciados. No había un archivo anterior que copiar.'
            : 'Datos reiniciados. Copia conservada en $backup',
      );
    } catch (error) {
      if (!context.mounted) return;
      showMessage(context, _messageFor(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: ContentFrame(
            maxWidth: 620,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                const Icon(Icons.error_outline, size: 36),
                const SizedBox(height: 12),
                Text(
                  'No se pudieron cargar los datos',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 8),
                Text(
                  controller.errorMessage ??
                      'El archivo local no se pudo leer.',
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: 16),
                Text(
                  'El archivo original no se sobrescribe automáticamente. '
                  'Puedes reintentar la lectura o reiniciar los datos con '
                  'confirmación explícita.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: mutedInk),
                ),
                const SizedBox(height: 24),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: [
                    FilledButton.icon(
                      onPressed: controller.busy ? null : controller.retryLoad,
                      icon: const Icon(Icons.refresh, size: 20),
                      label: const Text('Reintentar'),
                    ),
                    OutlinedButton.icon(
                      onPressed: controller.busy ? null : () => _reset(context),
                      icon: const Icon(Icons.restart_alt, size: 20),
                      label: const Text('Reiniciar datos'),
                    ),
                  ],
                ),
                if (controller.busy) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(minHeight: 3),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomeShell extends StatefulWidget {
  const _HomeShell({required this.controller});

  final AppController controller;

  @override
  State<_HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<_HomeShell> {
  int _index = 0;

  AppController get _controller => widget.controller;

  Future<void> _addService() async {
    final added = await showServiceFormDialog(
      context,
      onSubmit: (name, category) async {
        await _controller.createService(name: name, category: category);
      },
    );
    if (added && mounted) showMessage(context, 'Servicio agregado.');
  }

  Future<void> _editService(Service service) async {
    final updated = await showServiceFormDialog(
      context,
      service: service,
      onSubmit: (name, category) async {
        await _controller.updateService(
          id: service.id,
          name: name,
          category: category,
        );
      },
    );
    if (updated && mounted) showMessage(context, 'Servicio actualizado.');
  }

  Future<void> _deleteService(
    Service service, {
    bool closeDetail = false,
  }) async {
    final count = _controller.data.bills
        .where((bill) => bill.serviceId == service.id)
        .length;
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar servicio',
      message: count == 0
          ? 'Se eliminará «${service.name}». No tiene recibos asociados.'
          : 'Se eliminará «${service.name}» y sus $count '
                '${count == 1 ? 'recibo asociado' : 'recibos asociados'}. '
                'Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar servicio',
    );
    if (!confirmed || !mounted) return;
    try {
      await _controller.deleteService(service.id);
      if (!mounted) return;
      if (closeDetail) Navigator.of(context).pop();
      showMessage(context, 'Servicio eliminado.');
    } catch (error) {
      if (mounted) showMessage(context, _messageFor(error));
    }
  }

  void _openService(Service service) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (routeContext) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            final current = _controller.data.serviceById(service.id);
            if (current == null) {
              return Scaffold(
                appBar: AppBar(),
                body: ContentFrame(
                  maxWidth: 620,
                  child: EmptyState(
                    icon: Icons.info_outline,
                    title: 'Este servicio ya no existe',
                    message:
                        'El servicio fue eliminado o los datos cambiaron. '
                        'Vuelve al resumen para continuar.',
                    action: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Volver'),
                    ),
                  ),
                ),
              );
            }
            return ServiceDetailScreen(
              data: _controller.data,
              service: current,
              today: _controller.today,
              busy: _controller.busy,
              onRegisterBill: () => _openBillForm(serviceId: current.id),
              onEditService: () => _editService(current),
              onDeleteService: () => _deleteService(current, closeDetail: true),
              onEditBill: (bill) =>
                  _openBillForm(bill: bill, serviceId: bill.serviceId),
              onDeleteBill: _deleteBill,
              onTogglePaid: _togglePaid,
            );
          },
        ),
      ),
    );
  }

  Future<void> _openBillForm({Bill? bill, String? serviceId}) async {
    final editing = bill != null;
    final result = await Navigator.of(context).push<Bill>(
      MaterialPageRoute<Bill>(
        builder: (routeContext) => ListenableBuilder(
          listenable: _controller,
          builder: (context, _) {
            Bill? latest;
            if (bill != null) {
              for (final item in _controller.data.bills) {
                if (item.id == bill.id) latest = item;
              }
            }
            return BillFormScreen(
              data: _controller.data,
              today: _controller.today,
              bill: latest,
              initialServiceId: serviceId,
              onSave: _controller.saveBill,
              onAddService: _addService,
            );
          },
        ),
      ),
    );
    if (result != null && mounted) {
      showMessage(
        context,
        editing ? 'Recibo actualizado.' : 'Recibo guardado.',
      );
    }
  }

  Future<void> _deleteBill(Bill bill) async {
    final service = _controller.data.serviceById(bill.serviceId);
    final confirmed = await confirmAction(
      context,
      title: 'Eliminar recibo',
      message:
          'Se eliminará el recibo de ${service?.name ?? 'este servicio'} con '
          'vencimiento ${dateLabel(bill.dueDate)} por '
          '${formatMoney(bill.amount)}. Esta acción no se puede deshacer.',
      confirmLabel: 'Eliminar recibo',
    );
    if (!confirmed || !mounted) return;
    try {
      await _controller.deleteBill(bill.id);
      if (mounted) showMessage(context, 'Recibo eliminado.');
    } catch (error) {
      if (mounted) showMessage(context, _messageFor(error));
    }
  }

  Future<void> _togglePaid(Bill bill) async {
    try {
      await _controller.setBillPaid(bill.id, !bill.paid);
      if (mounted) {
        showMessage(
          context,
          bill.paid
              ? 'Recibo marcado como pendiente.'
              : 'Recibo marcado como pagado.',
        );
      }
    } catch (error) {
      if (mounted) showMessage(context, _messageFor(error));
    }
  }

  Future<void> _showStorageInfo() async {
    try {
      final path = await _controller.storagePath();
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Información y almacenamiento'),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 480),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('AlDía organiza recibos; no procesa pagos.'),
                const SizedBox(height: 12),
                const Text(
                  'Los servicios y recibos se guardan en este archivo local:',
                ),
                const SizedBox(height: 12),
                SelectableText(
                  path,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Text(
                  'No se envía información a un servidor ni se sincroniza '
                  'entre dispositivos. Si desinstalas la aplicación o '
                  'eliminas sus datos, la información puede perderse.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: mutedInk),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cerrar'),
            ),
          ],
        ),
      );
    } catch (error) {
      if (mounted) showMessage(context, _messageFor(error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;
    final screens = <Widget>[
      SummaryScreen(
        data: controller.data,
        today: controller.today,
        onAddService: _addService,
        onRegisterBill: () => _openBillForm(),
        onViewService: _openService,
        onLoadDemo: controller.loadDemo,
        onClearDemo: controller.clearDemo,
        onOpenStorageInfo: _showStorageInfo,
      ),
      ServicesScreen(
        data: controller.data,
        busy: controller.busy,
        onAddService: _addService,
        onEditService: _editService,
        onDeleteService: _deleteService,
        onOpenService: _openService,
      ),
      CalendarScreen(
        data: controller.data,
        today: controller.today,
        busy: controller.busy,
        onRegisterBill: () => _openBillForm(),
        onOpenService: _openService,
      ),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= 900;
        if (wide) {
          return Scaffold(
            body: SafeArea(
              child: Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: (value) =>
                        setState(() => _index = value),
                    labelType: NavigationRailLabelType.all,
                    destinations: const [
                      NavigationRailDestination(
                        icon: Icon(Icons.space_dashboard_outlined),
                        selectedIcon: Icon(Icons.space_dashboard),
                        label: Text('Resumen'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.home_work_outlined),
                        selectedIcon: Icon(Icons.home_work),
                        label: Text('Servicios'),
                      ),
                      NavigationRailDestination(
                        icon: Icon(Icons.calendar_today_outlined),
                        selectedIcon: Icon(Icons.calendar_today),
                        label: Text('Calendario'),
                      ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(
                    child: IndexedStack(index: _index, children: screens),
                  ),
                ],
              ),
            ),
          );
        }
        return Scaffold(
          body: SafeArea(
            bottom: false,
            child: IndexedStack(index: _index, children: screens),
          ),
          bottomNavigationBar: DecoratedBox(
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: softDivider)),
            ),
            child: NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: (value) => setState(() => _index = value),
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.space_dashboard_outlined),
                  selectedIcon: Icon(Icons.space_dashboard),
                  label: 'Resumen',
                ),
                NavigationDestination(
                  icon: Icon(Icons.home_work_outlined),
                  selectedIcon: Icon(Icons.home_work),
                  label: 'Servicios',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_today_outlined),
                  selectedIcon: Icon(Icons.calendar_today),
                  label: 'Calendario',
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

String _messageFor(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}
