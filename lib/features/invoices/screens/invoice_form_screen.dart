import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:intl/intl.dart';
import '../bloc/invoice_bloc.dart';
import '../../clients/bloc/client_bloc.dart';
import '../../clients/bloc/client_event.dart';
import '../../clients/bloc/client_state.dart';
import '../../products/bloc/product_bloc.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/invoice_service.dart';

class InvoiceFormScreen extends StatefulWidget {
  final InvoiceType type;
  final Invoice? invoice;

  const InvoiceFormScreen({
    Key? key,
    required this.type,
    this.invoice,
  }) : super(key: key);

  @override
  State<InvoiceFormScreen> createState() => _InvoiceFormScreenState();
}

class _InvoiceFormScreenState extends State<InvoiceFormScreen> {
  final _formKey = GlobalKey<FormBuilderState>();
  final InvoiceService _invoiceService = InvoiceService();
  
  List<InvoiceItem> _items = [];
  double _subtotal = 0.0;
  double _discount = 0.0;
  double _tax = 0.0;
  double _total = 0.0;
  
  bool get isEditing => widget.invoice != null;
  String get title => isEditing 
      ? 'Edit ${widget.type.value.toUpperCase()}'
      : 'New ${widget.type.value.toUpperCase()}';

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClients());
    context.read<ProductBloc>().add(LoadProducts());
    
    if (isEditing) {
      _loadExistingInvoice();
    } else {
      _addEmptyItem();
    }
  }

  Future<void> _loadExistingInvoice() async {
    // TODO: Load invoice items from database
    _addEmptyItem();
  }

  void _addEmptyItem() {
    setState(() {
      _items.add(InvoiceItem(
        invoiceId: 0,
        description: '',
        quantity: 1.0,
        unitPrice: 0.0,
        total: 0.0,
      ));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        elevation: 0,
      ),
      body: FormBuilder(
        key: _formKey,
        initialValue: _getInitialValues(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClientSection(),
              const SizedBox(height: 24),
              _buildInvoiceDetailsSection(),
              const SizedBox(height: 24),
              _buildItemsSection(),
              const SizedBox(height: 24),
              _buildTotalsSection(),
              const SizedBox(height: 24),
              _buildNotesSection(),
              const SizedBox(height: 32),
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getInitialValues() {
    if (!isEditing) {
      return {
        'issueDate': DateTime.now(),
        'dueDate': DateTime.now().add(const Duration(days: 30)),
      };
    }
    
    final invoice = widget.invoice!;
    return {
      'clientId': invoice.clientId,
      'issueDate': invoice.issueDate,
      'dueDate': invoice.dueDate,
      'notes': invoice.notes,
      'terms': invoice.terms,
      'discountAmount': invoice.discountAmount,
      'taxAmount': invoice.taxAmount,
    };
  }

  Widget _buildClientSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Client Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            BlocBuilder<ClientBloc, ClientState>(
              builder: (context, state) {
                if (state is ClientLoaded) {
                  return FormBuilderDropdown<int>(
                    name: 'clientId',
                    decoration: const InputDecoration(
                      labelText: 'Select Client *',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(),
                    items: state.clients.map((client) {
                      return DropdownMenuItem(
                        value: client.id!,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(client.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                            Text(client.email, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                }
                return const CircularProgressIndicator();
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${widget.type.value.toUpperCase()} Details',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'issueDate',
                    inputType: InputType.date,
                    decoration: const InputDecoration(
                      labelText: 'Issue Date *',
                      border: OutlineInputBorder(),
                    ),
                    validator: FormBuilderValidators.required(),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FormBuilderDateTimePicker(
                    name: 'dueDate',
                    inputType: InputType.date,
                    decoration: InputDecoration(
                      labelText: widget.type == InvoiceType.estimate ? 'Valid Until' : 'Due Date',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Items',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: _addEmptyItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Item'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _items.length,
              itemBuilder: (context, index) {
                return _buildItemRow(index);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    initialValue: item.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _items[index] = item.copyWith(description: value);
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Qty',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final qty = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _items[index] = item.copyWith(
                          quantity: qty,
                          total: qty * item.unitPrice,
                        );
                        _calculateTotals();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextFormField(
                    initialValue: item.unitPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Price',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      final price = double.tryParse(value) ?? 0.0;
                      setState(() {
                        _items[index] = item.copyWith(
                          unitPrice: price,
                          total: item.quantity * price,
                        );
                        _calculateTotals();
                      });
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    NumberFormat.currency(symbol: '\$').format(item.total),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                    textAlign: TextAlign.right,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeItem(index),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalsSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Subtotal:'),
                Text(NumberFormat.currency(symbol: '\$').format(_subtotal)),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Discount:')),
                Expanded(
                  child: TextFormField(
                    initialValue: _discount.toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        _discount = double.tryParse(value) ?? 0.0;
                        _calculateTotals();
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(child: Text('Tax:')),
                Expanded(
                  child: TextFormField(
                    initialValue: _tax.toString(),
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      isDense: true,
                      prefixText: '\$ ',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    onChanged: (value) {
                      setState(() {
                        _tax = double.tryParse(value) ?? 0.0;
                        _calculateTotals();
                      });
                    },
                  ),
                ),
              ],
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                Text(
                  NumberFormat.currency(symbol: '\$').format(_total),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotesSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Additional Information',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            FormBuilderTextField(
              name: 'notes',
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 16),
            FormBuilderTextField(
              name: 'terms',
              decoration: const InputDecoration(
                labelText: 'Terms & Conditions',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            onPressed: _saveInvoice,
            child: Text(isEditing ? 'Update' : 'Create'),
          ),
        ),
      ],
    );
  }

  void _removeItem(int index) {
    if (_items.length > 1) {
      setState(() {
        _items.removeAt(index);
        _calculateTotals();
      });
    }
  }

  void _calculateTotals() {
    _subtotal = _items.fold(0.0, (sum, item) => sum + item.total);
    _total = _subtotal - _discount + _tax;
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      
      try {
        final invoiceNumber = await _invoiceService.generateInvoiceNumber(widget.type);
        
        final invoice = Invoice(
          id: isEditing ? widget.invoice!.id : null,
          number: isEditing ? widget.invoice!.number : invoiceNumber,
          type: widget.type,
          clientId: values['clientId'],
          issueDate: values['issueDate'],
          dueDate: values['dueDate'],
          subtotal: _subtotal,
          discountAmount: _discount,
          taxAmount: _tax,
          total: _total,
          notes: values['notes'],
          terms: values['terms'],
        );

        if (isEditing) {
          context.read<InvoiceBloc>().add(UpdateInvoice(invoice));
        } else {
          context.read<InvoiceBloc>().add(CreateInvoice(invoice, _items));
        }

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }
}