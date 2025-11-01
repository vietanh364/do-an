import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'PaymentScreen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onProductScanned;
  final String userRole;
  final bool forPayment;

  final Function(double)? onUpdateShiftRevenue;
  final int? currentShiftId;

  const BarcodeScannerScreen({
    Key? key,
    this.onProductScanned,
    required this.userRole,
    this.forPayment = false,
    this.onUpdateShiftRevenue,
    this.currentShiftId,
  }) : super(key: key);

  @override
  _BarcodeScannerScreenState createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> with WidgetsBindingObserver {
  String? barcode;
  Map<String, dynamic>? scannedProduct;
  MobileScannerController? _cameraController;
  bool _isScanning = true;
  bool _productFound = false;
  final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();
  bool _isFlashOn = false;
  Future<MobileScannerController?>? _cameraInitializationFuture;
  bool _isCameraPreviewReady = false;

  @override
  void initState() {
    super.initState();
    print('BarcodeScannerScreen: initState được gọi.');
    WidgetsBinding.instance.addObserver(this);
    _cameraInitializationFuture = _initializeAndStartCamera();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) return;
    print('BarcodeScannerScreen: Trạng thái vòng đời ứng dụng thay đổi thành: $state');

    if (state == AppLifecycleState.inactive) {
      _stopAndDisposeCamera();
      setState(() {
        _isCameraPreviewReady = false;
      });
    } else if (state == AppLifecycleState.resumed) {
      _stopAndDisposeCamera().then((_) {
        Future.delayed(const Duration(seconds: 1), () {
          print('BarcodeScannerScreen: Đã tiếp tục, đang khởi tạo lại camera sau độ trễ ngắn.');
          _cameraInitializationFuture = _initializeAndStartCamera();
          setState(() {
            _isCameraPreviewReady = false;
          });
        });
      });
    }
  }

  Future<MobileScannerController?> _initializeAndStartCamera() async {
    print('BarcodeScannerScreen: _initializeAndStartCamera được gọi.');
    if (_cameraController != null) {
      print('BarcodeScannerScreen: Đã tìm thấy controller hiện có, đang dừng và giải phóng.');
      await _stopAndDisposeCamera();
    }

    _cameraController = MobileScannerController();
    int retryCount = 0;
    const int maxRetries = 3;
    const Duration retryDelay = Duration(seconds: 1);

    while (retryCount < maxRetries) {
      try {
        print('BarcodeScannerScreen: Đang cố gắng khởi động controller camera (thử lại ${retryCount + 1}/${maxRetries})...');
        await _cameraController!.start();
        print('BarcodeScannerScreen: Controller camera đã khởi động thành công.');

        await Future.delayed(const Duration(milliseconds: 500));

        if (mounted) {
          setState(() {
            _isScanning = true;
            _isCameraPreviewReady = true;
          });
          print('BarcodeScannerScreen: Preview sẵn sàng và quét đã được bật.');
        }
        return _cameraController;
      } catch (e) {
        print('BarcodeScannerScreen: LỖI khi khởi động camera (thử lại ${retryCount + 1}/${maxRetries}): ${e.toString()}');
        retryCount++;
        if (retryCount < maxRetries) {
          print('BarcodeScannerScreen: Đang đợi ${retryDelay.inSeconds} giây trước khi thử lại...');
          await Future.delayed(retryDelay);
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Không thể khởi động camera sau nhiều lần thử: ${e.toString()}. Vui lòng kiểm tra quyền truy cập camera trong cài đặt ứng dụng hoặc khởi động lại ứng dụng.')),
            );
          }
          if (mounted) {
            setState(() {
              _isScanning = false;
              _isCameraPreviewReady = false;
            });
          }
          return null;
        }
      }
    }
    return null;
  }

  Future<void> _stopAndDisposeCamera() async {
    print('BarcodeScannerScreen: _stopAndDisposeCamera được gọi.');
    try {
      if (_cameraController != null) {
        print('BarcodeScannerScreen: Đang cố gắng dừng và giải phóng controller camera...');
        await _cameraController!.stop();
        _cameraController!.dispose();
        _cameraController = null;
        await Future.delayed(const Duration(milliseconds: 100));
        print('BarcodeScannerScreen: Controller camera đã dừng và giải phóng.');
      }
    } catch (e) {
      print('BarcodeScannerScreen: LỖI khi dừng camera: ${e.toString()}');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi dừng camera: ${e.toString()}')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
          _isCameraPreviewReady = false;
        });
      }
    }
  }

  @override
  void dispose() {
    print('BarcodeScannerScreen: dispose được gọi.');
    WidgetsBinding.instance.removeObserver(this);
    _stopAndDisposeCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    print('BarcodeScannerScreen: Phương thức build được gọi.');
    return Scaffold(
      key: _scaffoldMessengerKey,
      appBar: AppBar(
        title: Text(widget.forPayment
            ? 'Quét sản phẩm để tính tiền'
            : 'Quét sản phẩm'),
        actions: [
          IconButton(
            icon: Icon(_isFlashOn ? Icons.flash_on : Icons.flash_off),
            onPressed: () {
              setState(() {
                _isFlashOn = !_isFlashOn;
              });
              print('BarcodeScannerScreen: Đang chuyển đổi đèn flash. Trạng thái mới: $_isFlashOn');
              _cameraController?.toggleTorch();
            },
          ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: FutureBuilder<MobileScannerController?>(
              future: _cameraInitializationFuture,
              builder: (context, snapshot) {
                print('FutureBuilder: ConnectionState: ${snapshot.connectionState}, hasData: ${snapshot.hasData}, hasError: ${snapshot.hasError}');
                if (snapshot.connectionState == ConnectionState.done) {
                  if (snapshot.hasError || snapshot.data == null) {
                    print('FutureBuilder: Khởi tạo camera thất bại.');
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline, color: Colors.red, size: 50),
                          const SizedBox(height: 10),
                          Text('Không thể khởi động camera: ${snapshot.error ?? "Lỗi không xác định"}'),
                          const SizedBox(height: 10),
                          ElevatedButton(
                            onPressed: () {
                              print('FutureBuilder: Đang thử lại khởi tạo camera...');
                              setState(() {
                                _isCameraPreviewReady = false;
                                _cameraInitializationFuture = _initializeAndStartCamera();
                              });
                            },
                            child: const Text('Thử lại'),
                          ),
                        ],
                      ),
                    );
                  } else {
                    print('FutureBuilder: Khởi tạo camera thành công, đang hiển thị MobileScanner.');
                    _cameraController = snapshot.data;
                    if (_isCameraPreviewReady) {
                      return MobileScanner(
                        controller: _cameraController!,
                        onDetect: (capture) async {
                          final List<Barcode> barcodes = capture.barcodes;
                          if (barcodes.isNotEmpty && _isScanning) {
                            print('onDetect: Mã vạch đã phát hiện: ${barcodes.first.rawValue}');
                            setState(() {
                              _isScanning = false;
                            });

                            String scannedBarcode = barcodes.first.rawValue!;

                            setState(() {
                              barcode = scannedBarcode;
                            });

                            if (widget.forPayment) {
                              try {
                                final product = await DatabaseHelper.instance
                                    .getSanPhamByMaVach(scannedBarcode);
                                if (product != null) {
                                  print('onDetect: Sản phẩm tìm thấy: ${product['ten']}');
                                  setState(() {
                                    scannedProduct = product;
                                    _productFound = true;
                                  });

                                  final bool? paymentResult = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => PaymentScreen(
                                        product: product,
                                        onPaymentComplete: (p) {},
                                        updateRevenue: (amount) {
                                          widget.onUpdateShiftRevenue?.call(amount);
                                        },
                                        currentShiftId: widget.currentShiftId,
                                      ),
                                    ),
                                  );

                                  if (mounted) {
                                    print('onDetect: PaymentScreen đã pop với kết quả: $paymentResult');
                                    Navigator.pop(context, paymentResult ?? false);
                                  }
                                } else {
                                  print('onDetect: Không tìm thấy sản phẩm cho mã vạch: $scannedBarcode');
                                  setState(() {
                                    _productFound = false;
                                    _isScanning = true;
                                  });
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Không tìm thấy sản phẩm có mã vạch này. Vui lòng thử lại.'),
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                  }
                                }
                              } catch (e) {
                                print('onDetect: LỖI trong luồng thanh toán: ${e.toString()}');
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Lỗi: ${e.toString()}')),
                                  );
                                  setState(() {
                                    _isScanning = true;
                                  });
                                }
                              }
                            } else {
                              Future.microtask(() {
                                if (mounted) {
                                  print('onDetect: Quét không phải thanh toán, đang pop với mã vạch.');
                                  Navigator.pop(context, scannedBarcode);
                                }
                              });
                            }
                          }
                        },
                      );
                    } else {
                      return const Center(child: CircularProgressIndicator());
                    }
                  }
                } else {
                  print('FutureBuilder: Đang trong quá trình khởi tạo camera...');
                  return const Center(child: CircularProgressIndicator());
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
                        style: const TextStyle(fontSize: 16),
                      ),
                      const SizedBox(height: 10),
                      if (widget.forPayment)
                        _buildPaymentInfo(context)
                      else if (barcode != null)
                        const Text('Mã vạch đã được quét.'),
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

  Widget _buildPaymentInfo(BuildContext context) {
    if (_productFound && scannedProduct != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tên sản phẩm: ${scannedProduct!['ten']}'),
          Text(
            'Giá: ${NumberFormat("#,###", "vi_VN").format(
                double.tryParse(scannedProduct!['gia'].toString()) ?? 0)} VNĐ',
          ),
        ],
      );
    } else if (barcode != null) {
      return const Text('Không tìm thấy sản phẩm. Vui lòng thử lại.');
    } else {
      return const SizedBox.shrink();
    }
  }

  void _showSuccessSnackBar(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Thanh toán thành công!'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
