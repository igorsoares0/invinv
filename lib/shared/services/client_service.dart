import '../models/models.dart';
import '../../core/database/database_helper.dart';

class ClientService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> createClient(Client client) async {
    final map = client.toMap();
    map.remove('id');
    return await _db.insert('clients', map);
  }

  Future<List<Client>> getAllClients() async {
    final maps = await _db.query('clients', orderBy: 'name ASC');
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<Client?> getClientById(int id) async {
    final maps = await _db.query(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Client.fromMap(maps.first);
  }

  Future<List<Client>> searchClients(String query) async {
    final maps = await _db.query(
      'clients',
      where: 'name LIKE ? OR email LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Client.fromMap(map)).toList();
  }

  Future<int> updateClient(Client client) async {
    return await _db.update(
      'clients',
      client.toMap(),
      where: 'id = ?',
      whereArgs: [client.id],
    );
  }

  Future<int> deleteClient(int id) async {
    return await _db.delete(
      'clients',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Map<String, dynamic>>> getClientInvoiceHistory(int clientId) async {
    return await _db.rawQuery('''
      SELECT 
        i.*,
        c.name as client_name
      FROM invoices i
      JOIN clients c ON i.client_id = c.id
      WHERE i.client_id = ?
      ORDER BY i.created_at DESC
    ''', [clientId]);
  }

  Future<Map<String, dynamic>> getClientStats(int clientId) async {
    final result = await _db.rawQuery('''
      SELECT 
        COUNT(*) as total_invoices,
        SUM(CASE WHEN status = 'paid' THEN total ELSE 0 END) as total_paid,
        SUM(CASE WHEN status = 'sent' THEN total ELSE 0 END) as total_pending,
        SUM(CASE WHEN status = 'overdue' THEN total ELSE 0 END) as total_overdue
      FROM invoices
      WHERE client_id = ?
    ''', [clientId]);

    return result.first;
  }
}