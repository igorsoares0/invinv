import '../models/models.dart';
import '../../core/database/database_helper.dart';

class CompanyService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> createCompany(Company company) async {
    final map = company.toMap();
    map.remove('id');
    return await _db.insert('companies', map);
  }

  Future<Company?> getCompany() async {
    final maps = await _db.query('companies', limit: 1);

    if (maps.isEmpty) return null;
    return Company.fromMap(maps.first);
  }

  Future<int> updateCompany(Company company) async {
    if (company.id == null) {
      return await createCompany(company);
    }

    return await _db.update(
      'companies',
      company.toMap(),
      where: 'id = ?',
      whereArgs: [company.id],
    );
  }

  Future<int> deleteCompany(int id) async {
    return await _db.delete(
      'companies',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<bool> hasCompanyData() async {
    final maps = await _db.query('companies', limit: 1);
    return maps.isNotEmpty;
  }
}