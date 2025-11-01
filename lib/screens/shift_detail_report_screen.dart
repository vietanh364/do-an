import 'package:flutter/material.dart';
import '../database/database_helper.dart';
import '../models/shift.dart';
import '../models/User.dart';

class User {
  int id;
  String username;
  String ten_nv;

  User({required this.id, required this.username, required this.ten_nv});

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      username: map['username'],
      ten_nv: map['ten_nv'],
    );
  }
}

class ShiftDetailReportScreen extends StatefulWidget {
  const ShiftDetailReportScreen({Key? key}) : super(key: key);

  @override
  _ShiftDetailReportScreenState createState() => _ShiftDetailReportScreenState();
}

class _ShiftDetailReportScreenState extends State<ShiftDetailReportScreen> {
  List<Shift> _allShifts = [];
  bool _isLoading = true;
  Map<int, User> _usersMap = {};

  @override
  void initState() {
    super.initState();
    _loadAllShiftsAndUsers();
  }

  Future<void> _loadAllShiftsAndUsers() async {
    try {
      final dbHelper = DatabaseHelper.instance; // Use the singleton
      final rawShifts = await dbHelper.getAllShifts(); // Lấy tất cả ca làm việc
      final rawUsers = await dbHelper.getAllUsers(); // Lấy tất cả người dùng để ánh xạ tên

      // Xây dựng map user để dễ dàng truy vấn tên nhân viên
      for (var userData in rawUsers) {
        _usersMap[userData['id']] = User.fromMap(userData); // Giả sử cột ID của user là 'id'
      }

      setState(() {
        _allShifts = rawShifts.map((data) => Shift.fromMap(data)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading all shifts and users: $e');
      setState(() {
        _isLoading = false;
        // Optionally show an error message to the user
      });
    }
  }

  // Phương thức giúp lấy tên nhân viên từ employeeId
  String _getEmployeeName(int? employeeId) {
    if (employeeId == null) return 'N/A';
    final user = _usersMap[employeeId];
    if (user != null) {
      return user.ten_nv ?? user.username; // Ưu tiên tên đầy đủ, sau đó đến username
    }
    return 'Không xác định';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Báo cáo chi tiết ca làm việc'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _allShifts.isEmpty
          ? const Center(child: Text('Chưa có ca làm việc nào được ghi nhận.'))
          : ListView.builder(
        itemCount: _allShifts.length,
        itemBuilder: (context, index) {
          final shift = _allShifts[index];
          return Card(
            margin: const EdgeInsets.all(8.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ca làm việc #${shift.shiftId} - Nhân viên: ${_getEmployeeName(shift.userId)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 8),
                  Text('Bắt đầu: ${shift.getFormattedStartTime()}'),
                  Text(
                    'Kết thúc: ${shift.endTime != null ? shift.getFormattedEndTime() : 'Đang diễn ra'}',
                  ),
                  Text('Tổng doanh thu: ${shift.totalRevenue.toStringAsFixed(0)} VND'),
                  Text('Tổng đơn hàng: ${shift.totalOrders}'),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

