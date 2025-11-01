import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class PaymentScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic>) onPaymentComplete;
  final Function(double) updateRevenue;
  final int? currentShiftId;

  const PaymentScreen({
    Key? key,
    required this.product,
    required this.onPaymentComplete,
    required this.updateRevenue,
    this.currentShiftId,
  }) : super(key: key);

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _quantity = 1;
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _customerPhoneController = TextEditingController();
  Map<String, dynamic>? _selectedCustomer;
  bool _isLoadingCustomer = false;
  double _discountAmount = 0.0;
  final double _pointsToVNDRate = 1000.0;

  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  String _selectedPaymentMethod = 'Tiền mặt';

  @override
  void initState() {
    super.initState();
    _quantityController.text = _quantity.toString();
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _customerPhoneController.dispose();
    super.dispose();
  }

  double get _totalPrice {
    double gia = double.tryParse(widget.product['gia'].toString()) ?? 0.0;
    return (gia * _quantity) - _discountAmount;
  }

  Future<void> _searchCustomerByPhone() async {
    setState(() {
      _isLoadingCustomer = true;
      _selectedCustomer = null;
      _discountAmount = 0.0;
    });
    final String phone = _customerPhoneController.text.trim();
    if (phone.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vui lòng nhập số điện thoại để tìm kiếm.')),
        );
      }
      setState(() {
        _isLoadingCustomer = false;
      });
      return;
    }

    try {
      final customer = await DatabaseHelper.instance.getCustomerByPhone(phone);
      if (customer != null) {
        setState(() {
          _selectedCustomer = customer;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Đã tìm thấy khách hàng: ${customer['name']}')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Không tìm thấy khách hàng. Bạn có muốn thêm mới?')),
          );
          _showAddCustomerDialog(phone);
        }
      }
    } catch (e) {
      print('Error searching customer: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tìm khách hàng: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoadingCustomer = false;
      });
    }
  }

  Future<void> _showAddCustomerDialog(String initialPhone) async {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController phoneController = TextEditingController(text: initialPhone);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Thêm khách hàng mới'),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Tên khách hàng'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập tên khách hàng';
                    }
                    return null;
                  },
                ),
                TextFormField(
                  controller: phoneController,
                  decoration: const InputDecoration(labelText: 'Số điện thoại'),
                  keyboardType: TextInputType.phone,
                  readOnly: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Vui lòng nhập số điện thoại';
                    }
                    return null;
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newCustomerData = {
                    'name': nameController.text.trim(),
                    'phone': phoneController.text.trim(),
                    'points': 0.0,
                  };
                  try {
                    final newCustomerId = await DatabaseHelper.instance.insertCustomer(newCustomerData);
                    if (newCustomerId > 0) {
                      setState(() {
                        _selectedCustomer = {
                          'id': newCustomerId,
                          'name': newCustomerData['name'],
                          'phone': newCustomerData['phone'],
                          'points': newCustomerData['points'],
                        };
                      });
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm khách hàng mới và chọn.')),
                        );
                        Navigator.pop(context);
                      }
                    }
                  } catch (e) {
                    print('Error adding new customer: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi thêm khách hàng: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              child: const Text('Thêm'),
            ),
          ],
        );
      },
    );
  }

  void _applyPoints() {
    if (_selectedCustomer == null || _selectedCustomer!['points'] == null || (_selectedCustomer!['points'] as double) <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Khách hàng không có điểm hoặc không được chọn.')),
      );
      return;
    }

    double availablePoints = _selectedCustomer!['points'] as double;
    double maxDiscountFromPoints = availablePoints * _pointsToVNDRate;
    double currentBasePrice = (double.tryParse(widget.product['gia'].toString()) ?? 0.0) * _quantity;

    setState(() {
      _discountAmount = maxDiscountFromPoints;
      if (_discountAmount > currentBasePrice) {
        _discountAmount = currentBasePrice;
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Đã áp dụng ${NumberFormat("#,###", "vi_VN").format(_discountAmount)} VNĐ giảm giá từ điểm.')),
    );
  }

  Future<bool?> _showEwalletPaymentDialog(BuildContext context, double amount) async {
    return showDialog<bool?>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Thanh toán qua Ví điện tử'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tổng tiền: ${NumberFormat("#,###", "vi_VN").format(amount)} VNĐ',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
              const SizedBox(height: 20),
              Image.asset(
                'assets/images/b03f976a88b43dea64a5.jpg',
                width: 200,
                height: 200,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.qr_code_2, size: 100, color: Colors.grey);
                },
              ),
              const SizedBox(height: 20),
              const Text('Vui lòng quét mã QR này bằng ứng dụng ví điện tử của bạn để hoàn tất thanh toán.'),
              const SizedBox(height: 10),
              const CircularProgressIndicator(),
              const SizedBox(height: 10),
              const Text('Đang chờ xác nhận thanh toán...'),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Hủy thanh toán'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              child: const Text('Mô phỏng thành công'),
            ),
          ],
        );
      },
    );
  }

  String _generateReceiptText(Map<String, dynamic> transactionDetails, String paymentMethod) {
    final DateTime now = DateTime.now();
    final DateFormat dateFormatter = DateFormat('dd/MM/yyyy HH:mm:ss');
    final NumberFormat currencyFormatter = NumberFormat("#,###", "vi_VN");
    final NumberFormat pointsFormatter = NumberFormat("0.00", "vi_VN");

    String receipt = '';
    receipt += '--- HÓA ĐƠN THANH TOÁN ---\n';
    receipt += 'Thời gian: ${dateFormatter.format(now)}\n';
    receipt += '---------------------------\n';
    receipt += 'Sản phẩm: ${transactionDetails['ten']}\n';
    receipt += 'Đơn giá: ${currencyFormatter.format(transactionDetails['gia'])} VNĐ\n';
    receipt += 'Số lượng: ${transactionDetails['soLuong']}\n';
    receipt += '---------------------------\n';
    if (_discountAmount > 0) {
      receipt += 'Giảm giá: -${currencyFormatter.format(_discountAmount)} VNĐ\n';
    }
    receipt += 'TỔNG CỘNG: ${currencyFormatter.format(_totalPrice)} VNĐ\n';
    receipt += 'Phương thức: $paymentMethod\n';
    if (_selectedCustomer != null) {
      // Tính toán điểm mới sau giao dịch
      double pointsEarned = _totalPrice / 10000.0;
      double pointsUsed = _discountAmount / _pointsToVNDRate;
      double newPoints = (_selectedCustomer!['points'] ?? 0.0) + pointsEarned - pointsUsed;
      if (newPoints < 0) newPoints = 0;

      receipt += 'Khách hàng: ${_selectedCustomer!['name']} (${_selectedCustomer!['phone']})\n';
      receipt += 'Điểm tích lũy mới: ${pointsFormatter.format(newPoints)} điểm\n';
    }
    receipt += '---------------------------\n';
    receipt += 'Cảm ơn quý khách!\n';
    receipt += '---------------------------\n';
    return receipt;
  }

  Future<void> _showReceiptDialog(String receiptText) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Hóa đơn đã in'),
          content: SingleChildScrollView(
            child: Text(
              receiptText,
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
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
              child: const Text('In ra máy in (Mô phỏng)'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _handlePayment(BuildContext context, String paymentMethod) async {
    int id = widget.product['id'];
    String ten = widget.product['ten'];
    double gia = 0.0;

    try {
      gia = double.parse(widget.product['gia'].toString());
    } catch (e) {
      print('PaymentScreen: Lỗi khi parse giá: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Lỗi: Giá sản phẩm không hợp lệ.'),
            backgroundColor: Colors.red,
            duration: Duration(seconds: 2),
          ),
        );
        Future.microtask(() {
          if (context.mounted) {
            Navigator.pop(context, false);
          }
        });
      }
      return;
    }

    int currentStock = (widget.product['soLuong'] as int? ?? 0);
    if (_quantity <= 0) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Số lượng phải lớn hơn 0.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 2),
          ),
        );
        Future.microtask(() {
          if (context.mounted) {
            Navigator.pop(context, false);
          }
        });
      }
      return;
    }
    if (_quantity > currentStock) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Không đủ số lượng sản phẩm trong kho để thanh toán.'),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
        Future.microtask(() {
          if (context.mounted) {
            Navigator.pop(context, false);
          }
        });
      }
      return;
    }

    double finalPrice = _totalPrice;

    print('PaymentScreen: Bắt đầu xử lý thanh toán.');
    print('PaymentScreen: _selectedCustomer: $_selectedCustomer');
    print('PaymentScreen: customerId được truyền: ${_selectedCustomer?['id']}');
    print('PaymentScreen: Tổng tiền sản phẩm (sau giảm giá): $finalPrice');


    try {
      if (!context.mounted) return;

      bool? paymentSuccessful = true;

      if (paymentMethod == 'Ví điện tử') {
        paymentSuccessful = await _showEwalletPaymentDialog(context, finalPrice);
        if (paymentSuccessful == null || !paymentSuccessful) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Thanh toán Ví điện tử đã bị hủy hoặc không thành công.'),
                backgroundColor: Colors.orange,
                duration: Duration(seconds: 3),
              ),
            );
            Future.microtask(() {
              if (context.mounted) {
                Navigator.pop(context, false);
              }
            });
          }
          return;
        }
      }

      final int transactionId = await _dbHelper.thanhToanSanPhamTransaction(
        id,
        ten,
        gia,
        soLuong: _quantity,
        customerId: _selectedCustomer?['id'],
        paymentMethod: paymentMethod,
      );

      if (widget.currentShiftId != null) {
        await _dbHelper.insertShiftTransaction(widget.currentShiftId!, transactionId);
        print('Giao dịch $transactionId đã được liên kết với ca làm việc ${widget.currentShiftId}');
      }

      if (_discountAmount > 0 && _selectedCustomer != null) {
        double pointsUsed = _discountAmount / _pointsToVNDRate;
        await _dbHelper.updateCustomerPoints(_selectedCustomer!['id'], -pointsUsed);
        print('Đã trừ ${pointsUsed} điểm của khách hàng ${_selectedCustomer!['name']}');
      }

      widget.updateRevenue(finalPrice);
      widget.onPaymentComplete(widget.product);

      if (!context.mounted) return;
      final Map<String, dynamic> transactionDetails = {
        'ten': ten,
        'gia': gia,
        'soLuong': _quantity,
        'total_price': finalPrice,
      };
      await _showReceiptDialog(_generateReceiptText(transactionDetails, paymentMethod));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Đã thanh toán: $ten - ${NumberFormat("#,###", "vi_VN").format(finalPrice)} VNĐ (Số lượng: $_quantity) bằng $paymentMethod'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      if (context.mounted) {
        Navigator.pop(context, true);
      }

    } catch (e) {
      print('PaymentScreen: Lỗi khi thanh toán: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Có lỗi xảy ra trong quá trình thanh toán: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
        Future.microtask(() {
          if (context.mounted) {
            Navigator.pop(context, false);
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    double gia = double.tryParse(widget.product['gia'].toString()) ?? 0.0;
    double currentStock = (widget.product['soLuong'] as int? ?? 0).toDouble();

    final String? hinhAnhPath = widget.product['hinhAnh'] as String?;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Thanh toán sản phẩm'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hinhAnhPath != null && hinhAnhPath.isNotEmpty)
              Center(
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: hinhAnhPath.startsWith('http')
                      ? Image.network(
                    hinhAnhPath,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      );
                    },
                  )
                      : Image.file(
                    File(hinhAnhPath),
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Icon(
                        Icons.image_not_supported,
                        size: 80,
                        color: Colors.grey,
                      );
                    },
                  ),
                ),
              )
            else
              Center(
                child: Container(
                  height: 200,
                  width: 200,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade300),
                    color: Colors.grey.shade200,
                  ),
                  child: const Icon(
                    Icons.image_not_supported,
                    size: 80,
                    color: Colors.grey,
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              'Sản phẩm: ${widget.product['ten']}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              'Giá đơn vị: ${NumberFormat("#,###", "vi_VN").format(gia)} VNĐ',
              style: const TextStyle(fontSize: 18, color: Colors.red),
            ),
            const SizedBox(height: 10),
            Text(
              'Tồn kho hiện tại: ${NumberFormat("#,###", "vi_VN").format(currentStock)}',
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Số lượng: ',
                    style: TextStyle(fontSize: 18, color: Colors.purple),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove, color: Colors.purple),
                    onPressed: () {
                      setState(() {
                        if (_quantity > 1) {
                          _quantity--;
                          _quantityController.text = _quantity.toString();
                          _discountAmount = 0.0;
                        }
                      });
                    },
                  ),
                  SizedBox(
                    width: 50,
                    child: TextField(
                      controller: _quantityController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      onChanged: (value) {
                        setState(() {
                          _quantity = int.tryParse(value) ?? 0;
                          _discountAmount = 0.0;
                        });
                      },
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 0, vertical: 5),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.purple),
                    onPressed: () {
                      setState(() {
                        if (_quantity < (widget.product['soLuong'] as int? ?? 0)) {
                          _quantity++;
                          _quantityController.text = _quantity.toString();
                          _discountAmount = 0.0;
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Không thể thêm quá số lượng tồn kho.'),
                              duration: Duration(seconds: 1),
                            ),
                          );
                        }
                      });
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Tổng tiền: ${NumberFormat("#,###", "vi_VN").format(_totalPrice)} VNĐ',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.blue),
            ),
            const SizedBox(height: 30),
            const Divider(),
            const Text(
              'Thông tin khách hàng (Tích điểm):',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _customerPhoneController,
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    onChanged: (value) {
                      if (value.length == 10) {
                        FocusScope.of(context).unfocus();
                      }
                    },
                    decoration: const InputDecoration(
                      labelText: 'SĐT khách hàng',
                      border: OutlineInputBorder(),
                      counterText: "",
                    ),
                  ),
                ),
                _isLoadingCustomer
                    ? const Padding(
                  padding: EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(),
                )
                    : IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: _searchCustomerByPhone,
                ),
              ],
            ),
            if (_selectedCustomer != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tên: ${_selectedCustomer!['name']}'),
                    Text('Điểm tích lũy: ${NumberFormat("0.00", "vi_VN").format(_selectedCustomer!['points'] ?? 0.0)} điểm'),
                    ElevatedButton.icon(
                      onPressed: _applyPoints,
                      icon: const Icon(Icons.card_giftcard),
                      label: const Text('Áp dụng điểm'),
                    ),
                    if (_discountAmount > 0)
                      Text('Giảm giá từ điểm: -${NumberFormat("#,###", "vi_VN").format(_discountAmount)} VNĐ',
                        style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                      ),
                  ],
                ),
              ),
            const SizedBox(height: 20),
            const Text(
              'Chọn phương thức thanh toán:',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPaymentMethod = 'Tiền mặt';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPaymentMethod == 'Tiền mặt' ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Tiền mặt'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _selectedPaymentMethod = 'Ví điện tử';
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _selectedPaymentMethod == 'Ví điện tử' ? Colors.blue : Colors.grey,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  ),
                  child: const Text('Ví điện tử'),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () => _handlePayment(context, _selectedPaymentMethod),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
                  textStyle: const TextStyle(fontSize: 20),
                ),
                child: const Text('Thanh toán'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
