import 'dart:io';
import 'package:base_project/database/database_helper.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'ThemSanPhamScreen.dart';
import 'login_screen.dart';
import 'revenue_report_screen.dart';
import 'package:base_project/screens/product_screen.dart';
import 'package:base_project/screens/product_detail_screen.dart';
import 'package:base_project/screens/barcode_scanner_screen.dart';

class HomeScreen extends StatefulWidget {
  final String userRole;

  const HomeScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Map<String, dynamic>> sanPhamList = [];
  List<Map<String, dynamic>> filteredSanPhamList = [];
  TextEditingController searchController = TextEditingController();
  double totalRevenue = 0;

  @override
  void initState() {
    super.initState();
    _loadSanPham();
    _loadTotalRevenue();
  }

  Future<void> _loadSanPham() async {
    final data = await DatabaseHelper.instance.getAllSanPham();
    setState(() {
      sanPhamList = data;
      filteredSanPhamList = List.from(data);
    });
  }

  void _filterSanPham(String query) {
    setState(() {
      filteredSanPhamList = sanPhamList
          .where((sp) => sp['ten'].toLowerCase().contains(query.toLowerCase()))
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
      await DatabaseHelper.instance.deleteSanPham(id);
      _loadSanPham();
    }
  }

  void _themSanPhamMoi(Map<String, dynamic> sanPham) {
    setState(() {
      sanPhamList.add(sanPham);
      filteredSanPhamList = List.from(sanPhamList);
    });
  }

  Future<void> _selectAndPayProduct(BuildContext context, Map<String, dynamic> selectedSanPham) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(
          sanPham: selectedSanPham,
          onThanhToan: () {
            setState(() {
              _updateDoanhThu();
            });
          },
          userRole: widget.userRole,
        ),
      ),
    );

    if (result == true) {
      _loadTotalRevenue();
    }
  }

  Future<void> _loadTotalRevenue() async {
    double revenue = await DatabaseHelper.instance.getTongDoanhThu();
    setState(() {
      totalRevenue = revenue;
    });
  }

  void _updateDoanhThu() {
    _loadTotalRevenue();
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
                        leading: Icon(Icons.add),
                        title: Text('Thêm sản phẩm'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ThemSanPhamScreen(
                                onSanPhamAdded: _themSanPhamMoi,
                                userRole: widget.userRole,
                              ),
                            ),
                          );
                        },
                      ),
                      ListTile(
                        leading: Icon(Icons.bar_chart, color: Colors.blue),
                        title: Text('Thống kê doanh thu'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => RevenueScreen(),
                            ),
                          );
                        },
                      ),
                    ],
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
                    if (widget.userRole != "Quản lý") // Kiểm tra quyền
                      ListTile(
                        leading: Icon(Icons.qr_code_scanner),
                        title: Text('Quét sản phẩm'),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BarcodeScannerScreen(
                                onProductScanned: (product) {
                                  // Xử lý sản phẩm được quét ở đây
                                  print('Sản phẩm được quét: ${product['ten']}, ${product['gia']}');
                                  // Ví dụ: Thêm vào giỏ hàng, hiển thị thông tin, v.v.
                                },
                                userRole: widget.userRole, // Truyền userRole
                              ),
                            ),
                          );
                        },
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
            IconButton(
              icon: Icon(Icons.account_circle, color: Colors.white),
              onPressed: () {
                _showMoreOptions(context);
              },
            ),
          ],
        ),
      ),
      body: filteredSanPhamList.isEmpty
          ? Center(child: Text('Không tìm thấy sản phẩm!'))
          : GridView.builder(
        padding: EdgeInsets.all(10),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
        ),
        itemCount: filteredSanPhamList.length,
        itemBuilder: (context, index) {
          final sanPham = filteredSanPhamList[index];
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
                    child: sanPham['hinhAnh'] != null && sanPham['hinhAnh'].isNotEmpty
                        ? (sanPham['hinhAnh'].startsWith('http')
                        ? Image.network(
                      sanPham['hinhAnh'],
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
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
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.image_not_supported,
                          size: 80,
                          color: Colors.grey,
                        );
                      },
                    ))
                        : Icon(
                      Icons.image_not_supported,
                      size: 80,
                      color: Colors.grey,
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          sanPham['ten'],
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Giá: ${NumberFormat("#,###", "vi_VN").format(double.tryParse(sanPham['gia'].toString()) ?? 0)} VNĐ',
                          style: TextStyle(color: Colors.black),
                        ),
                      ],
                    ),
                  ),
                  if (widget.userRole == "Quản lý")
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        TextButton.icon(
                          icon: Icon(Icons.auto_fix_normal_outlined, color: Colors.black),
                          label: Text(
                            'Sửa',
                            style: TextStyle(color: Colors.blue),
                          ),
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ThemSanPhamScreen(
                                  sanPhamToEdit: sanPham,
                                  onSanPhamAdded: _themSanPhamMoi,
                                  userRole: widget.userRole,
                                ),
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          icon: Icon(Icons.delete, color: Colors.black),
                          label: Text(
                            'Xóa',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () {
                            _showDeleteConfirmationDialog(context, sanPham['id']);
                          },
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton(
            child: Icon(Icons.list),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductScreen(userRole: widget.userRole),
                ),
              );
            },
          ),
          if (widget.userRole == "Quản lý")
            Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FloatingActionButton(
                child: Icon(Icons.add),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ThemSanPhamScreen(
                        onSanPhamAdded: _themSanPhamMoi,
                        userRole: widget.userRole,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmationDialog(BuildContext context, int? id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: false, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Xác nhận xóa sản phẩm'),
          content: SingleChildScrollView(
            child: ListBody(
              children: <Widget>[
                Text('Bạn chắc chắn muốn xóa sản phẩm này?'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Hủy'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Xóa'),
              onPressed: () {
                Navigator.of(context).pop();
                _xoaSanPham(id!);
              },
            ),
          ],
        );
      },
    );
  }
}