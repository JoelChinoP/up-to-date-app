import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../app_theme.dart';
import '../logic/bill_rules.dart';
import '../models/app_data.dart';
import '../widgets/layout_widgets.dart';

class BillFormScreen extends StatefulWidget {
  const BillFormScreen({
    super.key,
    required this.data,
    required this.today,
    required this.onSave,
    required this.onAddService,
    this.bill,
    this.initialServiceId,
  });

  final AppData data;
  final DateTime today;
  final Bill? bill;
  final String? initialServiceId;
  final Future<Bill> Function({
    String? id,
    required String serviceId,
    required String amountText,
    required String dueDate,
  })
  onSave;
  final VoidCallback onAddService;

  @override
  State<BillFormScreen> createState() => _BillFormScreenState();
}

class _BillFormScreenState extends State<BillFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _dateText;
  String? _serviceId;
  String? _dueDate;
  bool _saving = false;
  String? _error;
  String? _duplicateError;

  bool get _editing => widget.bill != null;

  @override
  void initState() {
    super.initState();
    final bill = widget.bill;
    _amount = TextEditingController(
      text: bill == null ? '' : formatCentsForInput(bill.amount),
    );
    _dueDate = bill?.dueDate;
    _dateText = TextEditingController(
      text: bill == null ? '' : dateLabel(bill.dueDate),
    );
    _serviceId =
        bill?.serviceId ??
        widget.initialServiceId ??
        (widget.data.services.length == 1
            ? widget.data.services.first.id
            : null);
  }

  @override
  void didUpdateWidget(BillFormScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_serviceId == null && widget.data.services.length == 1) {
      _serviceId = widget.data.services.first.id;
    }
  }

  @override
  void dispose() {
    _amount.dispose();
    _dateText.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final initial = _dueDate == null ? widget.today : parseIsoDate(_dueDate!);
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.utc(2000, 1, 1),
      lastDate: DateTime.utc(2100, 12, 31),
      helpText: 'Selecciona el vencimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    if (picked == null || !mounted) return;
    final civil = DateTime.utc(picked.year, picked.month, picked.day);
    setState(() {
      _dueDate = isoDate(civil);
      _dateText.text = dateLabel(_dueDate!);
      _duplicateError = null;
      _error = null;
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid) return;
    final serviceId = _serviceId;
    final dueDate = _dueDate;
    if (serviceId == null || dueDate == null) return;
    setState(() {
      _saving = true;
      _error = null;
      _duplicateError = null;
    });
    try {
      final bill = await widget.onSave(
        id: widget.bill?.id,
        serviceId: serviceId,
        amountText: _amount.text,
        dueDate: dueDate,
      );
      if (!mounted) return;
      Navigator.of(context).pop(bill);
    } catch (error) {
      if (!mounted) return;
      final message = _messageFor(error);
      setState(() {
        _saving = false;
        if (message.contains('ya tiene un recibo')) {
          _duplicateError = message;
        } else {
          _error = message;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final services = widget.data.services;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: Text(_editing ? 'Editar recibo' : 'Registrar recibo'),
        ),
        body: SafeArea(
          child: services.isEmpty
              ? Center(
                  child: SingleChildScrollView(
                    child: ContentFrame(
                      maxWidth: 560,
                      child: EmptyState(
                        icon: Icons.home_work_outlined,
                        title: 'Primero agrega un servicio',
                        message:
                            'Agrega luz, agua o internet antes de registrar '
                            'un recibo.',
                        action: FilledButton.icon(
                          onPressed: widget.onAddService,
                          icon: const Icon(Icons.add, size: 20),
                          label: const Text('Agregar servicio'),
                        ),
                      ),
                    ),
                  ),
                )
              : SingleChildScrollView(
                  child: ContentFrame(
                    maxWidth: 560,
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_error != null) ...[
                            _ErrorLine(message: _error!),
                            const SizedBox(height: 16),
                          ],
                          DropdownButtonFormField<String>(
                            key: ValueKey('service-${_serviceId ?? 'none'}'),
                            initialValue: _serviceId,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Servicio',
                            ),
                            hint: const Text('Selecciona un servicio'),
                            items: [
                              for (final service in services)
                                DropdownMenuItem(
                                  value: service.id,
                                  child: Text(
                                    '${service.name} · ${service.category}',
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) {
                                    setState(() {
                                      _serviceId = value;
                                      _duplicateError = null;
                                    });
                                  },
                            validator: (value) => value == null
                                ? 'Selecciona el servicio del recibo.'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _amount,
                            enabled: !_saving,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9.,]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              labelText: 'Monto del recibo (S/)',
                              hintText: '0.00',
                            ),
                            validator: (value) {
                              try {
                                parseAmountCents(value ?? '');
                                return null;
                              } on FormatException catch (error) {
                                return error.message;
                              }
                            },
                          ),
                          const SizedBox(height: 18),
                          TextFormField(
                            controller: _dateText,
                            readOnly: true,
                            enabled: !_saving,
                            onTap: _pickDate,
                            decoration: const InputDecoration(
                              labelText: 'Vencimiento',
                              hintText: 'Selecciona una fecha',
                              suffixIcon: Icon(Icons.calendar_today_outlined),
                            ),
                            validator: (_) => _dueDate == null
                                ? 'Selecciona el vencimiento del recibo.'
                                : null,
                          ),
                          if (_duplicateError != null) ...[
                            const SizedBox(height: 12),
                            _ErrorLine(message: _duplicateError!),
                          ],
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton(
                              onPressed: _saving ? null : _save,
                              child: _saving
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        ),
                                        SizedBox(width: 10),
                                        Text('Guardando…'),
                                      ],
                                    )
                                  : Text(
                                      _editing
                                          ? 'Guardar cambios'
                                          : 'Guardar recibo',
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}

class _ErrorLine extends StatelessWidget {
  const _ErrorLine({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: divider),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, size: 20),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}

String _messageFor(Object error) {
  final text = error.toString();
  return text.startsWith('Exception: ') ? text.substring(11) : text;
}
