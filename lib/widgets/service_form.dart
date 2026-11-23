import 'package:flutter/material.dart';

import '../app_theme.dart';
import '../models/app_data.dart';

Future<bool> showServiceFormDialog(
  BuildContext context, {
  Service? service,
  required Future<void> Function(String name, String category) onSubmit,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) =>
        ServiceFormDialog(service: service, onSubmit: onSubmit),
  );
  return result ?? false;
}

class ServiceFormDialog extends StatefulWidget {
  const ServiceFormDialog({super.key, this.service, required this.onSubmit});

  final Service? service;
  final Future<void> Function(String name, String category) onSubmit;

  @override
  State<ServiceFormDialog> createState() => _ServiceFormDialogState();
}

class _ServiceFormDialogState extends State<ServiceFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late String _category;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.service?.name ?? '');
    _category = widget.service?.category ?? serviceCategories.first;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit(_name.text.trim(), _category);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = _messageFor(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = widget.service != null;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: Text(editing ? 'Editar servicio' : 'Agregar servicio'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Un servicio puede ser luz, agua, internet u otro pago '
                    'recurrente del hogar.',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: mutedInk),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _name,
                    autofocus: true,
                    maxLength: 50,
                    textInputAction: TextInputAction.done,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del servicio',
                      hintText: 'Por ejemplo, Luz del hogar',
                      counterText: '',
                    ),
                    validator: (value) {
                      final text = (value ?? '').trim();
                      if (text.isEmpty) {
                        return 'Escribe un nombre para el servicio.';
                      }
                      if (text.length > 50) {
                        return 'Usa 50 caracteres como máximo.';
                      }
                      return null;
                    },
                    onFieldSubmitted: (_) => _save(),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    initialValue: _category,
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    items: [
                      for (final category in serviceCategories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: _saving
                        ? null
                        : (value) {
                            if (value != null) {
                              setState(() => _category = value);
                            }
                          },
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _error!,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: _saving ? null : _save,
            child: _saving
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(editing ? 'Guardar cambios' : 'Agregar servicio'),
          ),
        ],
      ),
    );
  }
}

String _messageFor(Object error) =>
    error is Exception ? error.toString() : 'No se pudo guardar el servicio.';
