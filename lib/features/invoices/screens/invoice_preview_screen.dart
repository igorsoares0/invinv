import 'dart:io';
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
    try {
      final invoiceData = details['invoice'] as Map<String, dynamic>;
      final items = (details['items'] as List).map((item) => InvoiceItem.fromMap(item)).toList();
      final invoice = Invoice.fromMap(invoiceData);

      return Container(
        color: Colors.grey[100],
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: Card(
                elevation: 8,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 600,
                    minWidth: 400,
                  ),
                  child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.all(Radius.circular(8)),
                  ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(invoice),
                    const SizedBox(height: 32),
                    _buildCompanyAndClientInfo(invoiceData),
                    const SizedBox(height: 32),
                    _buildInvoiceDetails(invoice),
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
                    const SizedBox(height: 20),
                    _buildFooter(),
                  ],
                ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } catch (e) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text('Error building preview: ${e.toString()}'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }
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
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.blue,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              invoice.number,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        _buildCompanyLogo(),
      ],
    );
  }

  Widget _buildCompanyLogo() {
    if (_company?.logoPath != null &&
        _company!.logoPath!.isNotEmpty &&
        File(_company!.logoPath!).existsSync()) {
      try {
        return Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              File(_company!.logoPath!),
              fit: BoxFit.contain,
            ),
          ),
        );
      } catch (e) {
        return _buildTextLogo();
      }
    } else if (_company?.name != null) {
      return _buildTextLogo();
    }

    return const SizedBox(width: 80, height: 80);
  }

  Widget _buildTextLogo() {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: _company?.name != null
            ? Text(
                _company!.name.substring(0, 1).toUpperCase(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              )
            : const Icon(
                Icons.business,
                size: 30,
                color: Colors.grey,
              ),
      ),
    );
  }

  Widget _buildCompanyAndClientInfo(Map<String, dynamic> invoiceData) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _company?.name ?? 'Your Company Name',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (_company?.address != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _company!.address!,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (_company?.phone != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Phone: ${_company!.phone!}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (_company?.email != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Email: ${_company!.email!}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (_company?.taxId != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Tax ID: ${_company!.taxId!}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (_company?.website != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Website: ${_company!.website!}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 32),
          Flexible(
            flex: 1,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bill To:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  invoiceData['client_name'] ?? 'Unknown Client',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (invoiceData['client_email'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    invoiceData['client_email'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (invoiceData['client_phone'] != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    invoiceData['client_phone'],
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
                if (invoiceData['client_address'] != null) ...[
                  const SizedBox(height: 2),
                  Text(_buildFullAddress(invoiceData)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceDetails(Invoice invoice) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow('Issue Date:', DateFormat('MMM dd, yyyy').format(invoice.issueDate)),
              if (invoice.dueDate != null) ...[
                const SizedBox(height: 4),
                _buildDetailRow(
                  invoice.type == InvoiceType.estimate ? 'Valid Until:' : 'Due Date:',
                  DateFormat('MMM dd, yyyy').format(invoice.dueDate!),
                ),
              ],
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: _getStatusColor(invoice.status),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            invoice.status.value.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
            fontSize: 12,
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildItemsTable(List<InvoiceItem> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Table(
          border: TableBorder.all(color: Colors.grey[300]!),
          columnWidths: const {
            0: FlexColumnWidth(3),
            1: FlexColumnWidth(1),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(1.5),
          },
          children: [
            // Header
            TableRow(
              decoration: BoxDecoration(color: Colors.grey[100]),
              children: [
                _buildTableCell('Product/Service', isHeader: true),
                _buildTableCell('Qty', isHeader: true, alignment: Alignment.center),
                _buildTableCell('Rate', isHeader: true, alignment: Alignment.centerRight),
                _buildTableCell('Amount', isHeader: true, alignment: Alignment.centerRight),
              ],
            ),
            // Items
            ...items.map((item) => TableRow(
              children: [
                _buildProductCell(item),
                _buildTableCell(item.quantity.toString(), alignment: Alignment.center),
                _buildTableCell(NumberFormat.currency(symbol: '\$').format(item.unitPrice), alignment: Alignment.centerRight),
                _buildTableCell(NumberFormat.currency(symbol: '\$').format(item.total), alignment: Alignment.centerRight),
              ],
            )),
          ],
        );
      },
    );
  }

  Widget _buildTableCell(String text, {bool isHeader = false, Alignment? alignment}) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: alignment ?? Alignment.centerLeft,
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
      ),
    );
  }

  Widget _buildProductCell(InvoiceItem item) {
    return Container(
      padding: const EdgeInsets.all(12),
      alignment: Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            item.name,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 11,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(
              item.description,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
          if (item.category != null && item.category!.isNotEmpty) ...[
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.blue.shade200, width: 0.5),
              ),
              child: Text(
                item.category!,
                style: TextStyle(
                  fontSize: 9,
                  color: Colors.blue.shade700,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalsSection(Invoice invoice) {
    return Align(
      alignment: Alignment.centerRight,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 200),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildTotalRow('Subtotal:', NumberFormat.currency(symbol: '\$').format(invoice.subtotal)),
            if (invoice.discountAmount > 0)
              _buildTotalRow('Discount:', '-${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}'),
            if (invoice.taxAmount > 0)
              _buildTotalRow('Tax:', NumberFormat.currency(symbol: '\$').format(invoice.taxAmount)),
            const Divider(color: Colors.blue, thickness: 2),
            _buildTotalRow(
              'Total:',
              NumberFormat.currency(symbol: '\$').format(invoice.total),
              isTotal: true,
            ),
          ],
        ),
      ),
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
              fontSize: isTotal ? 14 : 12,
              color: isTotal ? Colors.blue : Colors.black,
            ),
          ),
          Text(
            amount,
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
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
        Text(
          'Notes:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          notes,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildTermsSection(String terms) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Terms & Conditions:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          terms,
          style: const TextStyle(fontSize: 11),
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