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
      backgroundColor: Colors.grey[50],
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
    );
  }

  Widget _buildInvoiceDetails(Map<String, dynamic> details) {
    final invoiceData = details['invoice'] as Map<String, dynamic>;
    final items = (details['items'] as List).map((item) => InvoiceItem.fromMap(item)).toList();
    final invoice = Invoice.fromMap(invoiceData);
    
    return CustomScrollView(
      slivers: [
        // Custom App Bar with invoice header
        SliverAppBar(
          expandedHeight: 200,
          pinned: true,
          backgroundColor: _getStatusColor(invoice.status),
          flexibleSpace: FlexibleSpaceBar(
            background: _buildInvoiceHeader(invoice, invoiceData),
          ),
          actions: [
            PopupMenuButton<String>(
              onSelected: (value) => _handleMenuAction(value, invoice),
              icon: const Icon(Icons.more_vert, color: Colors.white),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'preview', child: Text('Preview')),
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                const PopupMenuItem(value: 'pdf', child: Text('Generate PDF')),
                const PopupMenuItem(value: 'share', child: Text('Share')),
                if (invoice.status != InvoiceStatus.paid)
                  const PopupMenuItem(value: 'mark_paid', child: Text('Mark as Paid')),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
        
        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildQuickActions(invoice),
                const SizedBox(height: 20),
                _buildClientInfo(invoiceData),
                const SizedBox(height: 20),
                _buildInvoiceItems(items),
                const SizedBox(height: 20),
                _buildInvoiceTotals(invoice),
                if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildNotesSection(invoice.notes!),
                ],
                if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildTermsSection(invoice.terms!),
                ],
                const SizedBox(height: 100), // Bottom padding
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceHeader(Invoice invoice, Map<String, dynamic> invoiceData) {    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getStatusColor(invoice.status),
            _getStatusColor(invoice.status).withOpacity(0.8),
          ],
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          invoice.type.value.toUpperCase(),
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          invoice.number,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.3)),
                    ),
                    child: Text(
                      invoice.status.value.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                NumberFormat.currency(symbol: '\$').format(invoice.total),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.calendar_today, color: Colors.white.withOpacity(0.8), size: 16),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMM dd, yyyy').format(invoice.issueDate),
                    style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                  ),
                  if (invoice.dueDate != null) ...[
                    const SizedBox(width: 20),
                    Icon(Icons.schedule, color: Colors.white.withOpacity(0.8), size: 16),
                    const SizedBox(width: 8),
                    Text(
                      'Due ${DateFormat('MMM dd').format(invoice.dueDate!)}',
                      style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 14),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildActionButton(
              'Preview',
              Icons.visibility,
              Colors.blue,
              () => _navigateToPreview(invoice),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'PDF',
              Icons.picture_as_pdf,
              Colors.red,
              () => _generatePDF(invoice),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildActionButton(
              'Share',
              Icons.share,
              Colors.green,
              () => _shareInvoice(invoice),
            ),
          ),
          if (invoice.status == InvoiceStatus.draft) ...[
            const SizedBox(width: 12),
            Expanded(
              child: _buildActionButton(
                'Send',
                Icons.send,
                Colors.orange,
                () => _markAsSent(invoice),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton(String label, IconData icon, Color color, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClientInfo(Map<String, dynamic> invoiceData) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Bill To',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[600],
                  letterSpacing: 0.5,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'CLIENT',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue[700],
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: Text(
                  (invoiceData['client_name'] ?? 'U').substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 18,
                    color: Colors.blue[700],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      invoiceData['client_name'] ?? 'Unknown Client',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (invoiceData['client_email'] != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        invoiceData['client_email'],
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          if (invoiceData['client_phone'] != null || _buildFullAddress(invoiceData).isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),
            if (invoiceData['client_phone'] != null)
              _buildContactRow(Icons.phone, invoiceData['client_phone']),
            if (_buildFullAddress(invoiceData).isNotEmpty) ...[
              const SizedBox(height: 8),
              _buildContactRow(Icons.location_on, _buildFullAddress(invoiceData)),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildContactRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInvoiceItems(List<InvoiceItem> items) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Items',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${items.length} items',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final item = entry.value;
            return _buildModernItemRow(item, index < items.length - 1);
          }),
        ],
      ),
    );
  }

  Widget _buildModernItemRow(InvoiceItem item, bool showDivider) {
    return Container(
      margin: EdgeInsets.only(bottom: showDivider ? 16 : 0),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    item.quantity.toInt().toString(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[700],
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${NumberFormat.currency(symbol: '\$').format(item.unitPrice)} each',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    NumberFormat.currency(symbol: '\$').format(item.total),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (showDivider) ...[
            const SizedBox(height: 16),
            Divider(height: 1, color: Colors.grey[200]),
          ],
        ],
      ),
    );
  }

  Widget _buildInvoiceTotals(Invoice invoice) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildModernTotalRow('Subtotal', invoice.subtotal, false),
          if (invoice.discountAmount > 0) ...[
            const SizedBox(height: 12),
            _buildModernTotalRow('Discount', -invoice.discountAmount, false),
          ],
          if (invoice.taxAmount > 0) ...[
            const SizedBox(height: 12),
            _buildModernTotalRow('Tax', invoice.taxAmount, false),
          ],
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _getStatusColor(invoice.status).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getStatusColor(invoice.status).withOpacity(0.3),
              ),
            ),
            child: _buildModernTotalRow('Total', invoice.total, true),
          ),
        ],
      ),
    );
  }

  Widget _buildModernTotalRow(String label, double amount, bool isTotal) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
            fontSize: isTotal ? 18 : 15,
            color: isTotal ? Colors.grey[800] : Colors.grey[600],
          ),
        ),
        Text(
          NumberFormat.currency(symbol: '\$').format(amount),
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: isTotal ? 20 : 15,
            color: isTotal ? Colors.green[700] : Colors.grey[800],
          ),
        ),
      ],
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