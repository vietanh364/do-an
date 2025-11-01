import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';

class BestSellingProductsScreen extends StatefulWidget {
  const BestSellingProductsScreen({Key? key}) : super(key: key);

  @override
  _BestSellingProductsScreenState createState() => _BestSellingProductsScreenState();
}

class _BestSellingProductsScreenState extends State<BestSellingProductsScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _bestSellingProducts = [];
  double _totalRevenue = 0.0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final products = await _dbHelper.getBestSellingProducts();
      final revenue = await _dbHelper.getTongDoanhThu();
      setState(() {
        _bestSellingProducts = products;
        _totalRevenue = revenue;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading best selling products or revenue: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải dữ liệu: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sản phẩm bán chạy & Lợi nhuận'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tổng doanh thu toàn hệ thống:',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${NumberFormat("#,###", "vi_VN").format(_totalRevenue)} VNĐ',
                      style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                  ],
                ),
              ),
            ),
            const Text(
              'Top 10 sản phẩm bán chạy nhất:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _bestSellingProducts.isEmpty
                  ? const Center(child: Text('Chưa có giao dịch nào để thống kê.'))
                  : ListView.builder(
                itemCount: _bestSellingProducts.length,
                itemBuilder: (context, index) {
                  final product = _bestSellingProducts[index];
                  final productName = product['product_name'] ?? 'Không rõ tên';
                  final totalQuantity = product['total_quantity_sold'] ?? 0;
                  final totalRevenue = product['total_revenue_from_product'] as double? ?? 0.0;

                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
                    elevation: 2,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueAccent,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      title: Text(
                        productName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Số lượng bán: $totalQuantity'),
                          Text(
                            'Doanh thu: ${NumberFormat("#,###", "vi_VN").format(totalRevenue)} VNĐ',
                            style: const TextStyle(color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
