import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onProductScanned;
  final String userRole; // Add userRole

  BarcodeScannerScreen({
    Key? key,
    required this.onProductScanned,
    required this.userRole,
  }) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  String? barcode;
  Map<String, dynamic>? scannedProduct;
  MobileScannerController cameraController = MobileScannerController();

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quét sản phẩm')),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: MobileScanner(
              controller: cameraController,
              onDetect: (capture) async {
                final List<Barcode> barcodes = capture.barcodes;
                if (barcodes.isNotEmpty) {
                  String scannedBarcode = barcodes.first.rawValue!;
                  if (scannedBarcode != barcode) {
                    setState(() {
                      barcode = scannedBarcode;
                      scannedProduct = null;
                    });

                    try {

                      scannedProduct = await DatabaseHelper.instance.getSanPhamByMaVach(scannedBarcode);
                      if (mounted) {
                        setState(() {});
                      }
                    } catch (e) {
                      print('Lỗi khi tìm sản phẩm theo mã vạch: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Không tìm thấy sản phẩm có mã vạch này.')),
                        );
                      }
                    }
                  }
                }
              },
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Mã vạch: ${barcode ?? '---'}',
                        style: TextStyle(fontSize: 16),
                      ),
                      SizedBox(height: 10),
                      if (scannedProduct != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tên sản phẩm: ${scannedProduct!['ten']}'),
                            Text('Giá: ${NumberFormat("#,###", "vi_VN").format(double.tryParse(scannedProduct!['gia'].toString()) ?? 0)} VNĐ'),
                            ElevatedButton(
                              onPressed: () {
                                // Thực hiện logic tính tiền ở đây
                                _thanhToanSanPham(context, scannedProduct!);
                              },
                              child: Text('Tính tiền'),
                            ),
                          ],
                        )
                      else if (barcode != null)
                        Text('Không tìm thấy sản phẩm. Vui lòng thử lại.'),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _thanhToanSanPham(BuildContext context, Map<String, dynamic> product) async {
    print('Tính tiền sản phẩm: ${product['ten']}, giá: ${product['gia']}');
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => PaymentScreen(product: product)),
    );
  }
}

class PaymentScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  PaymentScreen({required this.product});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Thanh toán')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Sản phẩm: ${product['ten']}'),
            Text('Giá: ${NumberFormat("#,###", "vi_VN").format(double.tryParse(product['gia'].toString()) ?? 0)} VNĐ'),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Thanh toán'),
            ),
          ],
        ),
      ),
    );
  }
}