import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import '../bloc/invoice_bloc.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/pdf_service.dart';
import 'invoice_form_screen.dart';
import 'invoice_details_screen.dart';
import 'invoice_preview_screen.dart';

class InvoicesScreen extends StatefulWidget {
  const InvoicesScreen({Key? key}) : super(key: key);

  @override
  State<InvoicesScreen> createState() => _InvoicesScreenState();
}

class _InvoicesScreenState extends State<InvoicesScreen> {
  bool _showPaidOnly = false;

  @override
  void initState() {
    super.initState();
    context.read<InvoiceBloc>().add(LoadInvoices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Invoices', 
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        backgroundColor: Colors.grey.shade50,
        elevation: 0,
        toolbarHeight: 80,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToInvoiceForm(InvoiceType.invoice),
        backgroundColor: Colors.blue,
        child: const Icon(Icons.add, color: Colors.white),
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
          }
        },
        builder: (context, state) {
          if (state is InvoiceLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is InvoiceLoaded) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildFilterTabs(),
                const SizedBox(height: 24),
                _buildInvoiceRecordSection(),
                const SizedBox(height: 16),
                Expanded(
                  child: _buildInvoiceList(_getFilteredInvoices(state.invoices)),
                ),
              ],
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildFilterTabs() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _buildFilterTab('Paid', _showPaidOnly, () {
            setState(() => _showPaidOnly = true);
          }),
          const SizedBox(width: 16),
          _buildFilterTab('Unpaid', !_showPaidOnly, () {
            setState(() => _showPaidOnly = false);
          }),
        ],
      ),
    );
  }

  Widget _buildFilterTab(String text, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue : Colors.transparent,
          borderRadius: BorderRadius.circular(25),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildInvoiceRecordSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Record',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Here you will have access to all your invoices and\nbe able to manage them in the best way.',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  List<Invoice> _getFilteredInvoices(List<Invoice> invoices) {
    if (_showPaidOnly) {
      return invoices.where((invoice) => invoice.status == InvoiceStatus.paid).toList();
    } else {
      return invoices.where((invoice) => invoice.status != InvoiceStatus.paid).toList();
    }
  }

  Widget _buildInvoiceList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _buildInvoiceItem(invoice);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.receipt_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text('No invoices yet', style: TextStyle(fontSize: 18, color: Colors.grey)),
          const SizedBox(height: 8),
          const Text('Create your first invoice to get started', style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _navigateToInvoiceForm(InvoiceType.invoice),
            icon: const Icon(Icons.add),
            label: const Text('Create Invoice'),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceItem(Invoice invoice) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invoice.number,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  NumberFormat.currency(symbol: '\$').format(invoice.total),
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${invoice.dueDate != null ? DateFormat('MMM, dd').format(invoice.dueDate!) : 'No due date'}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 8),
                _buildStatusPill(invoice.status),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleInvoiceAction(value, invoice),
            icon: const Icon(Icons.more_horiz, color: Colors.grey),
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'view', child: Text('View Details')),
              const PopupMenuItem(value: 'preview', child: Text('Preview')),
              const PopupMenuItem(value: 'pdf', child: Text('Generate PDF')),
              const PopupMenuItem(value: 'share', child: Text('Share')),
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              if (invoice.type == InvoiceType.estimate)
                const PopupMenuItem(value: 'convert', child: Text('Convert to Invoice')),
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
    );
  }

  Widget _buildStatusPill(InvoiceStatus status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.value.toUpperCase(),
        style: const TextStyle(
          fontSize: 12,
          color: Colors.white,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _handleInvoiceAction(String action, Invoice invoice) {
    switch (action) {
      case 'view':
        _navigateToInvoiceDetails(invoice.id!);
        break;
      case 'preview':
        _navigateToInvoicePreview(invoice.id!);
        break;
      case 'pdf':
        _generatePDF(invoice);
        break;
      case 'share':
        _shareInvoice(invoice);
        break;
      case 'edit':
        _navigateToInvoiceForm(invoice.type, invoice: invoice);
        break;
      case 'convert':
        _showConvertDialog(invoice);
        break;
      case 'mark_paid':
        context.read<InvoiceBloc>().add(UpdateInvoiceStatus(invoice.id!, InvoiceStatus.paid));
        break;
      case 'delete':
        _showDeleteDialog(invoice);
        break;
    }
  }

  void _showConvertDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Convert to Invoice'),
        content: Text('Convert estimate ${invoice.number} to an invoice?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<InvoiceBloc>().add(ConvertEstimateToInvoice(invoice.id!));
              Navigator.pop(context);
            },
            child: const Text('Convert'),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(Invoice invoice) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Invoice'),
        content: Text('Are you sure you want to delete ${invoice.number}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              context.read<InvoiceBloc>().add(DeleteInvoice(invoice.id!));
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _navigateToInvoiceForm(InvoiceType type, {Invoice? invoice}) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceFormScreen(type: type, invoice: invoice),
      ),
    );
  }

  void _navigateToInvoiceDetails(int invoiceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoiceDetailsScreen(invoiceId: invoiceId),
      ),
    );
  }

  void _navigateToInvoicePreview(int invoiceId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => InvoicePreviewScreen(invoiceId: invoiceId),
      ),
    );
  }

  Future<void> _generatePDF(Invoice invoice) async {
    try {
      context.read<InvoiceBloc>().add(LoadInvoiceDetails(invoice.id!));
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('PDF generation will be available after loading invoice details'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error generating PDF: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _shareInvoice(Invoice invoice) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing invoice for sharing...'),
          duration: Duration(seconds: 1),
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Share feature will be available after loading invoice details'),
          backgroundColor: Colors.orange,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error sharing invoice: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}