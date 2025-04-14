import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';


class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'sanpham.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute(
          '''
          CREATE TABLE sanpham (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ten TEXT,
            gia REAL,
            hinhAnh TEXT,
            maVach TEXT UNIQUE
          )
          ''',
        );
        await db.execute(
          '''
          CREATE TABLE transactions (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            sanPhamId INTEGER,
            ten TEXT,
            gia REAL,
            thoiGian INTEGER  // Store time as INTEGER (Unix timestamp)
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
              '''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sanPhamId INTEGER,
              ten TEXT,
              gia REAL,
              thoiGian INTEGER,
              FOREIGN KEY (sanPhamId) REFERENCES sanpham(id)
            )
            '''
          );
        }
      },
    );
  }

  static DatabaseHelper get instance => _instance;

  // Thêm sản phẩm mới
  Future<int> insertSanPham(Map<String, dynamic> sanPham) async {
    final db = await database;
    try {
      return await db.insert('sanpham', sanPham);
    } catch (e) {
      print('Lỗi khi thêm sản phẩm: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSanPham() async {
    final db = await database;
    return await db.query('sanpham');
  }

  Future<Map<String, dynamic>?> getSanPhamByMaVach(String maVach) async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'sanpham',
        where: 'maVach = ?',
        whereArgs: [maVach],
        limit: 1,
      );

      if (result.isNotEmpty) {
        return result.first;
      } else {
        return null;
      }
    } catch (e) {
      print('Lỗi khi lấy sản phẩm theo mã vạch: $e');
      return null;
    }
  }

  Future<int> updateSanPham(Map<String, dynamic> sanPham) async {
    final db = await database;
    try {
      return await db.update(
        'sanpham',
        sanPham,
        where: 'id = ?',
        whereArgs: [sanPham['id']],
      );
    } catch (e) {
      print('Lỗi khi cập nhật sản phẩm: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> deleteSanPham(int id) async {
    final db = await database;
    try {
      return await db.delete(
        'sanpham',
        where: 'id = ?',
        whereArgs: [id],
      );
    } catch (e) {
      print('Lỗi khi xóa sản phẩm: $e');
      rethrow;
    }
  }

  Future<void> thanhToanSanPham(int sanPhamId, String ten, double gia) async {
    final db = await database;
    try {
      await db.insert(
        'transactions',
        {
          'sanPhamId': sanPhamId,
          'ten': ten,
          'gia': gia,
          'thoiGian': DateTime.now().millisecondsSinceEpoch,
        },
      );
    } catch (e) {
      print('Lỗi khi thanh toán sản phẩm: ${e.toString()}');
      rethrow;
    }
  }

  Future<double> getMonthlyRevenue(int year, int month) async {
    final db = await database;
    try {
      DateTime firstDayOfMonth = DateTime(year, month);
      DateTime lastDayOfMonth = DateTime(year, month + 1, 0, 23, 59, 59);

      List<Map<String, dynamic>> results = await db.query(
        'transactions',
        where: 'thoiGian >= ? AND thoiGian <= ?',
        whereArgs: [
          firstDayOfMonth.millisecondsSinceEpoch,
          lastDayOfMonth.millisecondsSinceEpoch,
        ],
        columns: ['gia'],
      );

      double totalRevenue = 0;
      for (var result in results) {
        totalRevenue += (result['gia'] is int) ? (result['gia']).toDouble() : result['gia'];
      }
      return totalRevenue;
    } catch (e) {
      print('Lỗi khi lấy doanh thu theo tháng: ${e.toString()}');
      rethrow;
    }
  }

  Future<double> getTongDoanhThu() async {
    final db = await database;
    try {
      List<Map<String, dynamic>> results = await db.query(
        'transactions',
        columns: ['gia'],
      );
      double totalRevenue = 0;
      for (var result in results) {
        totalRevenue += (result['gia'] is int) ? (result['gia']).toDouble() : result['gia'];
      }
      return totalRevenue;
    } catch (e) {
      print('Lỗi khi lấy tổng doanh thu: ${e.toString()}');
      rethrow;
    }
  }

  // New function to get transactions with date
  Future<List<Map<String, dynamic>>> getTransactionsWithDate({int? year, int? month, int? day}) async {
    final db = await database;
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (year != null) {
        whereClause += 'strftime(\'%Y\', datetime(thoiGian / 1000, \'unixepoch\')) = ?';
        whereArgs.add(year.toString());
      }
      if (month != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'strftime(\'%m\', datetime(thoiGian / 1000, \'unixepoch\')) = ?';
        whereArgs.add(month.toString().padLeft(2, '0'));
      }
      if (day != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'strftime(\'%d\', datetime(thoiGian / 1000, \'unixepoch\')) = ?';
        whereArgs.add(day.toString().padLeft(2, '0'));
      }

      return await db.query(
        'transactions',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      );
    } catch (e) {
      print('Lỗi khi lấy giao dịch theo điều kiện: ${e.toString()}');
      rethrow;
    }
  }
}