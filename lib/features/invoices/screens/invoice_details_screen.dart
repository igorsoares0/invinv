import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/invoice_bloc.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/pdf_service.dart';
import 'invoice_form_screen.dart';
import 'invoice_preview_screen.dart';

class InvoiceDetailsScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceDetailsScreen({Key? key, required this.invoiceId}) : super(key: key);

  @override
  State<InvoiceDetailsScreen> createState() => _InvoiceDetailsScreenState();
}

class _InvoiceDetailsScreenState extends State<InvoiceDetailsScreen> {
  final PDFService _pdfService = PDFService();

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Details'),
        elevation: 0,
        actions: [
          BlocBuilder<InvoiceBloc, InvoiceState>(
            builder: (context, state) {
              if (state is InvoiceDetailsLoaded) {
                final invoiceData = state.invoiceDetails['invoice'] as Map<String, dynamic>;
                final invoice = Invoice.fromMap(invoiceData);
                
                return PopupMenuButton<String>(
                  onSelected: (value) => _handleMenuAction(value, invoice),
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'preview', child: Text('Preview')),
                    const PopupMenuItem(value: 'edit', child: Text('Edit')),
                    const PopupMenuItem(value: 'duplicate', child: Text('Duplicate')),
                    const PopupMenuItem(value: 'pdf', child: Text('Generate PDF')),
                    const PopupMenuItem(value: 'share', child: Text('Share')),
                    if (invoice.status != InvoiceStatus.paid)
                      const PopupMenuItem(value: 'mark_paid', child: Text('Mark as Paid')),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text('Delete', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                );
              }
              return const SizedBox.shrink();
            },
          ),
        ],
      ),
      body: BlocConsumer<InvoiceBloc, InvoiceState>(
        listener: (context, state) {
          if (state is InvoiceError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.red),
            );
          } else if (state is InvoiceOperationSuccess) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(state.message), backgroundColor: Colors.green),
            );
            context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId));
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoiceDetailsLoaded) {
            return _buildInvoiceDetails(state.invoiceDetails);
          }

          return const Center(child: Text('Invoice not found'));
        },
      ),
      floatingActionButton: BlocBuilder<InvoiceBloc, InvoiceState>(
        builder: (context, state) {
          if (state is InvoiceDetailsLoaded) {
            final invoiceData = state.invoiceDetails['invoice'] as Map<String, dynamic>;
            final invoice = Invoice.fromMap(invoiceData);
            
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton(
                  onPressed: () => _navigateToPreview(invoice),
                  heroTag: "preview",
                  backgroundColor: Colors.blue,
                  child: const Icon(Icons.visibility),
                ),
                const SizedBox(height: 16),
                if (invoice.status == InvoiceStatus.draft)
                  FloatingActionButton.extended(
                    onPressed: () => _markAsSent(invoice),
                    heroTag: "send",
                    icon: const Icon(Icons.send),
                    label: const Text('Send'),
                  ),
              ],
            );
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildInvoiceDetails(Map<String, dynamic> details) {
    final invoiceData = details['invoice'] as Map<String, dynamic>;
    final items = (details['items'] as List).map((item) => InvoiceItem.fromMap(item)).toList();
    
    final invoice = Invoice.fromMap(invoiceData);
    
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildInvoiceHeader(invoice, invoiceData),
          _buildClientInfo(invoiceData),
          _buildInvoiceItems(items),
          _buildInvoiceTotals(invoice),
          if (invoice.notes != null && invoice.notes!.isNotEmpty)
            _buildNotesSection(invoice.notes!),
          if (invoice.terms != null && invoice.terms!.isNotEmpty)
            _buildTermsSection(invoice.terms!),
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildInvoiceHeader(Invoice invoice, Map<String, dynamic> invoiceData) {
    Color statusColor = _getStatusColor(invoice.status);
    
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).primaryColor,
            Theme.of(context).primaryColor.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.type.value.toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    invoice.number,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  invoice.status.value.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            NumberFormat.currency(symbol: '\$').format(invoice.total),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.calendar_today, color: Colors.white70, size: 16),
              const SizedBox(width: 8),
              Text(
                'Issued: ${DateFormat('MMM dd, yyyy').format(invoice.issueDate)}',
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
          if (invoice.dueDate != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.schedule, color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Text(
                  'Due: ${DateFormat('MMM dd, yyyy').format(invoice.dueDate!)}',
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> invoiceData) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Bill To',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              invoiceData['client_name'] ?? 'Unknown Client',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            if (invoiceData['client_email'] != null)
              Text(invoiceData['client_email']),
            if (invoiceData['client_phone'] != null)
              Text(invoiceData['client_phone']),
            if (invoiceData['client_address'] != null) ...[
              const SizedBox(height: 8),
              Text(_buildFullAddress(invoiceData)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceItems(List<InvoiceItem> items) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Items',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...items.map((item) => _buildItemRow(item, items)),
          ],
        ),
      ),
    );
  }

  Widget _buildItemRow(InvoiceItem item, List<InvoiceItem> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${item.quantity} × ${NumberFormat.currency(symbol: '\$').format(item.unitPrice)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                NumberFormat.currency(symbol: '\$').format(item.total),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          if (items.indexOf(item) < items.length - 1)
            const Divider(height: 24),
        ],
      ),
    );
  }

  Widget _buildInvoiceTotals(Invoice invoice) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildTotalRow('Subtotal', invoice.subtotal),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount', -invoice.discountAmount),
            if (invoice.taxAmount > 0)
              _buildTotalRow('Tax', invoice.taxAmount),
            const Divider(height: 24),
            _buildTotalRow(
              'Total',
              invoice.total,
              isTotal: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTotalRow(String label, double amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Text(
            NumberFormat.currency(symbol: '\$').format(amount),
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Notes',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(notes),
          ],
        ),
      ),
    );
  }

  Widget _buildTermsSection(String terms) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms & Conditions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(terms),
          ],
        ),
      ),
    );
  }

  String _buildFullAddress(Map<String, dynamic> invoiceData) {
    final parts = [
      invoiceData['client_address'],
      invoiceData['client_city'],
      invoiceData['client_state'],
      invoiceData['client_zip_code'],
    ].where((part) => part != null && part.toString().isNotEmpty).toList();
    
    return parts.join(', ');
  }

  Color _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return Colors.green;
      case InvoiceStatus.sent:
        return Colors.orange;
      case InvoiceStatus.overdue:
        return Colors.red;
      case InvoiceStatus.draft:
        return Colors.grey;
      case InvoiceStatus.approved:
        return Colors.blue;
      case InvoiceStatus.rejected:
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  void _handleMenuAction(String action, Invoice invoice) {
    switch (action) {
      case 'preview':
        _navigateToPreview(invoice);
        break;
      case 'edit':
        _navigateToEdit(invoice);
        break;
      case 'duplicate':
        // TODO: Implement duplicate
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Duplicate feature coming soon')),
        );
        break;
      case 'pdf':
        _generatePDF(invoice);
        break;
      case 'share':
        _shareInvoice(invoice);
        break;
      case 'mark_paid':
        context.read<InvoiceBloc>().add(UpdateInvoiceStatus(invoice.id!, InvoiceStatus.paid));
        break;
      case 'delete':
        _showDeleteDialog(invoice);
        break;
    }
  }

  void _markAsSent(Invoice invoice) {
    context.read<InvoiceBloc>().add(UpdateInvoiceStatus(invoice.id!, InvoiceStatus.sent));
  }

  void _showDeleteDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete ${invoice.number}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              context.read<InvoiceBloc>().add(DeleteInvoice(invoice.id!));
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToPreview(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(invoiceId: invoice.id!),
      ),
    );
  }

  void _navigateToEdit(Invoice invoice) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceFormScreen(
          type: invoice.type,
          invoice: invoice,
        ),
      ),
    ).then((_) {
      context.read<InvoiceBloc>().add(LoadInvoiceDetails(widget.invoiceId));
    });
  }

  Future<void> _generatePDF(Invoice invoice) async {
    final state = context.read<InvoiceBloc>().state;
    if (state is! InvoiceDetailsLoaded) return;

    try {
      final invoiceData = state.invoiceDetails['invoice'] as Map<String, dynamic>;
      final items = (state.invoiceDetails['items'] as List)
          .map((item) => InvoiceItem.fromMap(item))
          .toList();

      await _pdfService.printInvoice(
        invoice: invoice,
        items: items,
        clientData: invoiceData,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareInvoice(Invoice invoice) async {
    final state = context.read<InvoiceBloc>().state;
    if (state is! InvoiceDetailsLoaded) return;

    try {
      final invoiceData = state.invoiceDetails['invoice'] as Map<String, dynamic>;
      final items = (state.invoiceDetails['items'] as List)
          .map((item) => InvoiceItem.fromMap(item))
          .toList();

      await _pdfService.shareInvoice(
        invoice: invoice,
        items: items,
        clientData: invoiceData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}