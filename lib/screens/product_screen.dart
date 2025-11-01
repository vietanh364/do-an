import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:base_project/screens/PaymentScreen.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'SanPhamProvider.dart';
import 'ThemSanPhamScreen.dart';

class ProductScreen extends StatefulWidget {
  final String userRole;
  final bool isShiftActive;
  final int? currentShiftId;

  ProductScreen({
    required this.userRole,
    this.isShiftActive = false,
    this.currentShiftId,
  });

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SanPhamProvider>(context, listen: false).layDanhSachSanPham();
    });
  }

  void _onSanPhamAdded(Map<String, dynamic> sanPham) {
    Provider.of<SanPhamProvider>(context, listen: false).layDanhSachSanPham();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã thêm sản phẩm "${sanPham['ten']}" thành công!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sanPhamProvider = Provider.of<SanPhamProvider>(context);
    final sanPhamList = sanPhamProvider.sanPhamList;

    return Scaffold(
      appBar: AppBar(title: const Text('Danh sách sản phẩm')),
      body: sanPhamList.isEmpty
          ? const Center(child: Text('Chưa có sản phẩm nào'))
          : ListView.builder(
        itemCount: sanPhamList.length,
        itemBuilder: (context, index) {
          final sanPham = sanPhamList[index];
          double gia = 0.0;

          try {
            gia = double.parse(sanPham['gia'].toString());
          } catch (e) {
            print(
                'ProductScreen: Error parsing price for ${sanPham['ten']}: $e');
          }

          return ListTile(
            title: Text(sanPham['ten'] ?? 'Không có tên'),
            subtitle: Text(
              'Giá: ${NumberFormat("#,###", "vi_VN").format(gia)} VNĐ',
            ),
            trailing: const Icon(Icons.arrow_forward),
            onTap: () async {
              print(
                  'ProductScreen: Tapped on ${sanPham['ten']} (id: ${sanPham['id']})');

              if (widget.userRole == "Nhân viên" &&
                  !widget.isShiftActive) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                        'Vui lòng bắt đầu ca làm việc trước khi bán hàng.'),
                    duration: Duration(seconds: 3),
                  ),
                );
                return;
              }
              final bool? paymentSuccessful = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => PaymentScreen(
                    product: sanPham,
                    onPaymentComplete: (product) {
                      print(
                          'ProductScreen: Payment completed for ${product['ten']}.');
                      Provider.of<SanPhamProvider>(context, listen: false)
                          .layDanhSachSanPham();
                    },
                    updateRevenue: (amount) {
                      print('ProductScreen: Updated revenue by $amount');
                    },
                    currentShiftId: widget
                        .currentShiftId,
                  ),
                ),
              );

              if (paymentSuccessful == true) {
                Provider.of<SanPhamProvider>(context, listen: false)
                    .layDanhSachSanPham();
              }
            },
          );
        },
      ),
      // Nút dấu + nổi (Floating Action Button)
      floatingActionButton: (widget.userRole == "Quản lý")
          ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ThemSanPhamScreen(
                onSanPhamAdded: _onSanPhamAdded,
                userRole: widget.userRole,
                isForPayment: false,
                sanPhamToEdit: null,
                onProductSelected: null,
              ),
            ),
          );
        },
        child: Icon(Icons.add),
        tooltip: 'Thêm sản phẩm mới',
      )
          : null, // Chỉ hiển thị nếu userRole là "Quản lý"
    );
  }
}
