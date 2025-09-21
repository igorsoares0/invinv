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
import 'invoice_preview_screen.dart';

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
      // Ensure list is empty for new invoices
      setState(() {
        _items.clear();
      });
      // Generate initial invoice number for new invoices
      _generateInitialInvoiceNumber();
    }
  }

  Future<void> _loadExistingInvoice() async {
    try {
      final items = await _invoiceService.getInvoiceItems(widget.invoice!.id!);
      setState(() {
        _items = items.isNotEmpty ? items : [];
        _discount = widget.invoice!.discountAmount;
        _tax = widget.invoice!.taxAmount;
        _calculateTotals();
      });
    } catch (e) {
      // No items to load, start with empty list
    }
  }

  void _addEmptyItem() {
    setState(() {
      _items.add(InvoiceItem(
        invoiceId: 0,
        name: '',
        description: '',
        quantity: 1.0,
        unit: 'un',
        unitPrice: 0.0,
        category: null,
        total: 0.0,
      ));
    });
  }

  void _showAddItemModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddItemModal(),
    );
  }

  void _editItem(int index) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAddItemModal(editingIndex: index),
    );
  }

  void _showPreview() {
    if (widget.invoice?.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => InvoicePreviewScreen(invoiceId: widget.invoice!.id!),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please save the invoice first to see preview'),
          backgroundColor: Colors.orange,
        ),
      );
    }
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
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: IconButton(
              onPressed: _showPreview,
              icon: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.visibility_outlined,
                  color: Colors.blue,
                  size: 22,
                ),
              ),
              tooltip: 'Preview Invoice',
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: FormBuilder(
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
                    const SizedBox(height: 120),
                  ],
                ),
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Map<String, dynamic> _getInitialValues() {
    if (!isEditing) {
      return {
        'issueDate': DateTime.now(),
        // Due date is optional - no default value
      };
    }
    
    final invoice = widget.invoice!;
    return {
      'clientId': invoice.clientId,
      'number': invoice.number,
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
                  child: SizedBox(
                    width: double.infinity,
                    child: Text(
                      '${client.name} • ${client.email}',
                      style: const TextStyle(fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
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
          // Invoice Number field
          _buildFormField(
            name: 'number',
            labelText: '${widget.type.value.toUpperCase()} Number *',
            hintText: 'Edit number if needed',
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Number is required';
              }
              if (value.trim().length < 3) {
                return 'Number must be at least 3 characters';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
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
                  labelText: widget.type == InvoiceType.estimate ? 'Valid Until (Optional)' : 'Due Date (Optional)',
                  hintText: 'Leave blank if no due date',
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
          if (_items.isEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200, style: BorderStyle.solid),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_outlined,
                    size: 48,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No items added yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add products or services to this invoice',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ] else ...[
            // Show added items as cards
            ...List.generate(_items.length, (index) => _buildItemCard(index)),
            const SizedBox(height: 16),
          ],
          // Add Item button
          Container(
            width: double.infinity,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.blue,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TextButton.icon(
              onPressed: _showAddItemModal,
              icon: const Icon(Icons.add, color: Colors.white, size: 20),
              label: Text(
                _items.isEmpty ? 'Add First Item' : 'Add Another Item',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              style: TextButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    if (item.description.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.description,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                    if (item.category != null && item.category!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Text(
                          item.category!,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade700,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\$').format(item.total),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${item.quantity} ${item.unit} × \$${item.unitPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 36,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: TextButton.icon(
                    onPressed: () => _editItem(index),
                    icon: Icon(Icons.edit_outlined, size: 16, color: Colors.grey.shade700),
                    label: Text(
                      'Edit',
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                    ),
                    style: TextButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.red.shade300),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _removeItem(index),
                  icon: Icon(Icons.delete_outline, size: 16, color: Colors.red.shade600),
                  padding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemRow(int index) {
    final item = _items[index];
    final List<String> _units = ['un', 'hr', 'kg', 'lb', 'm', 'ft', 'L', 'gal', 'piece', 'box'];

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
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    key: ValueKey('name_${index}_${item.name}'),
                    initialValue: item.name,
                    decoration: const InputDecoration(
                      labelText: 'Product/Service Name *',
                      hintText: 'Enter name...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _items[index] = item.copyWith(name: value);
                      });
                    },
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Name is required';
                      }
                      return null;
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    key: ValueKey('description_${index}_${item.description}'),
                    initialValue: item.description,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Optional details...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _items[index] = item.copyWith(description: value);
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: IconButton(
                  onPressed: () => _showProductSelector(index),
                  icon: Icon(
                    Icons.inventory_2_outlined,
                    color: Colors.green.shade700,
                    size: 20,
                  ),
                  tooltip: 'Select from products',
                  padding: const EdgeInsets.all(12),
                  constraints: const BoxConstraints(
                    minWidth: 44,
                    minHeight: 44,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    key: ValueKey('quantity_${index}_${item.quantity}'),
                    initialValue: item.quantity.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Quantity',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: DropdownButtonFormField<String>(
                    key: ValueKey('unit_${index}_${item.unit}'),
                    value: _units.contains(item.unit) ? item.unit : 'un',
                    decoration: const InputDecoration(
                      labelText: 'Unit',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    items: _units.map((unit) => DropdownMenuItem(
                      value: unit,
                      child: Text(unit),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _items[index] = item.copyWith(unit: value ?? 'un');
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    key: ValueKey('unitPrice_${index}_${item.unitPrice}'),
                    initialValue: item.unitPrice.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Unit Price',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
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
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextFormField(
                    key: ValueKey('category_${index}_${item.category ?? ""}'),
                    initialValue: item.category ?? '',
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      hintText: 'Optional category...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _items[index] = item.copyWith(category: value.isEmpty ? null : value);
                      });
                    },
                  ),
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
    String? hintText,
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
        child: Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: Colors.blue,
              secondary: Colors.blue.shade100,
              surface: Colors.white,
              onSurface: Colors.black87,
              onPrimary: Colors.white,
            ),
            dialogBackgroundColor: Colors.white,
            dialogTheme: DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 8,
              shadowColor: Colors.black.withOpacity(0.1),
            ),
            datePickerTheme: DatePickerThemeData(
              backgroundColor: Colors.white,
              headerBackgroundColor: Colors.blue,
              headerForegroundColor: Colors.white,
              dayStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
              todayBackgroundColor: MaterialStateProperty.all(Colors.blue.shade50),
              todayForegroundColor: MaterialStateProperty.all(Colors.blue.shade700),
              dayForegroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.white;
                }
                return Colors.black87;
              }),
              dayBackgroundColor: MaterialStateProperty.resolveWith((states) {
                if (states.contains(MaterialState.selected)) {
                  return Colors.blue;
                }
                return null;
              }),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              dayShape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue,
                textStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          child: FormBuilderDateTimePicker(
            name: name,
            inputType: InputType.date,
            validator: validator != null ? (DateTime? value) {
              return validator(value?.toString());
            } : null,
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
            decoration: InputDecoration(
              labelText: labelText,
              hintText: hintText,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              suffixIcon: Container(
                margin: const EdgeInsets.all(8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.calendar_today,
                  size: 20,
                  color: Colors.blue.shade700,
                ),
              ),
            ),
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
          hintText: hintText,
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
        itemHeight: 56,
        menuMaxHeight: 300,
        dropdownColor: Colors.white,
        iconEnabledColor: Colors.blue.shade700,
        iconSize: 20,
        decoration: InputDecoration(
          labelText: labelText,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        style: const TextStyle(
          fontSize: 14,
          color: Colors.black87,
          fontWeight: FontWeight.w500,
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

  Future<void> _generateInitialInvoiceNumber() async {
    try {
      final invoiceNumber = await _invoiceService.generateInvoiceNumber(widget.type);
      // Wait for the form to be built before setting the initial value
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _formKey.currentState?.fields['number']?.didChange(invoiceNumber);
      });
    } catch (e) {
      // Silently fail for initial generation, user can manually enter number
    }
  }

  void _showProductSelector(int? itemIndex) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildProductSelectorSheet(itemIndex),
    );
  }

  void _showManualItemForm({int? editingIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildManualItemForm(editingIndex: editingIndex),
    );
  }

  Widget _buildAddItemModal({int? editingIndex}) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Modal Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.add_shopping_cart, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        editingIndex != null ? 'Edit Item' : 'Add Item',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Options
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Option 1: Create Manually
                  Container(
                    width: double.infinity,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.blue.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showManualItemForm(editingIndex: editingIndex);
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.edit_outlined,
                              color: Colors.blue.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Create Manually',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Enter product/service details manually',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Option 2: Select from Products
                  Container(
                    width: double.infinity,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.green.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                        _showProductSelector(editingIndex);
                      },
                      style: TextButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2_outlined,
                              color: Colors.green.shade600,
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Text(
                                  'Select from Products',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                  ),
                                ),
                                Text(
                                  'Choose from your existing products',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.grey.shade400,
                            size: 16,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualItemForm({int? editingIndex}) {
    final _manualFormKey = GlobalKey<FormBuilderState>();
    final List<String> _units = ['un', 'hr', 'kg', 'lb', 'm', 'ft', 'L', 'gal', 'piece', 'box'];

    final isEditing = editingIndex != null;
    final initialValues = isEditing ? {
      'name': _items[editingIndex].name,
      'description': _items[editingIndex].description,
      'quantity': _items[editingIndex].quantity.toString(),
      'unit': _items[editingIndex].unit,
      'unitPrice': _items[editingIndex].unitPrice.toString(),
      'category': _items[editingIndex].category,
    } : {
      'quantity': '1',
      'unit': 'un',
      'unitPrice': '0',
    };

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.edit_outlined, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Item' : 'Create Item Manually',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Form
          Expanded(
            child: FormBuilder(
              key: _manualFormKey,
              initialValue: initialValues,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildManualFormField(
                      name: 'name',
                      icon: Icons.inventory_2_outlined,
                      labelText: 'Product/Service Name *',
                      validator: FormBuilderValidators.required(),
                    ),
                    const SizedBox(height: 20),
                    _buildManualFormField(
                      name: 'description',
                      icon: Icons.description_outlined,
                      labelText: 'Description',
                      maxLines: 3,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _buildManualFormField(
                            name: 'quantity',
                            icon: Icons.numbers,
                            labelText: 'Quantity *',
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            validator: FormBuilderValidators.compose([
                              FormBuilderValidators.required(),
                              FormBuilderValidators.numeric(),
                              FormBuilderValidators.min(0.01),
                            ]),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.straighten,
                                    size: 20,
                                    color: Colors.grey.shade600,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Unit',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Container(
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
                                child: FormBuilderDropdown<String>(
                                  name: 'unit',
                                  items: _units.map((unit) => DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  )).toList(),
                                  decoration: const InputDecoration(
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 16,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _buildManualFormField(
                      name: 'unitPrice',
                      icon: Icons.attach_money,
                      labelText: 'Unit Price *',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: FormBuilderValidators.compose([
                        FormBuilderValidators.required(),
                        FormBuilderValidators.numeric(),
                        FormBuilderValidators.min(0),
                      ]),
                    ),
                    const SizedBox(height: 20),
                    _buildManualFormField(
                      name: 'category',
                      icon: Icons.category_outlined,
                      labelText: 'Category',
                    ),
                    const SizedBox(height: 40),
                    Row(
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
                              onPressed: () => _saveManualItem(_manualFormKey, editingIndex),
                              child: Text(
                                isEditing ? 'Update Item' : 'Add Item',
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
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSelectorSheet(int? itemIndex) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Icon(Icons.inventory_2, color: Colors.blue.shade600),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Select Product',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Search products...',
                      prefixIcon: Icon(Icons.search, color: Colors.grey.shade400),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (query) {
                      context.read<ProductBloc>().add(SearchProducts(query));
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: BlocBuilder<ProductBloc, ProductState>(
              builder: (context, state) {
                if (state is ProductLoaded) {
                  if (state.products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: () {
                              // Navigate to create product
                            },
                            child: const Text('Add your first product'),
                          ),
                        ],
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: state.products.length,
                    itemBuilder: (context, index) {
                      final product = state.products[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.shade200),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          leading: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.blue.shade50,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              Icons.inventory_2,
                              color: Colors.blue.shade600,
                            ),
                          ),
                          title: Text(
                            product.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (product.description != null && product.description!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  product.description!,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 14,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      NumberFormat.currency(symbol: '\$').format(product.price),
                                      style: TextStyle(
                                        color: Colors.green.shade700,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      product.unit,
                                      style: TextStyle(
                                        color: Colors.grey.shade700,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue.shade600,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: IconButton(
                              onPressed: () {
                                _selectProduct(itemIndex, product);
                                Navigator.pop(context);
                              },
                              icon: const Icon(
                                Icons.add,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  );
                }
                if (state is ProductError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red.shade400,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Failed to load products',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.red.shade600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton(
                          onPressed: () {
                            context.read<ProductBloc>().add(LoadProducts());
                          },
                          child: const Text('Try again'),
                        ),
                      ],
                    ),
                  );
                }
                return const Center(
                  child: CircularProgressIndicator(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildManualFormField({
    required String name,
    IconData? icon,
    required String labelText,
    String? Function(String?)? validator,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return Column(
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
                labelText,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
        ] else ...[
          Text(
            labelText,
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
        Container(
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
          child: FormBuilderTextField(
            name: name,
            validator: validator,
            maxLines: maxLines,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              hintStyle: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 16,
              ),
            ),
            style: const TextStyle(
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
        ),
      ],
    );
  }

  void _saveManualItem(GlobalKey<FormBuilderState> formKey, int? editingIndex) {
    if (formKey.currentState?.saveAndValidate() ?? false) {
      final values = formKey.currentState!.value;

      final item = InvoiceItem(
        invoiceId: 0,
        name: values['name'],
        description: values['description'] ?? '',
        quantity: double.parse(values['quantity']),
        unit: values['unit'] ?? 'un',
        unitPrice: double.parse(values['unitPrice']),
        category: values['category']?.isEmpty == true ? null : values['category'],
        total: double.parse(values['quantity']) * double.parse(values['unitPrice']),
      );

      setState(() {
        if (editingIndex != null) {
          _items[editingIndex] = item;
        } else {
          _items.add(item);
        }
        _calculateTotals();
      });

      Navigator.pop(context);
    }
  }

  void _selectProduct(int? itemIndex, Product product) {
    final newItem = InvoiceItem(
      invoiceId: 0,
      productId: product.id,
      name: product.name,
      description: product.description ?? '',
      quantity: itemIndex != null ? _items[itemIndex].quantity : 1.0,
      unit: product.unit,
      unitPrice: product.price,
      category: product.category,
      total: (itemIndex != null ? _items[itemIndex].quantity : 1.0) * product.price,
    );

    setState(() {
      if (itemIndex != null) {
        _items[itemIndex] = newItem;
      } else {
        _items.add(newItem);
      }
      _calculateTotals();
    });
  }

  Future<void> _saveInvoice() async {
    if (_formKey.currentState?.saveAndValidate() ?? false) {
      final values = _formKey.currentState!.value;
      
      try {
        final invoice = Invoice(
          id: isEditing ? widget.invoice!.id : null,
          number: values['number'].toString().trim(),
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
          context.read<InvoiceBloc>().add(UpdateInvoice(invoice, _items));
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