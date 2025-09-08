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
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        toolbarHeight: 80,
        iconTheme: const IconThemeData(color: Colors.black87),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: FormBuilder(
        key: _formKey,
        initialValue: _getInitialValues(),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildClientSection(),
              const SizedBox(height: 20),
              _buildInvoiceDetailsSection(),
              const SizedBox(height: 20),
              _buildItemsSection(),
              const SizedBox(height: 20),
              _buildTotalsSection(),
              const SizedBox(height: 20),
              _buildNotesSection(),
              const SizedBox(height: 60),
              _buildActionButtons(),
              const SizedBox(height: 40),
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
    return _buildSection(
      title: 'Client Information',
      icon: Icons.person_outline,
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, state) {
          if (state is ClientLoaded) {
            return _buildStyledDropdown(
              name: 'clientId',
              labelText: 'Select Client *',
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
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildInvoiceDetailsSection() {
    return _buildSection(
      title: '${widget.type.value.toUpperCase()} Details',
      icon: Icons.calendar_today_outlined,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildFormField(
                  name: 'issueDate',
                  labelText: 'Issue Date *',
                  isDateField: true,
                  validator: FormBuilderValidators.required(),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildFormField(
                  name: 'dueDate',
                  labelText: widget.type == InvoiceType.estimate ? 'Valid Until' : 'Due Date',
                  isDateField: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemsSection() {
    return _buildSection(
      title: 'Items',
      icon: Icons.list_alt_outlined,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Line Items', style: TextStyle(fontWeight: FontWeight.w500)),
              TextButton.icon(
                onPressed: _addEmptyItem,
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Item'),
                style: TextButton.styleFrom(foregroundColor: Colors.blue),
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
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          TextFormField(
            initialValue: item.description,
            decoration: const InputDecoration(
              labelText: 'Description',
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 8),
            ),
            onChanged: (value) {
              setState(() {
                _items[index] = item.copyWith(description: value);
              });
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.quantity.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Quantity',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
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
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  initialValue: item.unitPrice.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Unit Price',
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
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
              const SizedBox(width: 16),
              Container(
                width: 80,
                child: Column(
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                      ),
                    ),
                    Text(
                      NumberFormat.currency(symbol: '\$').format(item.total),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _removeItem(index),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTotalsSection() {
    return _buildSection(
      title: 'Totals',
      icon: Icons.calculate_outlined,
      child: Column(
        children: [
          _buildTotalRow('Subtotal', _subtotal, isBold: false),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Discount',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    initialValue: _discount.toString(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Tax',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),
              ),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    initialValue: _tax.toString(),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
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
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),
          _buildTotalRow('Total', _total, isBold: true),
        ],
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isBold = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '$label:',
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.grey.shade700,
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$').format(amount),
          style: TextStyle(
            fontSize: isBold ? 18 : 16,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildNotesSection() {
    return _buildSection(
      title: 'Additional Information',
      icon: Icons.note_outlined,
      child: Column(
        children: [
          _buildFormField(
            name: 'notes',
            labelText: 'Notes',
            maxLines: 3,
          ),
          const SizedBox(height: 16),
          _buildFormField(
            name: 'terms',
            labelText: 'Terms & Conditions',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    IconData? icon,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) ...[
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                ],
              ),
            ] else ...[
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildFormField({
    required String name,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
    bool isDateField = false,
  }) {
    if (isDateField) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: FormBuilderDateTimePicker(
          name: name,
          inputType: InputType.date,
          validator: validator != null ? (DateTime? value) {
            return validator(value?.toString());
          } : null,
          decoration: InputDecoration(
            labelText: labelText,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: FormBuilderTextField(
        name: name,
        validator: validator,
        maxLines: maxLines,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildStyledDropdown({
    required String name,
    required String labelText,
    String? Function(int?)? validator,
    required List<DropdownMenuItem<int>> items,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: FormBuilderDropdown<int>(
        name: name,
        validator: validator,
        items: items,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Container(
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(25),
            ),
            child: TextButton(
              onPressed: _saveInvoice,
              child: Text(
                isEditing ? 'Update' : 'Create',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
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