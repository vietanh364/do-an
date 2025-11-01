import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';

class ShiftReportScreen extends StatefulWidget {
  final int? employeeId;


  const ShiftReportScreen({Key? key, this.employeeId}) : super(key: key);

  @override
  _ShiftReportScreenState createState() => _ShiftReportScreenState();
}

class _ShiftReportScreenState extends State<ShiftReportScreen> {
  late Future<List<Map<String, dynamic>>> _shiftsFuture;
  late Future<List<Map<String, dynamic>>> _transactionsFuture;

  @override
  void initState() {
    super.initState();
    _loadShifts();
  }

  void _loadShifts() {
    if (widget.employeeId == null) {
      _shiftsFuture = DatabaseHelper.instance.getAllShifts();
    } else {
      _shiftsFuture = DatabaseHelper.instance.getEmployeeShifts(widget.employeeId!);
    }
  }

  Future<List<Map<String, dynamic>>> _loadTransactionsForShift(int shiftId) async {
    return await DatabaseHelper.instance.getTransactionsForShift(shiftId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.employeeId == null ? 'Báo cáo tất cả ca làm việc' : 'Báo cáo ca làm việc của tôi'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _shiftsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Lỗi: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('Không có ca làm việc nào.'));
          } else {
            final shifts = snapshot.data!;
            return ListView.builder(
              itemCount: shifts.length,
              itemBuilder: (context, index) {
                final shift = shifts[index];
                final startTime = DateTime.parse(shift['startTime']);
                final endTime = shift['endTime'] != null ? DateTime.parse(shift['endTime']) : null;
                final initialCash = shift['initialCash'] as double? ?? 0.0;
                final finalCash = shift['finalCash'] as double? ?? 0.0;
                final totalRevenue = shift['totalRevenue'] as double? ?? 0.0;
                final cashDifference = finalCash - (initialCash + totalRevenue);

                return Card(
                  margin: const EdgeInsets.all(8.0),
                  child: ExpansionTile(
                    title: Text('Ca làm việc ID: ${shift['id']} - ${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}'),
                    subtitle: Text('Doanh thu ca: ${NumberFormat("#,###", "vi_VN").format(totalRevenue)} VNĐ'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Bắt đầu: ${DateFormat('dd/MM/yyyy HH:mm').format(startTime)}'),
                            Text('Kết thúc: ${endTime != null ? DateFormat('dd/MM/yyyy HH:mm').format(endTime) : 'Đang hoạt động'}'),
                            Text('Tiền mặt ban đầu: ${NumberFormat("#,###", "vi_VN").format(initialCash)} VNĐ'),
                            Text('Tiền mặt cuối ca: ${NumberFormat("#,###", "vi_VN").format(finalCash)} VNĐ'),
                            Text('Chênh lệch tiền mặt: ${NumberFormat("#,###", "vi_VN").format(cashDifference)} VNĐ',
                              style: TextStyle(color: cashDifference == 0 ? Colors.black : (cashDifference > 0 ? Colors.green : Colors.red)),
                            ),
                            const SizedBox(height: 10),
                            const Text('Giao dịch trong ca:', style: TextStyle(fontWeight: FontWeight.bold)),
                            FutureBuilder<List<Map<String, dynamic>>>(
                              future: _loadTransactionsForShift(shift['id']),
                              builder: (context, transactionSnapshot) {
                                if (transactionSnapshot.connectionState == ConnectionState.waiting) {
                                  return const CircularProgressIndicator();
                                } else if (transactionSnapshot.hasError) {
                                  return Text('Lỗi tải giao dịch: ${transactionSnapshot.error}');
                                } else if (!transactionSnapshot.hasData || transactionSnapshot.data!.isEmpty) {
                                  return const Text('Không có giao dịch nào trong ca này.');
                                } else {
                                  final transactions = transactionSnapshot.data!;
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: transactions.map((trans) {
                                      final transactionTime = DateTime.parse(trans['thoiGian']);
                                      final paymentMethod = trans['paymentMethod'] ?? 'Không rõ'; // Lấy phương thức thanh toán
                                      return Text(
                                        '- ${DateFormat('HH:mm').format(transactionTime)} (${paymentMethod}): ${trans['ten']} x ${trans['soLuong']} (${NumberFormat("#,###", "vi_VN").format(trans['gia'])} VNĐ/sp) = ${NumberFormat("#,###", "vi_VN").format(trans['gia'] * trans['soLuong'])} VNĐ',
                                      );
                                    }).toList(),
                                  );
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
