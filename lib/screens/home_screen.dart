import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ThemSanPhamScreen.dart';
import 'login_screen.dart';
import 'revenue_report_screen.dart';
import 'package:base_project/screens/product_screen.dart';
import 'package:base_project/screens/barcode_scanner_screen.dart';
import 'package:provider/provider.dart';
import 'SanPhamProvider.dart';
import 'package:base_project/database/database_helper.dart';
import 'inventory_screen.dart';
import 'PaymentScreen.dart';
import 'UserManagementScreen.dart';
import 'package:base_project/screens/shift_report_screen.dart';
import 'package:collection/collection.dart';
import 'package:base_project/screens/best_selling_products_screen.dart';
import 'package:base_project/screens/CustomerManagementScreen.dart';
import 'package:base_project/screens/ReceiptHistoryScreen.dart';
import 'package:base_project/screens/manager_notification_screen.dart';
import 'package:base_project/screens/employee_notification_screen.dart';


class HomeScreen extends StatefulWidget {
  final String userRole;
  final int userId;


  const HomeScreen({Key? key, required this.userRole, required this.userId}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  TextEditingController searchController = TextEditingController();
  double totalRevenue = 0;
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  List<Map<String, dynamic>> filteredSanPhamList = [];

  int? _currentShiftId;
  bool _isShiftActive = false;
  double _initialCash = 0.0;
  int _unreadNotificationCount = 0;

  double _currentShiftTotalRevenue = 0.0;

  @override
  void initState() {
    super.initState();
    _loadTotalRevenue();
    _checkActiveShift();
    _loadUnreadNotificationCount();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SanPhamProvider>(context, listen: false).layDanhSachSanPham();
    });
  }

  Future<void> _loadUnreadNotificationCount() async {
    if (widget.userId != null) {
      try {
        final count = await DatabaseHelper.instance.getUnreadNotificationCount(widget.userId);
        if (mounted) {
          setState(() {
            _unreadNotificationCount = count;
          });
        }
      } catch (e) {
        print('Error loading unread notification count: $e');
      }
    }
  }

  Future<void> _capNhatDoanhThuCaLamViecVaoDatabase(double soTien) async {
    if (_currentShiftId != null) {
      setState(() {
        _isLoading = true;
      });
      try {
        Map<String, dynamic>? caLamViec = await DatabaseHelper.instance.getShiftById(_currentShiftId!);

        if (caLamViec != null) {
          double doanhThuCaHienCo = (caLamViec['totalRevenue'] as double? ?? 0.0);
          double doanhThuCaMoi = doanhThuCaHienCo + soTien;

          await DatabaseHelper.instance.updateShift({
            'id': _currentShiftId,
            'totalRevenue': doanhThuCaMoi,
          });

          if (mounted) {
            setState(() {
              _currentShiftTotalRevenue = doanhThuCaMoi;
            });
            print('Đã cập nhật doanh thu ca làm việc $_currentShiftId: ${NumberFormat("#,###", "vi_VN").format(doanhThuCaMoi)} VNĐ');
          }
        } else {
          print('Không tìm thấy ca làm việc với ID: $_currentShiftId để cập nhật doanh thu.');
        }
      } catch (e) {
        print('Lỗi khi cập nhật doanh thu ca làm việc trong DB: $e');
        if (mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Lỗi cập nhật doanh thu ca: ${e.toString()}')),
          );
        }
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    } else {
      print('Không có ca làm việc nào đang hoạt động để cập nhật doanh thu.');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('Vui lòng bắt đầu ca làm việc.')),
      );
    }
  }

  Future<void> _endShift() async {
    if (!_isShiftActive || _currentShiftId == null) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Không có ca làm việc nào đang hoạt động để kết thúc.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    final dbHelper = DatabaseHelper.instance;

    double shiftRevenue = _currentShiftTotalRevenue;

    print('Calculated Shift Revenue (from running total): $shiftRevenue');

    double? finalCash = await _showFinalCashDialog(_initialCash, shiftRevenue);
    if (finalCash == null) {
      print('User cancelled ending shift.');
      return;
    }
    print('Final Cash entered by user: $finalCash');

    setState(() {
      _isLoading = true;
    });

    try {
      final Map<String, dynamic> updatedShiftData = {
        'id': _currentShiftId,
        'endTime': DateTime.now().toIso8601String(),
        'finalCash': finalCash,
        'totalRevenue': shiftRevenue,
      };
      print('Updating shift with data: $updatedShiftData');

      await dbHelper.updateShift(updatedShiftData);
      print('Shift (ID: $_currentShiftId) successfully updated in DB.');

      setState(() {
        _currentShiftId = null;
        _isShiftActive = false;
        _initialCash = 0.0;
        _currentShiftTotalRevenue = 0.0;
      });
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Ca làm việc đã kết thúc. Doanh thu ca: ${NumberFormat("#,###", "vi_VN").format(shiftRevenue)} VNĐ'),
          duration: Duration(seconds: 3),
        ),
      );

      if (mounted) {
        print('Navigating to ShiftReportScreen for userId: ${widget.userId}');
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ShiftReportScreen(employeeId: widget.userId),
          ),
        ).then((_) {
          print('Returned from ShiftReportScreen.');
          _loadTotalRevenue();
        });
      }
    } catch (e) {
      print('Error ending shift: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Không thể kết thúc ca làm việc. Lỗi: ${e.toString()}'),
          duration: Duration(seconds: 5),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _checkActiveShift() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final allShifts = await dbHelper.getAllShifts();
      final currentActiveShift = allShifts.firstWhereOrNull(
            (shift) => shift['userId'] == widget.userId && shift['endTime'] == null,
      );

      if (currentActiveShift != null) {
        setState(() {
          _currentShiftId = currentActiveShift['id'] as int;
          _isShiftActive = true;
          _initialCash = currentActiveShift['initialCash'] as double? ?? 0.0;
          _currentShiftTotalRevenue = currentActiveShift['totalRevenue'] as double? ?? 0.0;
        });
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Tiếp tục ca làm việc #${_currentShiftId} của bạn.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      print('Error checking active shift: $e');
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(content: Text('Lỗi khi kiểm tra ca làm việc đang hoạt động: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }


  Future<void> _loadSanPham() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await Provider.of<SanPhamProvider>(context, listen: false).layDanhSachSanPham();
    } catch (e) {
      print('HomeScreen: Lỗi khi tải sản phẩm: $e');
      if (context.mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Không tải được sản phẩm. Vui lòng thử lại.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterSanPham(String query) {
    final sanPhamProvider = Provider.of<SanPhamProvider>(
      context,
      listen: false,
    );
    List<Map<String, dynamic>> allSanPham = sanPhamProvider.sanPhamList;
    setState(() {
      filteredSanPhamList =
          allSanPham
              .where(
                (sp) => sp['ten'].toLowerCase().contains(query.toLowerCase()),
          )
              .toList();
    });
  }

  void _logout() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => LoginScreen()),
          (route) => false,
    );
  }

  void _xoaSanPham(int id) async {
    if (widget.userRole == "Quản lý") {
      try {
        final dbHelper = DatabaseHelper.instance;
        await dbHelper.deleteSanPham(id);
        Provider.of<SanPhamProvider>(
          context,
          listen: false,
        ).layDanhSachSanPham();
      } catch (e) {
        print("Lỗi khi xóa sản phẩm: $e");
        if (context.mounted) {
          _scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('Không xóa được sản phẩm.'),
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    }
  }

  void _themSanPhamMoi(Map<String, dynamic> sanPham) async {
    try {
      final dbHelper = DatabaseHelper.instance;
      final newId = await dbHelper.insertSanPham(sanPham);
      sanPham['id'] = newId;
      Provider.of<SanPhamProvider>(context, listen: false).layDanhSachSanPham();
    } catch (e) {
      print("Lỗi khi thêm sản phẩm: $e");
      if (context.mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Không thêm được sản phẩm.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    }
  }


  Future<void> _selectAndPayProduct(
      BuildContext context,
      Map<String, dynamic> selectedSanPham,
      ) async {
    if (!_isShiftActive && widget.userRole != "Quản lý") {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Vui lòng bắt đầu ca làm việc trước khi bán hàng.'),
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PaymentScreen(
          product: selectedSanPham,
          onPaymentComplete: (product) {
            _refreshAllData();
          },
          updateRevenue: (amount) {
            _capNhatDoanhThuCaLamViecVaoDatabase(amount);
          },
          currentShiftId: widget.userRole == "Quản lý" ? null : _currentShiftId,
        ),
      ),
    );

    if (result == true) {
      _refreshAllData();
      _loadTotalRevenue();
    }
  }

  Future<void> _loadTotalRevenue() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      totalRevenue = await dbHelper.getTongDoanhThu();
      if (_currentShiftId != null) {
        final duLieuCaHienTai = await dbHelper.getShiftById(_currentShiftId!);
        if (duLieuCaHienTai != null) {
          _currentShiftTotalRevenue = duLieuCaHienTai['totalRevenue'] as double? ?? 0.0;
        }
      }
    } catch (e) {
      print('HomeScreen: Lỗi khi tải doanh thu: $e');
      if (context.mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Không tải được doanh thu.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
      setState(() {
        totalRevenue = 0.0;
        _currentShiftTotalRevenue = 0.0;
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _updateDoanhThu() {
    _loadTotalRevenue();
  }

  Future<void> _startShift() async {
    if (_isShiftActive) {
      _scaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(
          content: Text('Bạn đã có một ca làm việc đang hoạt động.'),
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    double? initialCash = await _showInitialCashDialog();
    if (initialCash == null) {
      return;
    }
    _initialCash = initialCash;

    setState(() {
      _isLoading = true;
    });
    try {
      final dbHelper = DatabaseHelper.instance;
      final newShiftId = await dbHelper.insertShift({
        'userId': widget.userId,
        'startTime': DateTime.now().toIso8601String(),
        'endTime': null,
        'initialCash': _initialCash,
        'finalCash': null,
        'totalRevenue': 0.0,
      });

      setState(() {
        _currentShiftId = newShiftId;
        _isShiftActive = true;
        _currentShiftTotalRevenue = 0.0;
      });
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Ca làm việc #${_currentShiftId} đã bắt đầu.'),
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      print('Error starting shift: $e');
      _scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Không thể bắt đầu ca làm việc.'),
          duration: Duration(seconds: 3),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _refreshAllData() async {
    await _loadSanPham();
    await _loadTotalRevenue();
  }

  Future<double?> _showInitialCashDialog() async {
    String? cashAmount;
    return showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tiền mặt ban đầu của ca'),
          content: TextField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              hintText: 'Nhập số tiền mặt hiện có trong két',
            ),
            onChanged: (value) {
              cashAmount = value;
            },
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
            ),
            TextButton(
              child: const Text('Bắt đầu'),
              onPressed: () {
                final double? amount = double.tryParse(cashAmount ?? '0');
                if (amount != null && amount >= 0) {
                  Navigator.of(dialogContext).pop(amount);
                } else {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số tiền hợp lệ.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  Future<double?> _showFinalCashDialog(double initialCash, double shiftRevenue) async {
    String? finalCashAmount;
    final expectedCash = initialCash + shiftRevenue;

    return showDialog<double?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Kết thúc ca làm việc'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tiền mặt ban đầu: ${NumberFormat("#,###", "vi_VN").format(initialCash)} VNĐ'),
              Text('Doanh thu trong ca: ${NumberFormat("#,###", "vi_VN").format(shiftRevenue)} VNĐ'),
              Text('Tổng tiền mặt dự kiến: ${NumberFormat("#,###", "vi_VN").format(expectedCash)} VNĐ'),
              const SizedBox(height: 10),
              TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  hintText: 'Nhập số tiền mặt cuối ca thực tế',
                ),
                onChanged: (value) {
                  finalCashAmount = value;
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop(null);
              },
            ),
            TextButton(
              child: const Text('Kết thúc ca'),
              onPressed: () {
                final double? amount = double.tryParse(finalCashAmount ?? '0');
                if (amount != null && amount >= 0) {
                  Navigator.of(dialogContext).pop(amount);
                } else {
                  _scaffoldMessengerKey.currentState?.showSnackBar(
                    const SnackBar(
                      content: Text('Vui lòng nhập số tiền hợp lệ.'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }


  void _showMoreOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => Navigator.pop(context),
          child: Align(
            alignment: Alignment.topRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(15),
                    bottomLeft: Radius.circular(15),
                  ),
                  boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (widget.userRole == "Quản lý") ...[
                      ListTile(
                        leading: Icon(Icons.bar_chart, color: Colors.blue),
                        title: Text('Thống kê doanh thu'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RevenueReportScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.trending_up, color: Colors.green),
                        title: Text('Sản phẩm bán chạy & Lợi nhuận'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const BestSellingProductsScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.receipt),
                        title: const Text('Lịch sử hóa đơn'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) => const ReceiptHistoryScreen()),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.store),
                        title: Text('Quản lý tồn kho'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => InventoryScreen(
                                userRole: widget.userRole,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.people),
                        title: Text('Quản lý nhân viên'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => UserManagementScreen(),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.history_toggle_off),
                        title: Text('Báo cáo ca làm việc'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShiftReportScreen(employeeId: null),
                            ),
                          );
                        },
                      ),
                    ],
                    if (widget.userRole == "Nhân viên") ...[
                      ListTile(
                        leading: Icon(_isShiftActive ? Icons.timer_off : Icons.timer),
                        title: Text(_isShiftActive ? 'Kết thúc ca làm việc' : 'Bắt đầu ca làm việc'),
                        onTap: () {
                          Navigator.pop(context);
                          if (_isShiftActive) {
                            _endShift();
                          } else {
                            _startShift();
                          }
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.history),
                        title: Text('Xem báo cáo ca làm việc của tôi'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ShiftReportScreen(employeeId: widget.userId),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.store),
                        title: Text('Xem tồn kho'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder:
                                  (context) => InventoryScreen(
                                userRole: widget.userRole,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: const Icon(Icons.notifications),
                        title: const Text('Thông báo'),
                        trailing: _unreadNotificationCount > 0
                            ? CircleAvatar(
                          radius: 12,
                          backgroundColor: Colors.red,
                          child: Text(
                            '$_unreadNotificationCount',
                            style: const TextStyle(color: Colors.white, fontSize: 10),
                          ),
                        )
                            : null,
                        onTap: () async {
                          Navigator.pop(context);
                          if (widget.userRole == 'Quản lý') {
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => ManagerNotificationScreen(managerId: widget.userId)),
                            );
                          } else { // Nhân viên
                            await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => EmployeeNotificationScreen(userId: widget.userId)),
                            );
                          }
                          _loadUnreadNotificationCount(); // Tải lại số thông báo chưa đọc sau khi quay lại
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.qr_code_scanner),
                        title: Text('Quét sản phẩm để tính tiền'),
                        onTap: () {
                          Navigator.pop(context);
                          if (!_isShiftActive && widget.userRole != "Quản lý") {
                            _scaffoldMessengerKey.currentState?.showSnackBar(
                              const SnackBar(
                                content: Text('Vui lòng bắt đầu ca làm việc trước khi bán hàng.'),
                                duration: Duration(seconds: 3),
                              ),
                            );
                            return;
                          }
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BarcodeScannerScreen(
                                userRole: widget.userRole,
                                forPayment: true,
                                onUpdateShiftRevenue: (soTien) {
                                  _capNhatDoanhThuCaLamViecVaoDatabase(soTien);
                                },
                                currentShiftId: _currentShiftId,
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                    ListTile(
                      leading: Icon(Icons.group),
                      title: Text('Quản lý khách hàng'),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const CustomerManagementScreen(),
                          ),
                        );
                      },
                    ),
                    ListTile(
                      leading: Icon(Icons.logout, color: Colors.red),
                      title: Text(
                        'Đăng xuất',
                        style: TextStyle(color: Colors.red),
                      ),
                      onTap: () {
                        Navigator.pop(context);
                        _logout();
                      },
                    ),
                    Divider(),
                    ListTile(
                      leading: Icon(Icons.close, color: Colors.black54),
                      title: Text('Đóng'),
                      onTap: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: _filterSanPham,
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm sản phẩm...',
                  hintStyle: TextStyle(color: Colors.white70),
                  prefixIcon: Icon(Icons.search, color: Colors.white),
                  border: InputBorder.none,
                ),
                style: TextStyle(color: Colors.white),
              ),
            ),
            Stack(
              children: [
                IconButton(
                  icon: const Icon(Icons.notifications, color: Colors.white),
                  onPressed: () async {
                    if (widget.userRole == 'Quản lý') {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ManagerNotificationScreen(managerId: widget.userId)),
                      );
                    } else {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EmployeeNotificationScreen(userId: widget.userId)),
                      );
                    }
                    _loadUnreadNotificationCount();
                  },
                ),
                if (_unreadNotificationCount > 0)
                  Positioned(
                    right: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      constraints: const BoxConstraints(
                        minWidth: 14,
                        minHeight: 14,
                      ),
                      child: Text(
                        '$_unreadNotificationCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
              ],
            ),
            IconButton(
              icon: Icon(Icons.account_circle, color: Colors.white),
              onPressed: () {
                _showMoreOptions(context);
              },
            ),
          ],
        ),
      ),
      body:
      _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Consumer<SanPhamProvider>(
        builder: (context, sanPhamProvider, _) {
          final List<Map<String, dynamic>> filteredSanPhamList =
          sanPhamProvider.sanPhamList
              .where(
                (sp) =>
            searchController.text.isEmpty ||
                sp['ten'].toLowerCase().contains(
                  searchController.text.toLowerCase(),
                ),
          )
              .toList();
          if (filteredSanPhamList.isEmpty) {
            return const Center(
              child: Text('Không tìm thấy sản phẩm!'),
            );
          }
          return GridView.builder(
            padding: EdgeInsets.all(10),
            gridDelegate:
            const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.75,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: filteredSanPhamList.length,
            itemBuilder: (context, index) {
              final sanPham = filteredSanPhamList[index];
              double gia = 0.0;
              try {
                gia = double.parse(sanPham['gia'].toString());
              } catch (e) {
                print('HomeScreen: Lỗi khi parse giá cho ${sanPham['ten']}: $e');
              }
              return GestureDetector(
                onTap: () {
                  _selectAndPayProduct(context, sanPham);
                },
                child: Card(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child:
                        sanPham['hinhAnh'] != null &&
                            sanPham['hinhAnh'].isNotEmpty
                            ? (sanPham['hinhAnh'].startsWith('http')
                            ? Image.network(
                          sanPham['hinhAnh'],
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            );
                          },
                        )
                            : Image.file(
                          File(sanPham['hinhAnh']),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          errorBuilder: (
                              context,
                              error,
                              stackTrace,
                              ) {
                            return const Icon(
                              Icons.image_not_supported,
                              size: 80,
                              color: Colors.grey,
                            );
                          },
                        ))
                            : const Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              sanPham['ten'],
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 5),
                            Text(
                              'Giá: ${NumberFormat("#,###", "vi_VN").format(double.tryParse(sanPham['gia'].toString()) ?? 0)} VNĐ',
                              style: const TextStyle(
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (widget.userRole == "Quản lý")
                        Row(
                          mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                          children: [
                            TextButton.icon(
                              icon: const Icon(
                                Icons.auto_fix_normal_outlined,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Sửa',
                                style: TextStyle(color: Colors.blue),
                              ),
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder:
                                        (context) => ThemSanPhamScreen(
                                      sanPhamToEdit: sanPham,
                                      onSanPhamAdded:
                                      _themSanPhamMoi,
                                      userRole: widget.userRole,
                                    ),
                                  ),
                                );
                              },
                            ),
                            TextButton.icon(
                              icon: const Icon(
                                Icons.delete,
                                color: Colors.black,
                              ),
                              label: const Text(
                                'Xóa',
                                style: TextStyle(color: Colors.red),
                              ),
                              onPressed: () {
                                _showDeleteConfirmationDialog(
                                  context,
                                  sanPham['id'],
                                );
                              },
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: (widget.userRole == "Quản lý")
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThemSanPhamScreen(
                onSanPhamAdded: _themSanPhamMoi,
                userRole: widget.userRole,
                isForPayment: false,
                sanPhamToEdit: null,
                onProductSelected: null,
              ),
            ),
          );
        },
        child: const Icon(Icons.add),
        tooltip: 'Thêm sản phẩm mới',
      )
          : null,
    );
  }



  void _showDeleteConfirmationDialog(BuildContext context, int sanPhamId) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Xác nhận xóa'),
          content: const Text('Bạn có chắc chắn muốn xóa sản phẩm này không?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Hủy'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Xóa'),
              onPressed: () {
                _xoaSanPham(sanPhamId);
                Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
