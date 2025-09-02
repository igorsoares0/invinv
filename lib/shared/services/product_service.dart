import '../models/models.dart';
import '../../core/database/database_helper.dart';

class ProductService {
  final DatabaseHelper _db = DatabaseHelper();

  Future<int> createProduct(Product product) async {
    final map = product.toMap();
    map.remove('id');
    return await _db.insert('products', map);
  }

  Future<List<Product>> getAllProducts() async {
    final maps = await _db.query('products', orderBy: 'name ASC');
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<Product?> getProductById(int id) async {
    final maps = await _db.query(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
    
    if (maps.isEmpty) return null;
    return Product.fromMap(maps.first);
  }

  Future<List<Product>> searchProducts(String query) async {
    final maps = await _db.query(
      'products',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<Product>> getProductsByCategory(String category) async {
    final maps = await _db.query(
      'products',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
    return maps.map((map) => Product.fromMap(map)).toList();
  }

  Future<List<String>> getAllCategories() async {
    final maps = await _db.rawQuery('''
      SELECT DISTINCT category 
      FROM products 
      WHERE category IS NOT NULL AND category != ''
      ORDER BY category ASC
    ''');
    return maps.map((map) => map['category'] as String).toList();
  }

  Future<int> updateProduct(Product product) async {
    return await _db.update(
      'products',
      product.toMap(),
      where: 'id = ?',
      whereArgs: [product.id],
    );
  }

  Future<int> deleteProduct(int id) async {
    return await _db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Product>> getMostUsedProducts({int limit = 10}) async {
    final maps = await _db.rawQuery('''
      SELECT p.*, COUNT(ii.product_id) as usage_count
      FROM products p
      LEFT JOIN invoice_items ii ON p.id = ii.product_id
      GROUP BY p.id
      ORDER BY usage_count DESC, p.name ASC
      LIMIT ?
    ''', [limit]);
    return maps.map((map) => Product.fromMap(map)).toList();
  }
}