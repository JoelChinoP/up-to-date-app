import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/app_data.dart';
import '../widgets/category_icon.dart';
import '../widgets/layout_widgets.dart';

class ServicesScreen extends StatelessWidget {
  const ServicesScreen({
    super.key,
    required this.data,
    required this.onAddService,
    required this.onEditService,
    required this.onDeleteService,
    required this.onOpenService,
    this.busy = false,
  });

  final AppData data;
  final VoidCallback onAddService;
  final ValueChanged<Service> onEditService;
  final ValueChanged<Service> onDeleteService;
  final ValueChanged<Service> onOpenService;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    final services = data.services;
    if (services.isEmpty) {
      return ListView(
        children: [
          ContentFrame(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeading(
                  title: 'Servicios',
                  subtitle: 'Luz, agua, internet y otros pagos del hogar.',
                  trailing: FilledButton.icon(
                    onPressed: busy ? null : onAddService,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Agregar servicio'),
                  ),
                ),
                const SizedBox(height: 24),
                MoSurface(
                  fill: true,
                  border: false,
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.home_work_outlined,
                    title: 'Aún no hay servicios',
                    message: 'Agrega luz, agua o internet para empezar.',
                    action: FilledButton.icon(
                      onPressed: busy ? null : onAddService,
                      icon: const Icon(Icons.add, size: 20),
                      label: const Text('Agregar servicio'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      itemCount: services.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return ContentFrame(
            verticalPadding: 24,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageHeading(
                  title: 'Servicios',
                  subtitle: 'Luz, agua, internet y otros pagos del hogar.',
                  trailing: FilledButton.icon(
                    onPressed: busy ? null : onAddService,
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Agregar servicio'),
                  ),
                ),
                const SizedBox(height: 20),
                SectionLabel(
                  '${services.length} '
                  '${services.length == 1 ? 'servicio' : 'servicios'}',
                ),
              ],
            ),
          );
        }
        final service = services[index - 1];
        return _ServiceRow(
          service: service,
          billCount: data.bills
              .where((bill) => bill.serviceId == service.id)
              .length,
          busy: busy,
          onOpen: () => onOpenService(service),
          onEdit: () => onEditService(service),
          onDelete: () => onDeleteService(service),
        );
      },
    );
  }
}

class _ServiceRow extends StatelessWidget {
  const _ServiceRow({
    required this.service,
    required this.billCount,
    required this.busy,
    required this.onOpen,
    required this.onEdit,
    required this.onDelete,
  });

  final Service service;
  final int billCount;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return ContentFrame(
      maxWidth: 1100,
      verticalPadding: 0,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onOpen,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: softDivider)),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: softSurface,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      categoryIcon(service.category),
                      size: 22,
                      color: ink,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          service.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${service.category} · $billCount '
                          '${billCount == 1 ? 'recibo' : 'recibos'}',
                          style: Theme.of(
                            context,
                          ).textTheme.bodyMedium?.copyWith(color: mutedInk),
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    tooltip: 'Acciones de ${service.name}',
                    enabled: !busy,
                    onSelected: (value) {
                      if (value == 'edit') onEdit();
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'edit',
                        child: ListTile(
                          leading: Icon(Icons.edit_outlined, size: 20),
                          title: Text('Editar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'delete',
                        child: ListTile(
                          leading: Icon(Icons.delete_outline, size: 20),
                          title: Text('Eliminar'),
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                  const Icon(Icons.chevron_right, size: 20, color: mutedInk),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
