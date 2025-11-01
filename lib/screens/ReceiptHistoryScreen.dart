import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';

class ReceiptHistoryScreen extends StatefulWidget {
  const ReceiptHistoryScreen({Key? key}) : super(key: key);

  @override
  _ReceiptHistoryScreenState createState() => _ReceiptHistoryScreenState();
}

class _ReceiptHistoryScreenState extends State<ReceiptHistoryScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _dbHelper.getTransactionsWithDate();
      setState(() {
        _transactions = data;
      });
    } catch (e) {
      print('Error loading transactions for history: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải lịch sử giao dịch: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  String _generateReceiptText(Map<String, dynamic> transactionDetails) {
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final NumberFormat currencyFormatter = NumberFormat("#,###", "vi_VN");
    final NumberFormat pointsFormatter = NumberFormat("0.00", "vi_VN");

    String receipt = '';
    receipt += '--- HÓA ĐƠN THANH TOÁN ---\n';
    receipt += 'Thời gian: ${dateFormatter.format(DateTime.parse(transactionDetails['thoiGian']))}\n';
    receipt += '---------------------------\n';
    receipt += 'Sản phẩm: ${transactionDetails['ten']}\n';
    receipt += 'Đơn giá: ${currencyFormatter.format(transactionDetails['gia'])} VNĐ\n';
    receipt += 'Số lượng: ${transactionDetails['soLuong']}\n';
    receipt += '---------------------------\n';
    receipt += 'TỔNG CỘNG: ${currencyFormatter.format(transactionDetails['total_price'])} VNĐ\n';
    receipt += 'Phương thức: ${transactionDetails['paymentMethod'] ?? 'Không rõ'}\n'; // Hiển thị phương thức thanh toán

    if (transactionDetails['customerId'] != null) {
      receipt += 'ID Khách hàng: ${transactionDetails['customerId']}\n';
    }
    receipt += '---------------------------\n';
    receipt += 'Cảm ơn quý khách!\n';
    receipt += '---------------------------\n';
    return receipt;
  }

  void _showReceiptDialog(Map<String, dynamic> transaction) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Chi tiết hóa đơn'),
          content: SingleChildScrollView(
            child: Text(
              _generateReceiptText(transaction),
              style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Đóng'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lịch sử hóa đơn'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transactions.isEmpty
          ? const Center(child: Text('Không có hóa đơn nào được lưu.'))
          : ListView.builder(
        itemCount: _transactions.length,
        itemBuilder: (context, index) {
          final transaction = _transactions[index];
          final transactionTime = DateTime.parse(transaction['thoiGian']);
          final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(transactionTime);
          final totalPrice = transaction['total_price'] as double? ?? 0.0;
          final paymentMethod = transaction['paymentMethod'] ?? 'Không rõ';

          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ListTile(
              title: Text('${transaction['ten']} x ${transaction['soLuong']}'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Tổng tiền: ${NumberFormat("#,###", "vi_VN").format(totalPrice)} VNĐ'),
                  Text('Thời gian: $formattedDate'),
                  Text('Phương thức: $paymentMethod'),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios),
              onTap: () => _showReceiptDialog(transaction),
            ),
          );
        },
      ),
    );
  }
}
