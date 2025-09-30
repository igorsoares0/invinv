import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasesPath = await getDatabasesPath();
    final path = join(databasesPath, 'invinv.db');

    return await openDatabase(
      path,
      version: 4,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE companies (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        legal_name TEXT,
        logo_path TEXT,
        address TEXT,
        phone TEXT,
        email TEXT,
        website TEXT,
        tax_id TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE clients (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT,
        address TEXT,
        city TEXT,
        state TEXT,
        zip_code TEXT,
        notes TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE products (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        description TEXT,
        price REAL NOT NULL,
        unit TEXT DEFAULT 'un',
        category TEXT,
        created_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE invoices (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        number TEXT UNIQUE NOT NULL,
        type TEXT NOT NULL,
        client_id INTEGER NOT NULL,
        issue_date TEXT NOT NULL,
        due_date TEXT,
        status TEXT DEFAULT 'draft',
        subtotal REAL NOT NULL,
        discount_amount REAL DEFAULT 0,
        tax_amount REAL DEFAULT 0,
        total REAL NOT NULL,
        notes TEXT,
        terms TEXT,
        created_at TEXT NOT NULL,
        FOREIGN KEY (client_id) REFERENCES clients (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE invoice_items (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        invoice_id INTEGER NOT NULL,
        product_id INTEGER,
        name TEXT NOT NULL,
        description TEXT,
        quantity REAL NOT NULL,
        unit TEXT DEFAULT 'un',
        unit_price REAL NOT NULL,
        category TEXT,
        total REAL NOT NULL,
        FOREIGN KEY (invoice_id) REFERENCES invoices (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id) ON DELETE SET NULL
      )
    ''');

    await db.execute('''
      CREATE INDEX idx_invoices_client_id ON invoices(client_id)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoices_status ON invoices(status)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoices_type ON invoices(type)
    ''');

    await db.execute('''
      CREATE INDEX idx_invoice_items_invoice_id ON invoice_items(invoice_id)
    ''');

    await db.execute('''
      CREATE TABLE subscription_status (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        is_premium BOOLEAN DEFAULT 0,
        plan_type TEXT DEFAULT 'free',
        expires_at TEXT,
        is_active BOOLEAN DEFAULT 0,
        invoice_count INTEGER DEFAULT 0,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      INSERT INTO subscription_status (is_premium, plan_type, is_active, invoice_count, updated_at)
      VALUES (0, 'free', 1, 0, datetime('now'))
    ''');

    await db.execute('''
      CREATE TRIGGER increment_invoice_count
      AFTER INSERT ON invoices
      BEGIN
        UPDATE subscription_status
        SET invoice_count = invoice_count + 1,
            updated_at = datetime('now')
        WHERE id = 1;
      END
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      // Add unit and category columns to invoice_items table
      await db.execute('ALTER TABLE invoice_items ADD COLUMN unit TEXT DEFAULT "un"');
      await db.execute('ALTER TABLE invoice_items ADD COLUMN category TEXT');
    }
    if (oldVersion < 3) {
      // Add name column to invoice_items table
      await db.execute('ALTER TABLE invoice_items ADD COLUMN name TEXT DEFAULT ""');
      // Update existing records to move description to name field if name is empty
      await db.execute('UPDATE invoice_items SET name = description WHERE name = "" OR name IS NULL');
      // Clear description field for existing records since it's now separate
      await db.execute('UPDATE invoice_items SET description = ""');
    }
    if (oldVersion < 4) {
      // Add subscription_status table
      await db.execute('''
        CREATE TABLE subscription_status (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          is_premium BOOLEAN DEFAULT 0,
          plan_type TEXT DEFAULT 'free',
          expires_at TEXT,
          is_active BOOLEAN DEFAULT 0,
          invoice_count INTEGER DEFAULT 0,
          updated_at TEXT NOT NULL
        )
      ''');

      // Count existing invoices and insert initial status
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM invoices');
      final invoiceCount = result.first['count'] as int? ?? 0;

      await db.execute('''
        INSERT INTO subscription_status (is_premium, plan_type, is_active, invoice_count, updated_at)
        VALUES (0, 'free', 1, ?, datetime('now'))
      ''', [invoiceCount]);

      // Create trigger to auto-increment invoice count
      await db.execute('''
        CREATE TRIGGER increment_invoice_count
        AFTER INSERT ON invoices
        BEGIN
          UPDATE subscription_status
          SET invoice_count = invoice_count + 1,
              updated_at = datetime('now')
          WHERE id = 1;
        END
      ''');
    }
  }

  Future<int> insert(String table, Map<String, dynamic> values) async {
    final db = await database;
    return await db.insert(table, values);
  }

  Future<List<Map<String, dynamic>>> query(
    String table, {
    String? where,
    List<dynamic>? whereArgs,
    String? orderBy,
    int? limit,
    int? offset,
  }) async {
    final db = await database;
    return await db.query(
      table,
      where: where,
      whereArgs: whereArgs,
      orderBy: orderBy,
      limit: limit,
      offset: offset,
    );
  }

  Future<int> update(
    String table,
    Map<String, dynamic> values, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.update(table, values, where: where, whereArgs: whereArgs);
  }

  Future<int> delete(
    String table, {
    required String where,
    required List<dynamic> whereArgs,
  }) async {
    final db = await database;
    return await db.delete(table, where: where, whereArgs: whereArgs);
  }

  Future<List<Map<String, dynamic>>> rawQuery(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawQuery(sql, arguments);
  }

  Future<int> rawInsert(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawInsert(sql, arguments);
  }

  Future<int> rawUpdate(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawUpdate(sql, arguments);
  }

  Future<int> rawDelete(String sql, [List<dynamic>? arguments]) async {
    final db = await database;
    return await db.rawDelete(sql, arguments);
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}