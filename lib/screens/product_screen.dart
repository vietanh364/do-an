import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:base_project/screens/product_detail_screen.dart';
import 'package:intl/intl.dart';

class ProductScreen extends StatefulWidget {
  final String userRole;

  ProductScreen({required this.userRole});

  @override
  _ProductScreenState createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  List<Map<String, dynamic>> sanPhamList = [];

  @override
  void initState() {
    super.initState();
    _loadSanPhamList();
  }

  Future<void> _loadSanPhamList() async {
    try {
      final data = await DatabaseHelper.instance.getAllSanPham();
      setState(() {
        sanPhamList = data;
      });
      print('ProductScreen: Loaded ${sanPhamList.length} products.');
    } catch (e) {
      print('ProductScreen: Error loading product list: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Có lỗi xảy ra khi tải danh sách sản phẩm.'),
          backgroundColor: Colors.red,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print('ProductScreen: Building UI with ${sanPhamList.length} products.');

    return Scaffold(
      appBar: AppBar(title: Text('Danh sách sản phẩm')),
      body: sanPhamList.isEmpty
          ? Center(child: Text('Chưa có sản phẩm nào'))
          : ListView.builder(
        itemCount: sanPhamList.length,
        itemBuilder: (context, index) {
          final sanPham = sanPhamList[index];
          double gia = 0.0;

          try {
            gia = double.parse(sanPham['gia'].toString());
          } catch (e) {
            print('ProductScreen: Error parsing price for ${sanPham['ten']}: $e');
          }

          return ListTile(
            title: Text(sanPham['ten'] ?? 'Không có tên'),
            subtitle: Text(
              'Giá: ${NumberFormat("#,###", "vi_VN").format(gia)} VNĐ',
            ),
            trailing: Icon(Icons.arrow_forward),
            onTap: () {
              print('ProductScreen: Tapped on ${sanPham['ten']} (id: ${sanPham['id']})');
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProductDetailScreen(
                    sanPham: sanPham,
                    userRole: widget.userRole,
                    onThanhToan: () {
                      print('ProductScreen: onThanhToan callback called.');
                      _loadSanPhamList();
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}