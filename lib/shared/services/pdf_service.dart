import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'company_service.dart';

class PDFService {
  final CompanyService _companyService = CompanyService();

  Future<Uint8List> generateInvoicePDF({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Map<String, dynamic> clientData,
  }) async {
    final pdf = pw.Document();
    final company = await _companyService.getCompany();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, company),
            pw.SizedBox(height: 32),
            _buildCompanyAndClientInfo(company, clientData),
            pw.SizedBox(height: 32),
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 32),
            _buildItemsTable(items),
            pw.SizedBox(height: 24),
            _buildTotalsSection(invoice),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 32),
              _buildNotesSection(invoice.notes!),
            ],
            if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildTermsSection(invoice.terms!),
            ],
            pw.Spacer(),
            _buildFooter(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Invoice invoice, Company? company) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              invoice.type.value.toUpperCase(),
              style: pw.TextStyle(
                fontSize: 32,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.blue700,
              ),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              invoice.number,
              style: pw.TextStyle(
                fontSize: 16,
                color: PdfColors.grey600,
              ),
            ),
          ],
        ),
        _buildCompanyLogo(company),
      ],
    );
  }

  pw.Widget _buildCompanyLogo(Company? company) {
    if (company?.logoPath != null &&
        company!.logoPath!.isNotEmpty &&
        File(company.logoPath!).existsSync()) {
      try {
        final logoBytes = File(company.logoPath!).readAsBytesSync();
        final logoImage = pw.MemoryImage(logoBytes);

        return pw.Container(
          width: 100,
          height: 100,
          decoration: pw.BoxDecoration(
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Image(
            logoImage,
            fit: pw.BoxFit.contain,
          ),
        );
      } catch (e) {
        // Fallback to text logo if image fails to load
        return _buildTextLogo(company);
      }
    } else if (company?.name != null) {
      return _buildTextLogo(company!);
    }

    return pw.SizedBox(width: 100, height: 100);
  }

  pw.Widget _buildTextLogo(Company company) {
    return pw.Container(
      width: 100,
      height: 100,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: pw.BorderRadius.circular(8),
      ),
      child: pw.Center(
        child: pw.Text(
          company.name.substring(0, 1).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 36,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildCompanyAndClientInfo(Company? company, Map<String, dynamic> clientData) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'From:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                company?.name ?? 'Your Company Name',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (company?.address != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(company!.address!),
              ],
              if (company?.phone != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Phone: ${company!.phone!}'),
              ],
              if (company?.email != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Email: ${company!.email!}'),
              ],
              if (company?.taxId != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Tax ID: ${company!.taxId!}'),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 32),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Bill To:',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                clientData['client_name'] ?? 'Unknown Client',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              if (clientData['client_email'] != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(clientData['client_email']),
              ],
              if (clientData['client_phone'] != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(clientData['client_phone']),
              ],
              if (clientData['client_address'] != null) ...[
                pw.SizedBox(height: 2),
                pw.Text(_buildFullAddress(clientData)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildInvoiceDetails(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Issue Date:', DateFormat('MMM dd, yyyy').format(invoice.issueDate)),
            if (invoice.dueDate != null) ...[
              pw.SizedBox(height: 4),
              _buildDetailRow(
                invoice.type == InvoiceType.estimate ? 'Valid Until:' : 'Due Date:',
                DateFormat('MMM dd, yyyy').format(invoice.dueDate!),
              ),
            ],
          ],
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: pw.BoxDecoration(
            color: _getStatusColor(invoice.status),
            borderRadius: pw.BorderRadius.circular(16),
          ),
          child: pw.Text(
            invoice.status.value.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(value),
      ],
    );
  }

  pw.Widget _buildItemsTable(List<InvoiceItem> items) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: PdfColors.grey100),
          children: [
            _buildTableCell('Description', isHeader: true),
            _buildTableCell('Qty', isHeader: true, alignment: pw.Alignment.center),
            _buildTableCell('Rate', isHeader: true, alignment: pw.Alignment.centerRight),
            _buildTableCell('Amount', isHeader: true, alignment: pw.Alignment.centerRight),
          ],
        ),
        // Items
        ...items.map((item) => pw.TableRow(
          children: [
            _buildTableCell(item.description),
            _buildTableCell(item.quantity.toString(), alignment: pw.Alignment.center),
            _buildTableCell(NumberFormat.currency(symbol: '\$').format(item.unitPrice), alignment: pw.Alignment.centerRight),
            _buildTableCell(NumberFormat.currency(symbol: '\$').format(item.total), alignment: pw.Alignment.centerRight),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildTableCell(String text, {bool isHeader = false, pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
        ),
      ),
    );
  }

  pw.Widget _buildTotalsSection(Invoice invoice) {
    return pw.Row(
      children: [
        pw.Spacer(flex: 2),
        pw.Expanded(
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', NumberFormat.currency(symbol: '\$').format(invoice.subtotal)),
              if (invoice.discountAmount > 0)
                _buildTotalRow('Discount:', '-${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}'),
              if (invoice.taxAmount > 0)
                _buildTotalRow('Tax:', NumberFormat.currency(symbol: '\$').format(invoice.taxAmount)),
              pw.Divider(color: PdfColors.blue700, thickness: 2),
              _buildTotalRow(
                'Total:',
                NumberFormat.currency(symbol: '\$').format(invoice.total),
                isTotal: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String amount, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? PdfColors.blue700 : PdfColors.black,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? PdfColors.blue700 : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildNotesSection(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Notes:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          notes,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildTermsSection(String terms) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'Terms & Conditions:',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Text(
          terms,
          style: const pw.TextStyle(fontSize: 10),
        ),
      ],
    );
  }

  pw.Widget _buildFooter() {
    return pw.Center(
      child: pw.Text(
        'Thank you for your business!',
        style: pw.TextStyle(
          fontSize: 14,
          color: PdfColors.grey600,
          fontStyle: pw.FontStyle.italic,
        ),
      ),
    );
  }

  String _buildFullAddress(Map<String, dynamic> clientData) {
    final parts = [
      clientData['client_address'],
      clientData['client_city'],
      clientData['client_state'],
      clientData['client_zip_code'],
    ].where((part) => part != null && part.toString().isNotEmpty).toList();
    
    return parts.join(', ');
  }

  PdfColor _getStatusColor(InvoiceStatus status) {
    switch (status) {
      case InvoiceStatus.paid:
        return PdfColors.green700;
      case InvoiceStatus.sent:
        return PdfColors.orange700;
      case InvoiceStatus.overdue:
        return PdfColors.red700;
      case InvoiceStatus.draft:
        return PdfColors.grey600;
      case InvoiceStatus.approved:
        return PdfColors.blue700;
      case InvoiceStatus.rejected:
        return PdfColors.red700;
      default:
        return PdfColors.grey600;
    }
  }

  Future<void> printInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Map<String, dynamic> clientData,
  }) async {
    final pdfData = await generateInvoicePDF(
      invoice: invoice,
      items: items,
      clientData: clientData,
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfData,
      name: '${invoice.number}.pdf',
    );
  }

  Future<void> shareInvoice({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Map<String, dynamic> clientData,
  }) async {
    final pdfData = await generateInvoicePDF(
      invoice: invoice,
      items: items,
      clientData: clientData,
    );

    await Printing.sharePdf(
      bytes: pdfData,
      filename: '${invoice.number}.pdf',
    );
  }
}