import '../models/models.dart';
import '../../core/database/database_helper.dart';

class InvoiceService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> createInvoice(Invoice invoice, List<InvoiceItem> items) async {
    final db = await _db.database;
    
    return await db.transaction((txn) async {
      final invoiceMap = invoice.toMap();
      invoiceMap.remove('id');
      final invoiceId = await txn.insert('invoices', invoiceMap);
      
      for (final item in items) {
        final itemMap = item.copyWith(invoiceId: invoiceId).toMap();
        itemMap.remove('id');
        await txn.insert('invoice_items', itemMap);
      }
      
      return invoiceId;
    });
  }

  Future<List<Invoice>> getAllInvoices() async {
    final maps = await _db.query('invoices', orderBy: 'created_at DESC');
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<Invoice?> getInvoiceById(int id) async {
    final maps = await _db.query(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Invoice.fromMap(maps.first);
  }

  Future<List<InvoiceItem>> getInvoiceItems(int invoiceId) async {
    final maps = await _db.query(
      'invoice_items',
      where: 'invoice_id = ?',
      whereArgs: [invoiceId],
      orderBy: 'id ASC',
    );
    return maps.map((map) => InvoiceItem.fromMap(map)).toList();
  }

  Future<Map<String, dynamic>?> getInvoiceWithDetails(int id) async {
    final invoiceQuery = await _db.rawQuery('''
      SELECT 
        i.*,
        c.name as client_name,
        c.email as client_email,
        c.phone as client_phone,
        c.address as client_address,
        c.city as client_city,
        c.state as client_state,
        c.zip_code as client_zip_code
      FROM invoices i
      JOIN clients c ON i.client_id = c.id
      WHERE i.id = ?
    ''', [id]);

    if (invoiceQuery.isEmpty) return null;

    final items = await getInvoiceItems(id);
    
    return {
      'invoice': invoiceQuery.first,
      'items': items.map((item) => item.toMap()).toList(),
    };
  }

  Future<List<Invoice>> getInvoicesByStatus(InvoiceStatus status) async {
    final maps = await _db.query(
      'invoices',
      where: 'status = ?',
      whereArgs: [status.value],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<List<Invoice>> getInvoicesByType(InvoiceType type) async {
    final maps = await _db.query(
      'invoices',
      where: 'type = ?',
      whereArgs: [type.value],
      orderBy: 'created_at DESC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<List<Invoice>> getOverdueInvoices() async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final maps = await _db.query(
      'invoices',
      where: 'due_date < ? AND status != ?',
      whereArgs: [today, InvoiceStatus.paid.value],
      orderBy: 'due_date ASC',
    );
    return maps.map((map) => Invoice.fromMap(map)).toList();
  }

  Future<int> updateInvoice(Invoice invoice) async {
    return await _db.update(
      'invoices',
      invoice.toMap(),
      where: 'id = ?',
      whereArgs: [invoice.id],
    );
  }

  Future<int> updateInvoiceStatus(int id, InvoiceStatus status) async {
    return await _db.update(
      'invoices',
      {'status': status.value},
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteInvoice(int id) async {
    return await _db.delete(
      'invoices',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<String> generateInvoiceNumber(InvoiceType type) async {
    final prefix = type == InvoiceType.invoice ? 'INV' : 
                   type == InvoiceType.estimate ? 'EST' : 'REC';
    
    final year = DateTime.now().year.toString();
    
    final result = await _db.rawQuery('''
      SELECT MAX(CAST(SUBSTR(number, -4) AS INTEGER)) as last_number
      FROM invoices 
      WHERE type = ? AND number LIKE ?
    ''', [type.value, '$prefix-$year-%']);

    final lastNumber = result.first['last_number'] as int? ?? 0;
    final nextNumber = (lastNumber + 1).toString().padLeft(4, '0');
    
    return '$prefix-$year-$nextNumber';
  }

  Future<Map<String, dynamic>> getDashboardStats() async {
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total_invoices,
        SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END) as total_paid,
        SUM(CASE WHEN status = 'sent' THEN total ELSE 0 END) as total_pending,
        SUM(CASE WHEN status = 'overdue' THEN total ELSE 0 END) as total_overdue,
        SUM(CASE WHEN status = 'draft' THEN total ELSE 0 END) as total_drafts
      FROM invoices
      WHERE strftime('%Y-%m', created_at) = strftime('%Y-%m', 'now')
    ''');

    return result.first;
  }

  Future<List<Map<String, dynamic>>> getMonthlyStats(int year) async {
    return await _db.rawQuery('''
      SELECT 
        strftime('%m', created_at) as month,
        COUNT(*) as invoice_count,
        SUM(total) as total_amount,
        SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END) as paid_amount
      FROM invoices
      WHERE strftime('%Y', created_at) = ?
      GROUP BY strftime('%Y-%m', created_at)
      ORDER BY month
    ''', [year.toString()]);
  }

  Future<Invoice> convertEstimateToInvoice(int estimateId) async {
    final estimate = await getInvoiceById(estimateId);
    if (estimate == null || estimate.type != InvoiceType.estimate) {
      throw Exception('Estimate not found or invalid type');
    }

    final items = await getInvoiceItems(estimateId);
    final invoiceNumber = await generateInvoiceNumber(InvoiceType.invoice);

    final invoice = estimate.copyWith(
      id: null,
      number: invoiceNumber,
      type: InvoiceType.invoice,
      status: InvoiceStatus.draft,
    );

    final invoiceId = await createInvoice(invoice, items);
    final newInvoice = await getInvoiceById(invoiceId);
    return newInvoice!;
  }
}