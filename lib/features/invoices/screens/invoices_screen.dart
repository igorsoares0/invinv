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

class _InvoicesScreenState extends State<InvoicesScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    context.read<InvoiceBloc>().add(LoadInvoices());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Invoices'),
            Tab(text: 'Estimates'),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'new_invoice',
                child: ListTile(
                  leading: Icon(Icons.receipt_long),
                  title: Text('New Invoice'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'new_estimate',
                child: ListTile(
                  leading: Icon(Icons.description),
                  title: Text('New Estimate'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _navigateToInvoiceForm(InvoiceType.invoice),
        child: const Icon(Icons.add),
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
            return TabBarView(
              controller: _tabController,
              children: [
                _buildInvoiceList(state.invoices),
                _buildInvoiceList(state.invoices.where((i) => i.type == InvoiceType.invoice).toList()),
                _buildInvoiceList(state.invoices.where((i) => i.type == InvoiceType.estimate).toList()),
              ],
            );
          }

          return const Center(child: Text('Something went wrong'));
        },
      ),
    );
  }

  Widget _buildInvoiceList(List<Invoice> invoices) {
    if (invoices.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        return _buildInvoiceCard(invoice);
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

  Widget _buildInvoiceCard(Invoice invoice) {
    Color statusColor = _getStatusColor(invoice.status);
    IconData typeIcon = invoice.type == InvoiceType.invoice 
        ? Icons.receipt_long 
        : invoice.type == InvoiceType.estimate 
          ? Icons.description 
          : Icons.receipt;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: statusColor.withOpacity(0.1),
          child: Icon(typeIcon, color: statusColor),
        ),
        title: Text(
          invoice.number,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${NumberFormat.currency(symbol: '\$').format(invoice.total)}'),
            Text('Due: ${invoice.dueDate != null ? DateFormat('MMM dd, yyyy').format(invoice.dueDate!) : 'No due date'}'),
            const SizedBox(height: 4),
            _buildStatusChip(invoice.status),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) => _handleInvoiceAction(value, invoice),
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
        onTap: () => _navigateToInvoiceDetails(invoice.id!),
      ),
    );
  }

  Widget _buildStatusChip(InvoiceStatus status) {
    Color color = _getStatusColor(status);
    String label = status.value.toUpperCase();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'new_invoice':
        _navigateToInvoiceForm(InvoiceType.invoice);
        break;
      case 'new_estimate':
        _navigateToInvoiceForm(InvoiceType.estimate);
        break;
    }
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
      // First we need to get the invoice details with items and client data
      context.read<InvoiceBloc>().add(LoadInvoiceDetails(invoice.id!));
      
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Generating PDF...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Note: In a real implementation, you would need to fetch the details first
      // For now, we'll show a placeholder message
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
      // Show loading message
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preparing invoice for sharing...'),
          duration: Duration(seconds: 1),
        ),
      );

      // Note: In a real implementation, you would need to fetch the details first
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