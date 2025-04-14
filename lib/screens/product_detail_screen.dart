import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:base_project/database/database_helper.dart';

class ProductDetailScreen extends StatelessWidget {
  final Map<String, dynamic> sanPham;
  final String userRole;
  final VoidCallback onThanhToan;

  const ProductDetailScreen({
    Key? key,
    required this.sanPham,
    required this.userRole,
    required this.onThanhToan,
  }) : super(key: key);

  Future<void> _handlePayment(BuildContext context) async {
    int id = sanPham['id'];
    String ten = sanPham['ten'];
    double gia = 0.0;

    try {
      gia = double.parse(sanPham['gia'].toString());
    } catch (e) {
      print('ProductDetailScreen: Lỗi khi parse giá: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Lỗi: Giá sản phẩm không hợp lệ.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    try {
      await DatabaseHelper.instance.thanhToanSanPham(id, ten, gia);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thanh toán: $ten - ${NumberFormat("#,###", "vi_VN").format(gia)} VNĐ'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      onThanhToan();
      Navigator.pop(context, true);
    } catch (e) {
      print('ProductDetailScreen: Lỗi khi thanh toán: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra trong quá trình thanh toán.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double gia = 0.0;
    try {
      gia = double.parse(sanPham['gia'].toString());
    } catch (e) {
      print('ProductDetailScreen: Lỗi khi parse giá trong build: $e');
    }

    return Scaffold(
      appBar: AppBar(title: Text('Chi tiết sản phẩm')),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              sanPham['ten'],
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            Text(
              'Giá: ${NumberFormat("#,###", "vi_VN").format(gia)} VNĐ',
              style: TextStyle(fontSize: 20, color: Colors.red),
            ),
            SizedBox(height: 30),
            Center(
              child: ElevatedButton(
                onPressed: () => _handlePayment(context),
                child: Text('Tính tiền'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}