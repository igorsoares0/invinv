import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../shared/models/models.dart';
import '../../../shared/services/company_service.dart';
import '../../../shared/services/pdf_service.dart';
import '../../../shared/services/invoice_service.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final int invoiceId;

  const InvoicePreviewScreen({Key? key, required this.invoiceId}) : super(key: key);

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen> {
  final CompanyService _companyService = CompanyService();
  final PDFService _pdfService = PDFService();
  final InvoiceService _invoiceService = InvoiceService();
  
  Company? _company;
  Map<String, dynamic>? _invoiceDetails;
  bool _isGeneratingPdf = false;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      final results = await Future.wait([
        _companyService.getCompany(),
        _invoiceService.getInvoiceWithDetails(widget.invoiceId),
      ]);

      setState(() {
        _company = results[0] as Company?;
        _invoiceDetails = results[1] as Map<String, dynamic>?;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Error loading invoice: ${e.toString()}';
        _isLoading = false;
      });
    }
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Preview'),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        actions: [
          TextButton.icon(
            onPressed: _isGeneratingPdf ? null : () => _generatePDF(),
            icon: _isGeneratingPdf 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.picture_as_pdf),
            label: Text(_isGeneratingPdf ? 'Generating...' : 'Generate PDF'),
          ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleMenuAction(value),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'share',
                child: ListTile(
                  leading: Icon(Icons.share),
                  title: Text('Share'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'email',
                child: ListTile(
                  leading: Icon(Icons.email),
                  title: Text('Send by Email'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'print',
                child: ListTile(
                  leading: Icon(Icons.print),
                  title: Text('Print'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(_errorMessage!),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_invoiceDetails == null) {
      return const Center(child: Text('Invoice not found'));
    }

    return _buildPreview(_invoiceDetails!);
  }

  Widget _buildPreview(Map<String, dynamic> details) {
    final invoiceData = details['invoice'] as Map<String, dynamic>;
    final items = (details['items'] as List).map((item) => InvoiceItem.fromMap(item)).toList();
    final invoice = Invoice.fromMap(invoiceData);

    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Container(
          width: MediaQuery.of(context).size.width * 0.9,
          constraints: const BoxConstraints(maxWidth: 600),
          margin: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            child: Container(
              padding: const EdgeInsets.all(32),
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.all(Radius.circular(8)),
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(invoice),
                    const SizedBox(height: 32),
                    _buildCompanyInfo(),
                    const SizedBox(height: 32),
                    _buildInvoiceInfo(invoice, invoiceData),
                    const SizedBox(height: 32),
                    _buildItemsTable(items),
                    const SizedBox(height: 24),
                    _buildTotalsSection(invoice),
                    if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
                      const SizedBox(height: 32),
                      _buildNotesSection(invoice.notes!),
                    ],
                    if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _buildTermsSection(invoice.terms!),
                    ],
                    const SizedBox(height: 32),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(Invoice invoice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              invoice.type.value.toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invoice.number,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ],
        ),
        if (_company?.logoPath != null)
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Icon(
                Icons.business,
                size: 40,
                color: Colors.grey,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildCompanyInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _company?.name ?? 'Your Company Name',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (_company?.address != null) Text(_company!.address!),
        if (_company?.phone != null) Text('Phone: ${_company!.phone!}'),
        if (_company?.email != null) Text('Email: ${_company!.email!}'),
        if (_company?.website != null) Text('Website: ${_company!.website!}'),
        if (_company?.taxId != null) Text('Tax ID: ${_company!.taxId!}'),
      ],
    );
  }

  Widget _buildInvoiceInfo(Invoice invoice, Map<String, dynamic> invoiceData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Bill To:',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                invoiceData['client_name'] ?? 'Unknown Client',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (invoiceData['client_email'] != null)
                Text(invoiceData['client_email']),
              if (invoiceData['client_phone'] != null)
                Text(invoiceData['client_phone']),
              if (invoiceData['client_address'] != null) ...[
                const SizedBox(height: 4),
                Text(_buildFullAddress(invoiceData)),
              ],
            ],
          ),
        ),
        const SizedBox(width: 32),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildInfoRow('Issue Date:', DateFormat('MMM dd, yyyy').format(invoice.issueDate)),
            const SizedBox(height: 4),
            if (invoice.dueDate != null)
              _buildInfoRow(
                invoice.type == InvoiceType.estimate ? 'Valid Until:' : 'Due Date:',
                DateFormat('MMM dd, yyyy').format(invoice.dueDate!),
              ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: _getStatusColor(invoice.status).withOpacity(0.1),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _getStatusColor(invoice.status)),
              ),
              child: Text(
                invoice.status.value.toUpperCase(),
                style: TextStyle(
                  color: _getStatusColor(invoice.status),
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
            color: Colors.grey,
          ),
        ),
        const SizedBox(width: 8),
        Text(value),
      ],
    );
  }

  Widget _buildItemsTable(List<InvoiceItem> items) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: const Row(
            children: [
              Expanded(flex: 3, child: Text('Description', style: TextStyle(fontWeight: FontWeight.bold))),
              Expanded(child: Text('Qty', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              Expanded(child: Text('Rate', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
              Expanded(child: Text('Amount', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.right)),
            ],
          ),
        ),
        ...items.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: Colors.grey[300]!),
                right: BorderSide(color: Colors.grey[300]!),
                bottom: BorderSide(color: Colors.grey[300]!),
              ),
              color: index.isEven ? Colors.white : Colors.grey[25],
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(item.description),
                ),
                Expanded(
                  child: Text(
                    item.quantity.toString(),
                    textAlign: TextAlign.center,
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.currency(symbol: '\$').format(item.unitPrice),
                    textAlign: TextAlign.right,
                  ),
                ),
                Expanded(
                  child: Text(
                    NumberFormat.currency(symbol: '\$').format(item.total),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTotalsSection(Invoice invoice) {
    return Column(
      children: [
        const SizedBox(height: 16),
        Row(
          children: [
            const Spacer(flex: 2),
            Expanded(
              child: Column(
                children: [
                  _buildTotalRow('Subtotal:', NumberFormat.currency(symbol: '\$').format(invoice.subtotal)),
                  if (invoice.discountAmount > 0)
                    _buildTotalRow('Discount:', '-${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}'),
                  if (invoice.taxAmount > 0)
                    _buildTotalRow('Tax:', NumberFormat.currency(symbol: '\$').format(invoice.taxAmount)),
                  const Divider(thickness: 2, color: Colors.blue),
                  _buildTotalRow(
                    'Total:',
                    NumberFormat.currency(symbol: '\$').format(invoice.total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTotalRow(String label, String amount, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 18 : 14,
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(String notes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Notes:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(notes),
      ],
    );
  }

  Widget _buildTermsSection(String terms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Terms & Conditions:',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          terms,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Center(
      child: Text(
        'Thank you for your business!',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontStyle: FontStyle.italic,
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

  void _handleMenuAction(String action) {
    switch (action) {
      case 'share':
        _shareInvoice();
        break;
      case 'email':
        _sendByEmail();
        break;
      case 'print':
        _printInvoice();
        break;
    }
  }

  Future<void> _generatePDF() async {
    if (_invoiceDetails == null) return;

    setState(() => _isGeneratingPdf = true);

    try {
      final invoiceData = _invoiceDetails!['invoice'] as Map<String, dynamic>;
      final items = (_invoiceDetails!['items'] as List)
          .map((item) => InvoiceItem.fromMap(item))
          .toList();

      final invoice = Invoice.fromMap(invoiceData);

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
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  Future<void> _shareInvoice() async {
    if (_invoiceDetails == null) return;

    try {
      final invoiceData = _invoiceDetails!['invoice'] as Map<String, dynamic>;
      final items = (_invoiceDetails!['items'] as List)
          .map((item) => InvoiceItem.fromMap(item))
          .toList();

      final invoice = Invoice.fromMap(invoiceData);

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

  void _sendByEmail() {
    // TODO: Implement email sending with attachment
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Email functionality coming soon!'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Future<void> _printInvoice() async {
    if (_invoiceDetails == null) return;

    try {
      final invoiceData = _invoiceDetails!['invoice'] as Map<String, dynamic>;
      final items = (_invoiceDetails!['items'] as List)
          .map((item) => InvoiceItem.fromMap(item))
          .toList();

      final invoice = Invoice.fromMap(invoiceData);

      await _pdfService.printInvoice(
        invoice: invoice,
        items: items,
        clientData: invoiceData,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error printing invoice: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}