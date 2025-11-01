import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:fl_chart/fl_chart.dart';

class RevenueReportScreen extends StatefulWidget {
  @override
  RevenueReportScreenState createState() => RevenueReportScreenState();
}

class RevenueReportScreenState extends State<RevenueReportScreen> {
  List<Map<String, dynamic>> _transactions = [];
  double _totalRevenue = 0;
  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  int? _selectedDay;
  bool _isLoading = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

  Map<int, double> _dailyRevenue = {};

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
      final dbHelper = DatabaseHelper.instance;
      final data = await dbHelper.getTransactionsWithDate(
        year: _selectedYear,
        month: _selectedMonth,
        day: _selectedDay,
      );
      setState(() {
        _transactions = data;
        _calculateTotalRevenue();
        _aggregateDailyRevenue();
      });
    } catch (e) {
      print('RevenueScreen: Error loading transactions: $e');
      if (mounted) {
        _scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text('Lỗi khi tải dữ liệu doanh thu: ${e.toString()}'),
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

  void _calculateTotalRevenue() {
    _totalRevenue = 0;
    for (var transaction in _transactions) {
      if (transaction['total_price'] != null) {
        _totalRevenue += (transaction['total_price'] as num).toDouble();
      }
    }
  }

  void _aggregateDailyRevenue() {
    _dailyRevenue.clear();
    for (var transaction in _transactions) {
      if (transaction['thoiGian'] != null && transaction['total_price'] != null) {
        final transactionDateString = transaction['thoiGian'] as String;
        final transactionDate = DateTime.parse(transactionDateString);
        final dayOfMonth = transactionDate.day;
        final totalPrice = (transaction['total_price'] as num).toDouble();

        _dailyRevenue.update(dayOfMonth, (value) => value + totalPrice,
            ifAbsent: () => totalPrice);
      }
    }
  }

  void updateRevenue(double amount) {
    setState(() {
      _totalRevenue += amount;
    });
    _loadTransactions();
  }

  Widget _buildBarChart() {
    if (_dailyRevenue.isEmpty) {
      return const Center(
        child: Text('Không có dữ liệu doanh thu cho biểu đồ trong khoảng thời gian này.'),
      );
    }

    int maxDay = 0;
    if (_selectedDay != null) {
      maxDay = _selectedDay!;
    } else {
      maxDay = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
    }

    List<BarChartGroupData> barGroups = [];
    for (int i = 1; i <= maxDay; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: _dailyRevenue[i] ?? 0,
              color: Colors.blue,
              width: 10,
              borderRadius: BorderRadius.circular(2),
            ),
          ],
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.7,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        color: Colors.white,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: BarChart(
            BarChartData(
              barGroups: barGroups,
              titlesData: FlTitlesData(
                show: true,
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      if (value.toInt() % 5 == 0 || value.toInt() == maxDay || _dailyRevenue.containsKey(value.toInt())) {
                        return SideTitleWidget(
                          axisSide: meta.axisSide,
                          child: Text(value.toInt().toString(), style: const TextStyle(fontSize: 10)),
                        );
                      }
                      return const SizedBox();
                    },
                    interval: 1,
                    reservedSize: 22,
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (value, meta) {
                      return SideTitleWidget(
                        axisSide: meta.axisSide,
                        child: Text(
                          NumberFormat.compact(locale: 'vi_VN').format(value),
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                    reservedSize: 40,
                    interval: _dailyRevenue.values.isNotEmpty
                        ? (_dailyRevenue.values.reduce((a, b) => a > b ? a : b) / 4).ceilToDouble()
                        : 100000,
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: const Color(0xff37434d), width: 1),
              ),
              gridData: const FlGridData(show: true),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      'Ngày ${group.x.toInt()}:\n',
                      const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      children: <TextSpan>[
                        TextSpan(
                          text: '${NumberFormat("#,###", "vi_VN").format(rod.toY)} VNĐ',
                          style: const TextStyle(
                            color: Colors.yellow,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(title: const Text('Thống kê doanh thu')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DropdownButton<int>(
                  value: _selectedYear,
                  items: List.generate(10, (index) => DateTime.now().year - 5 + index)
                      .map((year) => DropdownMenuItem(
                    value: year,
                    child: Text('$year'),
                  ))
                      .toList(),
                  onChanged: (year) {
                    setState(() {
                      _selectedYear = year!;
                      _selectedMonth = 1;
                      _selectedDay = null;
                      _loadTransactions();
                    });
                  },
                ),
                const SizedBox(width: 20),
                DropdownButton<int>(
                  value: _selectedMonth,
                  items: List.generate(12, (index) => index + 1)
                      .map((month) => DropdownMenuItem(
                    value: month,
                    child: Text('Tháng $month'),
                  ))
                      .toList(),
                  onChanged: (month) {
                    setState(() {
                      _selectedMonth = month!;
                      _selectedDay = null;
                      _loadTransactions();
                    });
                  },
                ),
                const SizedBox(width: 20),
                DropdownButton<int?>(
                  value: _selectedDay,
                  items: [
                    const DropdownMenuItem(value: null, child: Text('Tất cả ngày')),
                    ...List.generate(DateTime(_selectedYear, _selectedMonth + 1, 0).day, (index) => index + 1)
                        .map((day) => DropdownMenuItem(
                      value: day,
                      child: Text('Ngày $day'),
                    ))
                        .toList(),
                  ],
                  onChanged: (day) {
                    setState(() {
                      _selectedDay = day;
                      _loadTransactions();
                    });
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                :
            Text(
              'Tổng doanh thu: ${NumberFormat("#,###", "vi_VN").format(_totalRevenue)} VNĐ',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Expanded(
              flex: 2,
              child: _buildBarChart(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Chi tiết giao dịch:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              flex: 3,
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ListView.builder(
                itemCount: _transactions.length,
                itemBuilder: (context, index) {
                  final transaction = _transactions[index];
                  final timestamp = transaction['thoiGian'] is String
                      ? DateTime.parse(transaction['thoiGian'])
                      : DateTime.fromMillisecondsSinceEpoch(transaction['thoiGian']);
                  final formattedDate = DateFormat('dd/MM/yyyy HH:mm:ss').format(timestamp);

                  return ListTile(
                    title: Text('Sản phẩm: ${transaction['ten'] ?? 'Không có tên'}'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Giá: ${NumberFormat("#,###", "vi_VN").format(transaction['gia'] ?? 0)} VNĐ'),
                        Text('Số lượng: ${NumberFormat("#,###", "vi_VN").format(transaction['soLuong'] ?? 0)}'),
                        Text('Tổng tiền: ${NumberFormat("#,###", "vi_VN").format(transaction['total_price'] ?? 0)} VNĐ'),
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
