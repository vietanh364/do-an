
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:base_project/database/database_helper.dart';

class RevenueScreen extends StatefulWidget {
  @override
  _RevenueScreenState createState() => _RevenueScreenState();
}

class _RevenueScreenState extends State<RevenueScreen> {
  List<Map<String, dynamic>> transactions = [];
  double totalRevenue = 0;
  int selectedYear = DateTime.now().year;
  int selectedMonth = DateTime.now().month;
  int? selectedDay;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    try {
      final data = await DatabaseHelper.instance.getTransactionsWithDate(
        year: selectedYear,
        month: selectedMonth,
        day: selectedDay,
      );
      setState(() {
        transactions = data;
        _calculateTotalRevenue();
      });
    } catch (e) {
      print('RevenueScreen: Error loading transactions: $e');
      // Handle error (e.g., show a SnackBar)
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải dữ liệu doanh thu.'), duration: Duration(seconds: 3)),
      );
    }
  }

  void _calculateTotalRevenue() {
    totalRevenue = 0;
    for (var transaction in transactions) {
      totalRevenue += (transaction['gia'] as num).toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thống kê doanh thu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<int>(
                  value: selectedYear,
                  items: List.generate(10, (index) => DateTime.now().year - 5 + index)
                      .map((year) => DropdownMenuItem(value: year, child: Text('$year')))
                      .toList(),
                  onChanged: (year) {
                    setState(() {
                      selectedYear = year!;
                      selectedMonth = 1;
                      selectedDay = null;
                      _loadTransactions();
                    });
                  },
                ),
                SizedBox(width: 20),
                DropdownButton<int>(
                  value: selectedMonth,
                  items: List.generate(12, (index) => index + 1)
                      .map((month) => DropdownMenuItem(value: month, child: Text('Tháng $month')))
                      .toList(),
                  onChanged: (month) {
                    setState(() {
                      selectedMonth = month!;
                      selectedDay = null;
                      _loadTransactions();
                    });
                  },
                ),
                SizedBox(width: 20),
                DropdownButton<int>(
                  value: selectedDay,
                  items: List.generate(31, (index) => index + 1)
                      .map((day) => DropdownMenuItem(value: day, child: Text('Ngày $day')))
                      .toList(),
                  onChanged: (day) {
                    setState(() {
                      selectedDay = day;
                      _loadTransactions();
                    });
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Text('Tổng doanh thu: ${NumberFormat("#,###", "vi_VN").format(totalRevenue)} VNĐ',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: transactions.length,
                itemBuilder: (context, index) {
                  final transaction = transactions[index];
                  final timestamp = transaction['thoiGian'] as int;
                  final transactionDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
                  final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(transactionDate);

                  return ListTile(
                    title: Text('Sản phẩm: ${transaction['ten'] ?? 'Không có tên'}'), // Handle null
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Giá: ${NumberFormat("#,###", "vi_VN").format(transaction['gia'] ?? 0)} VNĐ'), // Handle null
                        Text('Thời gian: $formattedDate'),
                      ],
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