import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'dart:io';

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

  Future<bool> isMaVachUnique(String maVach) async {
    final db = await database;
    if (maVach.isEmpty) return true;
    final List<Map<String, dynamic>> result = await db.query(
      'sanpham',
      where: 'maVach = ?',
      whereArgs: [maVach],
    );
    return result.isEmpty;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pos_database.db');
    print('Database path: $path');

    try {
      var databasePath = await getDatabasesPath();
      var directory = Directory(databasePath);
      if (!directory.existsSync()) {
        directory.createSync(recursive: true);
        print('Database directory created: $databasePath');
      }

      return await openDatabase(
        path,
        version: 12,
        onCreate: (db, version) async {
          try {
            await db.execute(
              '''
          CREATE TABLE sanpham (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            ten TEXT,
            gia REAL,
            hinhAnh TEXT,
            soLuong INTEGER DEFAULT 0,
            maVach TEXT UNIQUE
          )
          ''',
            );
            await db.execute(
              '''
          CREATE TABLE customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT,
            phone TEXT UNIQUE,
            points REAL DEFAULT 0.0
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
            thoiGian TEXT,
            soLuong INTEGER,
            total_price REAL,
            customerId INTEGER,
            paymentMethod TEXT,
            FOREIGN KEY (sanPhamId) REFERENCES sanpham(id) ON DELETE CASCADE,
            FOREIGN KEY (customerId) REFERENCES customers(id) ON DELETE SET NULL
          )
          ''',
            );
            await db.execute(
              '''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT,
            ten_nv TEXT,
            sdt_nv TEXT,
            dia_chi_nv TEXT
          )
          ''',
            );
            await db.execute(
              '''
              CREATE TABLE shifts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                userId INTEGER,
                startTime TEXT,
                endTime TEXT,
                initialCash REAL,
                finalCash REAL,
                totalRevenue REAL,
                FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
              )
              ''',
            );
            await db.execute(
              '''
              CREATE TABLE shift_transactions (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                shiftId INTEGER,
                transactionId INTEGER,
                FOREIGN KEY (shiftId) REFERENCES shifts(id) ON DELETE CASCADE,
                FOREIGN KEY (transactionId) REFERENCES transactions(id) ON DELETE CASCADE
              )
              ''',
            );
            await db.execute(
              '''
              CREATE TABLE notifications (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                senderId INTEGER,
                receiverId INTEGER,
                message TEXT NOT NULL,
                timestamp TEXT NOT NULL,
                isRead INTEGER DEFAULT 0,
                FOREIGN KEY (senderId) REFERENCES users(id) ON DELETE CASCADE,
                FOREIGN KEY (receiverId) REFERENCES users(id) ON DELETE SET NULL
              )
              ''',
            );
            await _createDefaultUsers(db);
          } catch (e) {
            print("Error creating tables: $e");
            rethrow;
          }
        },
        onUpgrade: (db, oldVersion, newVersion) async {
          try {
            if (oldVersion < 2) {
              await db.execute(
                '''
            CREATE TABLE transactions (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              sanPhamId INTEGER,
              ten TEXT,
              gia REAL,
              thoiGian TEXT,
              soLuong INTEGER,
              FOREIGN KEY (sanPhamId) REFERENCES sanpham(id) ON DELETE CASCADE
            )
            ''',
              );
            }
            if (oldVersion < 3) {
              await db.execute(
                '''
              ALTER TABLE sanpham ADD COLUMN soLuong INTEGER DEFAULT 0;
              ''',
              );
            }
            if (oldVersion < 4) {
              await db.execute(
                '''
              ALTER TABLE sanpham ADD COLUMN maVach TEXT;
              ''',
              );
              await db.execute(
                '''
              CREATE UNIQUE INDEX unique_maVach ON sanpham (maVach);
              ''',
              );
            }
            if (oldVersion < 5) {
              await db.execute(
                '''
              ALTER TABLE transactions ADD COLUMN soLuong INTEGER;
              ''',
              );
            }
            if (oldVersion < 6) {
              await db.execute(
                '''
          CREATE TABLE users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT UNIQUE,
            password TEXT,
            role TEXT,
            ten_nv TEXT,
            sdt_nv TEXT,
            dia_chi_nv TEXT
          )
          ''',
              );
              await _createDefaultUsers(db);
            }
            if (oldVersion < 7) {
              await db.execute(
                '''
                CREATE TABLE shifts (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  userId INTEGER,
                  startTime TEXT,
                  endTime TEXT,
                  initialCash REAL,
                  finalCash REAL,
                  totalRevenue REAL,
                  FOREIGN KEY (userId) REFERENCES users(id) ON DELETE CASCADE
                )
                ''',
              );
            }
            if (oldVersion < 8) {
              await db.execute(
                '''
                CREATE TABLE shift_transactions (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  shiftId INTEGER,
                  transactionId INTEGER,
                  FOREIGN KEY (shiftId) REFERENCES shifts(id) ON DELETE CASCADE,
                  FOREIGN KEY (transactionId) REFERENCES transactions(id) ON DELETE CASCADE
                )
                ''',
              );
            }
            if (oldVersion < 9) {
              print('Database upgrade: Adding total_price column to transactions table.');
              await db.execute(
                '''
                ALTER TABLE transactions ADD COLUMN total_price REAL;
                ''',
              );
              await db.rawUpdate('''
                UPDATE transactions SET total_price = gia * soLuong WHERE total_price IS NULL
              ''');
            }
            if (oldVersion < 10) {
              print('Database upgrade: Adding customers table and customerId to transactions.');
              await db.execute(
                '''
                CREATE TABLE customers (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  name TEXT,
                  phone TEXT UNIQUE,
                  points REAL DEFAULT 0.0
                )
                ''',
              );
              await db.execute(
                '''
                ALTER TABLE transactions ADD COLUMN customerId INTEGER;
                ''',
              );
              await db.execute(
                '''
                CREATE INDEX idx_transactions_customerId ON transactions (customerId);
                ''',
              );
            }
            if (oldVersion < 11) {
              print('Database upgrade: Creating notifications table and paymentMethod column.');
              await db.execute(
                '''
                CREATE TABLE notifications (
                  id INTEGER PRIMARY KEY AUTOINCREMENT,
                  senderId INTEGER,
                  receiverId INTEGER,
                  message TEXT NOT NULL,
                  timestamp TEXT NOT NULL,
                  isRead INTEGER DEFAULT 0,
                  FOREIGN KEY (senderId) REFERENCES users(id) ON DELETE CASCADE,
                  FOREIGN KEY (receiverId) REFERENCES users(id) ON DELETE SET NULL
                )
                ''',
              );
              await db.execute(
                '''
                ALTER TABLE transactions ADD COLUMN paymentMethod TEXT DEFAULT 'Tiền mặt';
                ''',
              );
            }
          } catch (e) {
            print("Error upgrading database: $e");
            rethrow;
          }
        },
      );
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }

  Future<void> _createDefaultUsers(Database db) async {
    try {
      var countQL = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['QL'],
      );
      if (countQL.isEmpty) {
        await db.insert(
          'users',
          {
            'username': 'QL',
            'password': '123',
            'role': 'Quản lý',
            'ten_nv': 'Nguyễn Văn Quản Lý',
            'sdt_nv': '0123456789',
            'dia_chi_nv': 'Địa chỉ quản lý',
          },
        );
        print('Default user "QL" created.');
      }

      var countNV = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: ['NV'],
      );
      if (countNV.isEmpty) {
        await db.insert(
          'users',
          {
            'username': 'NV',
            'password': '123',
            'role': 'Nhân viên',
            'ten_nv': 'Trần Thị Nhân Viên',
            'sdt_nv': '0987654321',
            'dia_chi_nv': 'Địa chỉ nhân viên',
          },
        );
        print('Default user "NV" created.');
      }
    } catch (e) {
      print('Error creating default users: $e');
      rethrow;
    }
  }

  static DatabaseHelper get instance => _instance;

  Future<int> insertSanPham(Map<String, dynamic> sanPham) async {
    final db = await database;
    try {
      print('Inserting product: $sanPham');
      return await db.insert('sanpham', sanPham);
    } catch (e) {
      print('Error inserting product: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> insertNotification(Map<String, dynamic> notification) async {
    final db = await database;
    print('Inserting notification: $notification');
    try {
      return await db.insert('notifications', notification);
    } catch (e) {
      print('Error inserting notification: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getNotificationsForUser(int userId) async {
    final db = await database;
    print('Fetching notifications for user ID: $userId');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'notifications',
        where: 'receiverId IS NULL OR receiverId = ?',
        whereArgs: [userId],
        orderBy: 'timestamp DESC',
      );
      print('Fetched ${result.length} notifications for user ID: $userId');
      return result;
    } catch (e) {
      print('Error fetching notifications for user: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> getUnreadNotificationCount(int userId) async {
    final db = await database;
    print('Counting unread notifications for user ID: $userId');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'notifications',
        where: '(receiverId IS NULL OR receiverId = ?) AND isRead = 0',
        whereArgs: [userId],
        columns: ['COUNT(*) as count'],
      );
      if (result.isNotEmpty) {
        return result.first['count'] as int;
      }
      return 0;
    } catch (e) {
      print('Error counting unread notifications: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> markNotificationAsRead(int notificationId) async {
    final db = await database;
    print('Marking notification ID: $notificationId as read.');
    try {
      return await db.update(
        'notifications',
        {'isRead': 1},
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      print('Error marking notification as read: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> deleteNotification(int notificationId) async {
    final db = await database;
    print('Deleting notification ID: $notificationId');
    try {
      return await db.delete(
        'notifications',
        where: 'id = ?',
        whereArgs: [notificationId],
      );
    } catch (e) {
      print('Error deleting notification: ${e.toString()}');
      rethrow;
    }
  }


  Future<int> updateSanPham(Map<String, dynamic> sanPham) async {
    final db = await database;
    try {
      print('Updating product ID: ${sanPham['id']} with data: $sanPham');
      int rowsAffected = await db.update(
        'sanpham',
        sanPham,
        where: 'id = ?',
        whereArgs: [sanPham['id']],
      );
      print(
        'Product ID: ${sanPham['id']} updated. Rows affected: $rowsAffected',
      );
      return rowsAffected;
    } catch (e) {
      print('Error updating product: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllSanPham() async {
    final db = await database;
    print('Fetching all products...');
    final List<Map<String, dynamic>> result = await db.query('sanpham');
    print('Fetched ${result.length} products.');
    return result;
  }

  Future<Map<String, dynamic>?> getSanPhamByMaVach(String maVach) async {
    final db = await database;
    print('Fetching product by barcode: $maVach');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'sanpham',
        where: 'maVach = ?',
        whereArgs: [maVach],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Product found by barcode: ${result.first['ten']}');
        return result.first;
      }
      print('No product found for barcode: $maVach');
      return null;
    } catch (e) {
      print('Error fetching product by barcode: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> deleteSanPham(int id) async {
    final db = await database;
    try {
      print('Deleting product ID: $id');
      int rowsAffected = await db.delete(
        'sanpham',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Product ID: $id deleted. Rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error deleting product: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> thanhToanSanPhamTransaction(
    int id,
    String ten,
    double giaDonVi, {
    int soLuong = 1,
    int? customerId,
    required String paymentMethod,
  }) async {
    final db = await database;
    int transactionId = -1;
    try {
      await db.transaction((txn) async {
        var sanPhamResult = await txn.query(
          'sanpham',
          where: 'id = ?',
          whereArgs: [id],
        );
        if (sanPhamResult.isNotEmpty) {
          var sanPhamData = sanPhamResult.first;
          int currentQuantity = sanPhamData['soLuong'] as int? ?? 0;
          print(
            'thanhToanSanPhamTransaction: Product ID: $id, Current Quantity: $currentQuantity, Selling: $soLuong',
          );

          if (currentQuantity >= soLuong) {
            String thoiGian = DateTime.now().toIso8601String();
            double totalPrice = giaDonVi * soLuong;

            transactionId = await txn.insert('transactions', {
              'sanPhamId': id,
              'ten': ten,
              'gia': giaDonVi,
              'thoiGian': thoiGian,
              'soLuong': soLuong,
              'total_price': totalPrice,
              'customerId': customerId,
              'paymentMethod': paymentMethod,
            });
            print(
              'thanhToanSanPhamTransaction: Transaction inserted with ID: $transactionId, Total Price: $totalPrice, Customer ID: $customerId, Payment Method: $paymentMethod',
            );

            int newQuantity = currentQuantity - soLuong;
            int updatedRows = await txn.update(
              'sanpham',
              {'soLuong': newQuantity},
              where: 'id = ?',
              whereArgs: [id],
            );
            print(
              'thanhToanSanPhamTransaction: Product quantity updated. Rows affected: $updatedRows, New Quantity: $newQuantity',
            );
            if (updatedRows == 0) {
              print(
                'WARNING: Product quantity update affected 0 rows for ID: $id. This might indicate an issue.',
              );
            }

            if (customerId != null) {
              double pointsEarned = totalPrice / 10000.0;
              await _updateCustomerPointsInTransaction(
                txn,
                customerId,
                pointsEarned,
              );
              print('Updated customer $customerId points by $pointsEarned');
            }
          } else {
            print(
              'thanhToanSanPhamTransaction: Not enough stock for product ID: $id. Current: $currentQuantity, Requested: $soLuong',
            );
            throw Exception('Không đủ số lượng sản phẩm trong kho.');
          }
        } else {
          print('thanhToanSanPhamTransaction: Product not found with ID: $id');
          throw Exception('Sản phẩm không tồn tại.');
        }
      });
      return transactionId;
    } catch (e) {
      print('Error processing payment (Transaction method): ${e.toString()}');
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
          firstDayOfMonth.toIso8601String(),
          lastDayOfMonth.toIso8601String(),
        ],
        columns: ['total_price'],
      );

      double totalRevenue = 0;
      for (var result in results) {
        totalRevenue += (result['total_price'] as num? ?? 0.0).toDouble();
      }
      return totalRevenue;
    } catch (e) {
      print('Error getting monthly revenue: ${e.toString()}');
      rethrow;
    }
  }

  Future<double> getTongDoanhThu() async {
    final db = await database;
    try {
      final List<Map<String, dynamic>> result = await db.rawQuery('''
        SELECT COALESCE(SUM(total_price), 0.0) AS total_revenue
        FROM transactions
        ''');
      if (result.isNotEmpty && result.first['total_revenue'] != null) {
        return (result.first['total_revenue'] as num).toDouble();
      }
      return 0.0;
    } catch (e) {
      print('Error getting total revenue: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsWithDate({
    int? year,
    int? month,
    int? day,
  }) async {
    final db = await database;
    try {
      String whereClause = '';
      List<dynamic> whereArgs = [];

      if (year != null) {
        whereClause += 'strftime(\'%Y\', thoiGian) = ?';
        whereArgs.add(year.toString());
      }
      if (month != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'strftime(\'%m\', thoiGian) = ?';
        whereArgs.add(month.toString().padLeft(2, '0'));
      }
      if (day != null) {
        if (whereClause.isNotEmpty) whereClause += ' AND ';
        whereClause += 'strftime(\'%d\', thoiGian) = ?';
        whereArgs.add(day.toString().padLeft(2, '0'));
      }

      final orderBy = 'thoiGian DESC';

      return await db.query(
        'transactions',
        where: whereClause.isNotEmpty ? whereClause : null,
        whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
        orderBy: orderBy,
      );
    } catch (e) {
      print('Error fetching transactions by date: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getBestSellingProducts() async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery('''
      SELECT
        ten AS product_name,
        COALESCE(SUM(soLuong), 0) AS total_quantity_sold,
        COALESCE(SUM(total_price), 0.0) AS total_revenue_from_product
      FROM transactions
      GROUP BY ten
      ORDER BY total_quantity_sold DESC
      LIMIT 10
    ''');
    return result;
  }

  Future<double> getShiftTotalRevenue(int shiftId) async {
    final db = await database;
    final List<Map<String, dynamic>> result = await db.rawQuery(
      '''
      SELECT COALESCE(SUM(T.total_price), 0.0) AS shift_total_revenue
      FROM transactions T
      JOIN shift_transactions ST ON T.id = ST.transactionId
      WHERE ST.shiftId = ?
    ''',
      [shiftId],
    );
    if (result.isNotEmpty && result.first['shift_total_revenue'] != null) {
      return (result.first['shift_total_revenue'] as num).toDouble();
    }
    return 0.0;
  }

  Future<int> insertUser(Map<String, dynamic> user) async {
    final db = await database;
    try {
      print('Inserting user: ${user['username']}');
      return await db.insert('users', user);
    } catch (e) {
      print('Error inserting user: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> updateUser(int id, Map<String, dynamic> user) async {
    final db = await database;
    try {
      print('Updating user ID: $id with data: $user');
      int rowsAffected = await db.update(
        'users',
        user,
        where: 'id = ?',
        whereArgs: [id],
      );
      print('User ID: $id updated. Rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error updating user: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllUsers() async {
    final db = await database;
    print('Fetching all users...');
    final List<Map<String, dynamic>> result = await db.query('users');
    print('Fetched ${result.length} users.');
    return result;
  }

  Future<int> deleteUser(int id) async {
    final db = await database;
    try {
      print('Deleting user ID: $id');
      int rowsAffected = await db.delete(
        'users',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('User ID: $id deleted. Rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error deleting user: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getUserByUsername(String username) async {
    final db = await database;
    print('Fetching user by username: $username');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('User found: ${result.first['username']}');
        return result.first;
      }
      print('No user found for username: $username');
      return null;
    } catch (e) {
      print('Error fetching user by username: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getSanPhamById(int id) async {
    final db = await database;
    print('Fetching product by ID: $id');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'sanpham',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Product found by ID: ${result.first['ten']}');
        return result.first;
      }
      print('No product found for ID: $id');
      return null;
    } catch (e) {
      print('Lỗi khi lấy sản phẩm theo ID: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> updateSoLuongSanPham(int id, int soLuongMoi) async {
    final db = await database;
    print('Updating quantity for product ID: $id to $soLuongMoi');
    try {
      int rowsAffected = await db.update(
        'sanpham',
        {'soLuong': soLuongMoi},
        where: 'id = ?',
        whereArgs: [id],
      );
      print(
        'Quantity updated for product ID: $id. Rows affected: $rowsAffected',
      );
      return rowsAffected;
    } catch (e) {
      print('Lỗi khi cập nhật số lượng sản phẩm: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> getSoLuongSanPham(int id) async {
    final db = await database;
    print('Getting quantity for product ID: $id');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'sanpham',
        columns: ['soLuong'],
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );

      if (result.isNotEmpty) {
        int quantity = result.first['soLuong'] as int;
        print('Quantity for product ID: $id is $quantity');
        return quantity;
      }
      print('No quantity found for product ID: $id (product not found)');
      return 0;
    } catch (e) {
      print('Lỗi khi lấy số lượng sản phẩm: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> insertShift(Map<String, dynamic> shift) async {
    final db = await database;
    print('Inserting shift: $shift');
    try {
      return await db.insert('shifts', shift);
    } catch (e) {
      print('Error inserting shift: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> updateShift(Map<String, dynamic> shift) async {
    final db = await database;
    print('Updating shift ID: ${shift['id']} with data: $shift');
    try {
      int rowsAffected = await db.update(
        'shifts',
        shift,
        where: 'id = ?',
        whereArgs: [shift['id']],
      );
      print('Shift ID: ${shift['id']} updated. Rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error updating shift: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllShifts() async {
    final db = await database;
    print('Fetching all shifts...');
    try {
      final result = await db.query('shifts', orderBy: 'startTime DESC');
      print('Fetched ${result.length} shifts.');
      return result;
    } catch (e) {
      print("Error in getAllShifts: $e");
      throw e;
    }
  }

  Future<Map<String, dynamic>?> getShiftById(int id) async {
    final db = await database;
    print('Fetching shift by ID: $id');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'shifts',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Shift found by ID: $id');
        return result.first;
      }
      print('No shift found for ID: $id');
      return null;
    } catch (e) {
      print('Error fetching shift by ID: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> insertShiftTransaction(int shiftId, int transactionId) async {
    final db = await database;
    print(
      'Inserting shift transaction: shiftId=$shiftId, transactionId=$transactionId',
    );
    try {
      return await db.insert('shift_transactions', {
        'shiftId': shiftId,
        'transactionId': transactionId,
      });
    } catch (e) {
      print('Error inserting shift transaction: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getTransactionsForShift(
    int shiftId,
  ) async {
    final db = await database;
    print('Fetching transactions for shift ID: $shiftId');
    try {
      final List<Map<String, dynamic>> result = await db.rawQuery(
        '''
        SELECT T.* FROM transactions T
        INNER JOIN shift_transactions ST ON T.id = ST.transactionId
        WHERE ST.shiftId = ?
        ORDER BY T.thoiGian DESC
        ''',
        [shiftId],
      );
      print('Fetched ${result.length} transactions for shift ID: $shiftId');
      return result;
    } catch (e) {
      print('Error fetching transactions for shift: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getEmployeeShifts(int userId) async {
    final db = await database;
    print('Fetching shifts for employee ID: $userId');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'shifts',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'startTime DESC',
      );
      print('Fetched ${result.length} shifts for employee ID: $userId');
      return result;
    } catch (e) {
      print('Error getting employee shifts: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> insertCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    try {
      print('Inserting customer: ${customer['name']}');
      return await db.insert('customers', customer);
    } catch (e) {
      print('Error inserting customer: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> updateCustomer(Map<String, dynamic> customer) async {
    final db = await database;
    try {
      print('Updating customer ID: ${customer['id']} with data: $customer');
      int rowsAffected = await db.update(
        'customers',
        customer,
        where: 'id = ?',
        whereArgs: [customer['id']],
      );
      print(
        'Customer ID: ${customer['id']} updated. Rows affected: $rowsAffected',
      );
      return rowsAffected;
    } catch (e) {
      print('Error updating customer: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCustomerById(int id) async {
    final db = await database;
    print('Fetching customer by ID: $id');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Customer found by ID: ${result.first['name']}');
        return result.first;
      }
      print('No customer found for ID: $id');
      return null;
    } catch (e) {
      print('Error fetching customer by ID: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _getCustomerByIdInTransaction(
    Transaction txn,
    int id,
  ) async {
    print('Fetching customer by ID in transaction: $id');
    try {
      final List<Map<String, dynamic>> result = await txn.query(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Customer found by ID in transaction: ${result.first['name']}');
        return result.first;
      }
      print('No customer found for ID in transaction: $id');
      return null;
    } catch (e) {
      print('Error fetching customer by ID in transaction: ${e.toString()}');
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getCustomerByPhone(String phone) async {
    final db = await database;
    print('Fetching customer by phone: $phone');
    try {
      final List<Map<String, dynamic>> result = await db.query(
        'customers',
        where: 'phone = ?',
        whereArgs: [phone],
        limit: 1,
      );
      if (result.isNotEmpty) {
        print('Customer found by phone: ${result.first['name']}');
        return result.first;
      }
      print('No customer found for phone: $phone');
      return null;
    } catch (e) {
      print('Error fetching customer by phone: ${e.toString()}');
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getAllCustomers() async {
    final db = await database;
    print('Fetching all customers...');
    final List<Map<String, dynamic>> result = await db.query('customers');
    print('Fetched ${result.length} customers.');
    return result;
  }

  Future<int> deleteCustomer(int id) async {
    final db = await database;
    try {
      print('Deleting customer ID: $id');
      int rowsAffected = await db.delete(
        'customers',
        where: 'id = ?',
        whereArgs: [id],
      );
      print('Customer ID: $id deleted. Rows affected: $rowsAffected');
      return rowsAffected;
    } catch (e) {
      print('Error deleting customer: ${e.toString()}');
      rethrow;
    }
  }

  Future<int> updateCustomerPoints(int customerId, double pointsChange) async {
    final db = await database;
    try {
      final customer = await getCustomerById(customerId);
      if (customer != null) {
        double currentPoints = customer['points'] as double? ?? 0.0;
        double newPoints = currentPoints + pointsChange;
        if (newPoints < 0) newPoints = 0;

        int rowsAffected = await db.update(
          'customers',
          {'points': newPoints},
          where: 'id = ?',
          whereArgs: [customerId],
        );
        print(
          'Customer $customerId points updated to $newPoints. Rows affected: $rowsAffected (Public method)',
        );
        return rowsAffected;
      } else {
        print(
          'Customer with ID $customerId not found for point update (Public method).',
        );
        return 0;
      }
    } catch (e) {
      print('Error updating customer points (Public method): ${e.toString()}');
      rethrow;
    }
  }

  Future<void> _updateCustomerPointsInTransaction(
    Transaction txn,
    int customerId,
    double pointsChange,
  ) async {
    try {
      final customer = await _getCustomerByIdInTransaction(txn, customerId);
      if (customer != null) {
        double currentPoints = customer['points'] as double? ?? 0.0;
        double newPoints = currentPoints + pointsChange;
        if (newPoints < 0) newPoints = 0;

        int rowsAffected = await txn.update(
          'customers',
          {'points': newPoints},
          where: 'id = ?',
          whereArgs: [customerId],
        );
        print(
          'Customer $customerId points updated to $newPoints. Rows affected: $rowsAffected (In Transaction)',
        );
      } else {
        print(
          'Customer with ID $customerId not found for point update in transaction.',
        );
      }
    } catch (e) {
      print('Error updating customer points in transaction: ${e.toString()}');
      rethrow;
    }
  }
}
