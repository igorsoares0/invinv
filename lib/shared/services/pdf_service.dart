import 'dart:typed_data';
import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../models/models.dart';
import 'company_service.dart';
import 'template_service.dart';

class PDFService {
  final CompanyService _companyService = CompanyService();
  final TemplateService _templateService = TemplateService();

  Future<Uint8List> generateInvoicePDF({
    required Invoice invoice,
    required List<InvoiceItem> items,
    required Map<String, dynamic> clientData,
  }) async {
    final pdf = pw.Document();
    final company = await _companyService.getCompany();
    final templateType = await _templateService.getSelectedTemplate();

    if (templateType == InvoiceTemplateType.modern) {
      return _generateModernTemplate(pdf, invoice, items, clientData, company);
    } else if (templateType == InvoiceTemplateType.elegant) {
      return _generateElegantTemplate(pdf, invoice, items, clientData, company);
    } else {
      return _generateClassicTemplate(pdf, invoice, items, clientData, company);
    }
  }

  Future<Uint8List> _generateClassicTemplate(
    pw.Document pdf,
    Invoice invoice,
    List<InvoiceItem> items,
    Map<String, dynamic> clientData,
    Company? company,
  ) async {
    // Get custom color for classic template
    final customColor = await _templateService.getClassicTemplateColor();
    final pdfColor = PdfColor(
      (customColor.r * 255.0).round() / 255.0,
      (customColor.g * 255.0).round() / 255.0,
      (customColor.b * 255.0).round() / 255.0,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context context) {
          return [
            _buildHeader(invoice, company, pdfColor),
            pw.SizedBox(height: 32),
            _buildCompanyAndClientInfo(company, clientData),
            pw.SizedBox(height: 32),
            _buildInvoiceDetails(invoice),
            pw.SizedBox(height: 32),
            _buildItemsTable(items),
            pw.SizedBox(height: 24),
            _buildTotalsSection(invoice, pdfColor),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 32),
              _buildNotesSection(invoice.notes!),
            ],
            if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildTermsSection(invoice.terms!),
            ],
            pw.Spacer(),
            _buildWatermark(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _generateModernTemplate(
    pw.Document pdf,
    Invoice invoice,
    List<InvoiceItem> items,
    Map<String, dynamic> clientData,
    Company? company,
  ) async {
    // Get custom color for modern template
    final customColor = await _templateService.getModernTemplateColor();
    final pdfColor = PdfColor(
      (customColor.r * 255.0).round() / 255.0,
      (customColor.g * 255.0).round() / 255.0,
      (customColor.b * 255.0).round() / 255.0,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context context) {
          return [
            _buildModernHeader(invoice, company, pdfColor),
            pw.SizedBox(height: 24),
            _buildModernCompanyAndClientInfo(company, clientData, pdfColor),
            pw.SizedBox(height: 24),
            _buildModernInvoiceDetails(invoice, pdfColor),
            pw.SizedBox(height: 24),
            _buildModernItemsTable(items, pdfColor),
            pw.SizedBox(height: 20),
            _buildModernTotalsSection(invoice, pdfColor),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildModernNotesSection(invoice.notes!),
            ],
            if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _buildModernTermsSection(invoice.terms!),
            ],
            pw.Spacer(),
            _buildWatermark(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> _generateElegantTemplate(
    pw.Document pdf,
    Invoice invoice,
    List<InvoiceItem> items,
    Map<String, dynamic> clientData,
    Company? company,
  ) async {
    // Get custom color for elegant template
    final customColor = await _templateService.getElegantTemplateColor();
    final pdfColor = PdfColor(
      (customColor.r * 255.0).round() / 255.0,
      (customColor.g * 255.0).round() / 255.0,
      (customColor.b * 255.0).round() / 255.0,
    );
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return [
            _buildElegantHeader(invoice, company, pdfColor),
            pw.SizedBox(height: 28),
            _buildElegantCompanyAndClientInfo(company, clientData),
            pw.SizedBox(height: 28),
            _buildElegantInvoiceDetails(invoice),
            pw.SizedBox(height: 28),
            _buildElegantItemsTable(items, pdfColor),
            pw.SizedBox(height: 24),
            _buildElegantTotalsSection(invoice, pdfColor),
            if (invoice.notes != null && invoice.notes!.isNotEmpty) ...[
              pw.SizedBox(height: 28),
              _buildElegantNotesSection(invoice.notes!),
            ],
            if (invoice.terms != null && invoice.terms!.isNotEmpty) ...[
              pw.SizedBox(height: 24),
              _buildElegantTermsSection(invoice.terms!),
            ],
            pw.Spacer(),
            _buildWatermark(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(Invoice invoice, Company? company, [PdfColor? customColor]) {
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
                color: customColor ?? PdfColors.blue700,
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
        _buildCompanyLogo(company, customColor),
      ],
    );
  }

  pw.Widget _buildCompanyLogo(Company? company, [PdfColor? customColor]) {
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
        return _buildTextLogo(company, customColor);
      }
    } else if (company?.name != null) {
      return _buildTextLogo(company!, customColor);
    }

    return pw.SizedBox(width: 100, height: 100);
  }

  pw.Widget _buildTextLogo(Company company, [PdfColor? customColor]) {
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
            color: customColor ?? PdfColors.blue700,
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
              if (company?.website != null) ...[
                pw.SizedBox(height: 2),
                pw.Text('Website: ${company!.website!}'),
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
            _buildTableCell('Product/Service', isHeader: true),
            _buildTableCell('Qty', isHeader: true, alignment: pw.Alignment.center),
            _buildTableCell('Rate', isHeader: true, alignment: pw.Alignment.centerRight),
            _buildTableCell('Amount', isHeader: true, alignment: pw.Alignment.centerRight),
          ],
        ),
        // Items
        ...items.map((item) => pw.TableRow(
          children: [
            _buildProductCell(item),
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

  pw.Widget _buildProductCell(InvoiceItem item) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            item.name,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Text(
              item.description,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
          if (item.category != null && item.category!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.blue50,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.blue200, width: 0.5),
              ),
              child: pw.Text(
                item.category!,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.blue700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildTotalsSection(Invoice invoice, [PdfColor? customColor]) {
    return pw.Row(
      children: [
        pw.Spacer(flex: 2),
        pw.Expanded(
          child: pw.Column(
            children: [
              _buildTotalRow('Subtotal:', NumberFormat.currency(symbol: '\$').format(invoice.subtotal), customColor: customColor),
              if (invoice.discountAmount > 0)
                _buildTotalRow('Discount:', '-${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}', customColor: customColor),
              if (invoice.taxAmount > 0)
                _buildTotalRow('Tax:', NumberFormat.currency(symbol: '\$').format(invoice.taxAmount), customColor: customColor),
              pw.Divider(color: customColor ?? PdfColors.blue700, thickness: 2),
              _buildTotalRow(
                'Total:',
                NumberFormat.currency(symbol: '\$').format(invoice.total),
                isTotal: true,
                customColor: customColor,
              ),
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTotalRow(String label, String amount, {bool isTotal = false, PdfColor? customColor}) {
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
              color: isTotal ? (customColor ?? PdfColors.blue700) : PdfColors.black,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? (customColor ?? PdfColors.blue700) : PdfColors.black,
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

  // Modern Template Methods
  pw.Widget _buildModernHeader(Invoice invoice, Company? company, [PdfColor? customColor]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(24),
      decoration: pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [customColor ?? PdfColors.blue600, (customColor ?? PdfColors.blue800)],
        ),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                invoice.type.value.toUpperCase(),
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                invoice.number,
                style: pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.blue100,
                ),
              ),
            ],
          ),
          _buildModernCompanyLogo(company, customColor),
        ],
      ),
    );
  }

  pw.Widget _buildModernCompanyAndClientInfo(Company? company, Map<String, dynamic> clientData, [PdfColor? customColor]) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey200),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'From:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: customColor ?? PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  company?.name ?? 'Your Company Name',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (company?.address != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(company!.address!, style: const pw.TextStyle(fontSize: 12)),
                ],
                if (company?.phone != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Phone: ${company!.phone!}', style: const pw.TextStyle(fontSize: 12)),
                ],
                if (company?.email != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Email: ${company!.email!}', style: const pw.TextStyle(fontSize: 12)),
                ],
                if (company?.taxId != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Tax ID: ${company!.taxId!}', style: const pw.TextStyle(fontSize: 12)),
                ],
                if (company?.website != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text('Website: ${company!.website!}', style: const pw.TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
        pw.SizedBox(width: 20),
        pw.Expanded(
          child: pw.Container(
            padding: const pw.EdgeInsets.all(20),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey50,
              borderRadius: pw.BorderRadius.circular(8),
              border: pw.Border.all(color: PdfColors.grey300),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  'Bill To:',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: customColor ?? PdfColors.blue700,
                  ),
                ),
                pw.SizedBox(height: 12),
                pw.Text(
                  clientData['client_name'] ?? 'Unknown Client',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                if (clientData['client_email'] != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(clientData['client_email'], style: const pw.TextStyle(fontSize: 12)),
                ],
                if (clientData['client_phone'] != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(clientData['client_phone'], style: const pw.TextStyle(fontSize: 12)),
                ],
                if (clientData['client_address'] != null) ...[
                  pw.SizedBox(height: 4),
                  pw.Text(_buildFullAddress(clientData), style: const pw.TextStyle(fontSize: 12)),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildModernInvoiceDetails(Invoice invoice, [PdfColor? customColor]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildModernDetailRow('Issue Date:', DateFormat('MMM dd, yyyy').format(invoice.issueDate), customColor),
              if (invoice.dueDate != null) ...[
                pw.SizedBox(height: 8),
                _buildModernDetailRow(
                  invoice.type == InvoiceType.estimate ? 'Valid Until:' : 'Due Date:',
                  DateFormat('MMM dd, yyyy').format(invoice.dueDate!),
                  customColor,
                ),
              ],
            ],
          ),
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: pw.BoxDecoration(
              color: _getStatusColor(invoice.status),
              borderRadius: pw.BorderRadius.circular(20),
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
      ),
    );
  }

  pw.Widget _buildModernDetailRow(String label, String value, [PdfColor? customColor]) {
    return pw.Row(
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontWeight: pw.FontWeight.bold,
            color: customColor ?? PdfColors.blue700,
            fontSize: 12,
          ),
        ),
        pw.SizedBox(width: 8),
        pw.Text(
          value,
          style: const pw.TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  pw.Widget _buildModernItemsTable(List<InvoiceItem> items, [PdfColor? customColor]) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Table(
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
            decoration: pw.BoxDecoration(
              gradient: pw.LinearGradient(
                colors: [customColor ?? PdfColors.blue600, customColor ?? PdfColors.blue700],
              ),
            ),
            children: [
              _buildModernTableCell('Product/Service', isHeader: true),
              _buildModernTableCell('Qty', isHeader: true, alignment: pw.Alignment.center),
              _buildModernTableCell('Rate', isHeader: true, alignment: pw.Alignment.centerRight),
              _buildModernTableCell('Amount', isHeader: true, alignment: pw.Alignment.centerRight),
            ],
          ),
          // Items
          ...items.asMap().entries.map((entry) => pw.TableRow(
            decoration: pw.BoxDecoration(
              color: entry.key % 2 == 0 ? PdfColors.white : PdfColors.grey50,
            ),
            children: [
              _buildModernProductCell(entry.value, customColor),
              _buildModernTableCell(entry.value.quantity.toString(), alignment: pw.Alignment.center),
              _buildModernTableCell(NumberFormat.currency(symbol: '\$').format(entry.value.unitPrice), alignment: pw.Alignment.centerRight),
              _buildModernTableCell(NumberFormat.currency(symbol: '\$').format(entry.value.total), alignment: pw.Alignment.centerRight),
            ],
          )),
        ],
      ),
    );
  }

  pw.Widget _buildModernTableCell(String text, {bool isHeader = false, pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 12 : 11,
          color: isHeader ? PdfColors.white : PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildModernProductCell(InvoiceItem item, [PdfColor? customColor]) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            item.name,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: customColor ?? PdfColors.blue800,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              item.description,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
          if (item.category != null && item.category!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                color: PdfColors.orange100,
                borderRadius: pw.BorderRadius.circular(4),
                border: pw.Border.all(color: PdfColors.orange300, width: 0.5),
              ),
              child: pw.Text(
                item.category!,
                style: pw.TextStyle(
                  fontSize: 9,
                  color: PdfColors.orange700,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildModernTotalsSection(Invoice invoice, [PdfColor? customColor]) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 250,
        padding: const pw.EdgeInsets.all(20),
        decoration: pw.BoxDecoration(
          color: PdfColors.grey50,
          borderRadius: pw.BorderRadius.circular(8),
          border: pw.Border.all(color: PdfColors.grey300),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            _buildModernTotalRow('Subtotal:', NumberFormat.currency(symbol: '\$').format(invoice.subtotal), customColor: customColor),
            if (invoice.discountAmount > 0)
              _buildModernTotalRow('Discount:', '-${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}', customColor: customColor),
            if (invoice.taxAmount > 0)
              _buildModernTotalRow('Tax:', NumberFormat.currency(symbol: '\$').format(invoice.taxAmount), customColor: customColor),
            pw.Container(
              margin: const pw.EdgeInsets.symmetric(vertical: 8),
              height: 2,
              decoration: pw.BoxDecoration(
                gradient: pw.LinearGradient(
                  colors: [customColor ?? PdfColors.blue400, customColor ?? PdfColors.blue600],
                ),
              ),
            ),
            _buildModernTotalRow(
              'Total:',
              NumberFormat.currency(symbol: '\$').format(invoice.total),
              isTotal: true,
              customColor: customColor,
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildModernTotalRow(String label, String amount, {bool isTotal = false, PdfColor? customColor}) {
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
              color: isTotal ? (customColor ?? PdfColors.blue700) : PdfColors.black,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 16 : 14,
              color: isTotal ? (customColor ?? PdfColors.blue700) : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildModernNotesSection(String notes) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.blue50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.blue200),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Notes:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.blue700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            notes,
            style: const pw.TextStyle(fontSize: 12),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildModernTermsSection(String terms) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(16),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'Terms & Conditions:',
            style: pw.TextStyle(
              fontSize: 14,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
            ),
          ),
          pw.SizedBox(height: 8),
          pw.Text(
            terms,
            style: pw.TextStyle(
              fontSize: 11,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }


  pw.Widget _buildModernCompanyLogo(Company? company, [PdfColor? customColor]) {
    if (company?.logoPath != null &&
        company!.logoPath!.isNotEmpty &&
        File(company.logoPath!).existsSync()) {
      try {
        final logoBytes = File(company.logoPath!).readAsBytesSync();
        final logoImage = pw.MemoryImage(logoBytes);

        return pw.Container(
          width: 80,
          height: 80,
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            borderRadius: pw.BorderRadius.circular(8),
            border: pw.Border.all(color: PdfColors.grey300),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Image(
              logoImage,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
      } catch (e) {
        return _buildModernTextLogo(company, customColor);
      }
    } else if (company?.name != null) {
      return _buildModernTextLogo(company!, customColor);
    }

    return pw.SizedBox(width: 80, height: 80);
  }

  pw.Widget _buildModernTextLogo(Company company, [PdfColor? customColor]) {
    return pw.Container(
      width: 80,
      height: 80,
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        borderRadius: pw.BorderRadius.circular(8),
        border: pw.Border.all(color: PdfColors.grey300),
      ),
      child: pw.Center(
        child: pw.Text(
          company.name.substring(0, 1).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 32,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.blue700,
          ),
        ),
      ),
    );
  }

  // Elegant Template Methods
  pw.Widget _buildElegantHeader(Invoice invoice, Company? company, [PdfColor? customColor]) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: customColor ?? PdfColors.grey800, width: 3),
        ),
      ),
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 20),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  invoice.type.value.toUpperCase(),
                  style: pw.TextStyle(
                    fontSize: 36,
                    fontWeight: pw.FontWeight.bold,
                    color: customColor ?? PdfColors.grey800,
                    letterSpacing: 2,
                  ),
                ),
                pw.SizedBox(height: 8),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: pw.BoxDecoration(
                    color: customColor ?? PdfColors.grey800,
                  ),
                  child: pw.Text(
                    invoice.number,
                    style: pw.TextStyle(
                      fontSize: 14,
                      color: PdfColors.white,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            _buildElegantCompanyLogo(company, customColor),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildElegantCompanyLogo(Company? company, [PdfColor? customColor]) {
    if (company?.logoPath != null &&
        company!.logoPath!.isNotEmpty &&
        File(company.logoPath!).existsSync()) {
      try {
        final logoBytes = File(company.logoPath!).readAsBytesSync();
        final logoImage = pw.MemoryImage(logoBytes);

        return pw.Container(
          width: 90,
          height: 90,
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: customColor ?? PdfColors.grey800, width: 2),
          ),
          child: pw.Padding(
            padding: const pw.EdgeInsets.all(6),
            child: pw.Image(
              logoImage,
              fit: pw.BoxFit.contain,
            ),
          ),
        );
      } catch (e) {
        return _buildElegantTextLogo(company, customColor);
      }
    } else if (company?.name != null) {
      return _buildElegantTextLogo(company!, customColor);
    }

    return pw.SizedBox(width: 90, height: 90);
  }

  pw.Widget _buildElegantTextLogo(Company company, [PdfColor? customColor]) {
    return pw.Container(
      width: 90,
      height: 90,
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: customColor ?? PdfColors.grey800, width: 2),
      ),
      child: pw.Center(
        child: pw.Text(
          company.name.substring(0, 1).toUpperCase(),
          style: pw.TextStyle(
            fontSize: 36,
            fontWeight: pw.FontWeight.bold,
            color: customColor ?? PdfColors.grey800,
          ),
        ),
      ),
    );
  }

  pw.Widget _buildElegantCompanyAndClientInfo(Company? company, Map<String, dynamic> clientData) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey600, width: 1),
                  ),
                ),
                child: pw.Text(
                  'FROM',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                company?.name ?? 'Your Company Name',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              if (company?.address != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(company!.address!, style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
              if (company?.phone != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Phone: ${company!.phone!}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
              if (company?.email != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Email: ${company!.email!}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
              if (company?.taxId != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Tax ID: ${company!.taxId!}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
              if (company?.website != null) ...[
                pw.SizedBox(height: 4),
                pw.Text('Website: ${company!.website!}', style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ],
          ),
        ),
        pw.SizedBox(width: 40),
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.only(bottom: 8),
                decoration: pw.BoxDecoration(
                  border: pw.Border(
                    bottom: pw.BorderSide(color: PdfColors.grey600, width: 1),
                  ),
                ),
                child: pw.Text(
                  'BILL TO',
                  style: pw.TextStyle(
                    fontSize: 12,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey600,
                    letterSpacing: 1,
                  ),
                ),
              ),
              pw.SizedBox(height: 12),
              pw.Text(
                clientData['client_name'] ?? 'Unknown Client',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey800,
                ),
              ),
              if (clientData['client_email'] != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(clientData['client_email'], style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
              if (clientData['client_phone'] != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(clientData['client_phone'], style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
              if (clientData['client_address'] != null) ...[
                pw.SizedBox(height: 4),
                pw.Text(_buildFullAddress(clientData), style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  pw.Widget _buildElegantInvoiceDetails(Invoice invoice) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildElegantDetailRow('Issue Date', DateFormat('MMM dd, yyyy').format(invoice.issueDate)),
              if (invoice.dueDate != null) ...[
                pw.SizedBox(height: 8),
                _buildElegantDetailRow(
                  invoice.type == InvoiceType.estimate ? 'Valid Until' : 'Due Date',
                  DateFormat('MMM dd, yyyy').format(invoice.dueDate!),
                ),
              ],
            ],
          ),
        ),
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: pw.BoxDecoration(
            color: _getStatusColor(invoice.status),
            border: pw.Border.all(color: PdfColors.grey800, width: 1),
          ),
          child: pw.Text(
            invoice.status.value.toUpperCase(),
            style: pw.TextStyle(
              color: PdfColors.white,
              fontWeight: pw.FontWeight.bold,
              fontSize: 12,
              letterSpacing: 1,
            ),
          ),
        ),
      ],
    );
  }

  pw.Widget _buildElegantDetailRow(String label, String value) {
    return pw.Row(
      children: [
        pw.Container(
          width: 80,
          child: pw.Text(
            '$label:',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              fontSize: 12,
            ),
          ),
        ),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 12,
            color: PdfColors.grey800,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildElegantItemsTable(List<InvoiceItem> items, [PdfColor? customColor]) {
    return pw.Table(
      border: pw.TableBorder(
        top: pw.BorderSide(color: customColor ?? PdfColors.grey800, width: 2),
        bottom: pw.BorderSide(color: customColor ?? PdfColors.grey800, width: 2),
        horizontalInside: pw.BorderSide(color: PdfColors.grey400, width: 0.5),
      ),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
        2: const pw.FlexColumnWidth(1.5),
        3: const pw.FlexColumnWidth(1.5),
      },
      children: [
        // Header
        pw.TableRow(
          decoration: pw.BoxDecoration(color: customColor ?? PdfColors.grey800),
          children: [
            _buildElegantTableCell('PRODUCT/SERVICE', isHeader: true),
            _buildElegantTableCell('QTY', isHeader: true, alignment: pw.Alignment.center),
            _buildElegantTableCell('RATE', isHeader: true, alignment: pw.Alignment.centerRight),
            _buildElegantTableCell('AMOUNT', isHeader: true, alignment: pw.Alignment.centerRight),
          ],
        ),
        // Items
        ...items.map((item) => pw.TableRow(
          children: [
            _buildElegantProductCell(item),
            _buildElegantTableCell(item.quantity.toString(), alignment: pw.Alignment.center),
            _buildElegantTableCell(NumberFormat.currency(symbol: '\$').format(item.unitPrice), alignment: pw.Alignment.centerRight),
            _buildElegantTableCell(NumberFormat.currency(symbol: '\$').format(item.total), alignment: pw.Alignment.centerRight),
          ],
        )),
      ],
    );
  }

  pw.Widget _buildElegantTableCell(String text, {bool isHeader = false, pw.Alignment? alignment}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: alignment ?? pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontWeight: isHeader ? pw.FontWeight.bold : pw.FontWeight.normal,
          fontSize: isHeader ? 11 : 11,
          color: isHeader ? PdfColors.white : PdfColors.grey800,
          letterSpacing: isHeader ? 1 : 0,
        ),
      ),
    );
  }

  pw.Widget _buildElegantProductCell(InvoiceItem item) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      alignment: pw.Alignment.centerLeft,
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisSize: pw.MainAxisSize.min,
        children: [
          pw.Text(
            item.name,
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 11,
              color: PdfColors.grey800,
            ),
          ),
          if (item.description.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            pw.Text(
              item.description,
              style: pw.TextStyle(
                fontSize: 10,
                color: PdfColors.grey600,
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
          if (item.category != null && item.category!.isNotEmpty) ...[
            pw.SizedBox(height: 3),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: PdfColors.grey600, width: 0.5),
              ),
              child: pw.Text(
                item.category!,
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColors.grey600,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _buildElegantTotalsSection(Invoice invoice, [PdfColor? customColor]) {
    return pw.Align(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 240,
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: customColor ?? PdfColors.grey800, width: 1),
        ),
        child: pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.end,
          children: [
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: customColor ?? PdfColors.grey800,
              ),
              child: pw.Text(
                'SUMMARY',
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 1,
                ),
                textAlign: pw.TextAlign.center,
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(16),
              child: pw.Column(
                children: [
                  _buildElegantTotalRow('Subtotal', NumberFormat.currency(symbol: '\$').format(invoice.subtotal)),
                  if (invoice.discountAmount > 0)
                    _buildElegantTotalRow('Discount', '-${NumberFormat.currency(symbol: '\$').format(invoice.discountAmount)}'),
                  if (invoice.taxAmount > 0)
                    _buildElegantTotalRow('Tax', NumberFormat.currency(symbol: '\$').format(invoice.taxAmount)),
                  pw.Container(
                    margin: const pw.EdgeInsets.symmetric(vertical: 8),
                    height: 1,
                    color: customColor ?? PdfColors.grey800,
                  ),
                  _buildElegantTotalRow(
                    'TOTAL',
                    NumberFormat.currency(symbol: '\$').format(invoice.total),
                    isTotal: true,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  pw.Widget _buildElegantTotalRow(String label, String amount, {bool isTotal = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
              color: PdfColors.grey800,
              letterSpacing: isTotal ? 1 : 0,
            ),
          ),
          pw.Text(
            amount,
            style: pw.TextStyle(
              fontWeight: isTotal ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontSize: isTotal ? 14 : 12,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _buildElegantNotesSection(String notes) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey600, width: 1),
            ),
          ),
          child: pw.Text(
            'NOTES',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          notes,
          style: pw.TextStyle(
            fontSize: 11,
            color: PdfColors.grey700,
            lineSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildElegantTermsSection(String terms) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.only(bottom: 8),
          decoration: pw.BoxDecoration(
            border: pw.Border(
              bottom: pw.BorderSide(color: PdfColors.grey600, width: 1),
            ),
          ),
          child: pw.Text(
            'TERMS & CONDITIONS',
            style: pw.TextStyle(
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey600,
              letterSpacing: 1,
            ),
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          terms,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
            lineSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildWatermark() {
    return pw.Align(
      alignment: pw.Alignment.bottomRight,
      child: pw.Padding(
        padding: const pw.EdgeInsets.only(top: 16),
        child: pw.Text(
          'powered by invoice box',
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey500,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ),
    );
  }

}