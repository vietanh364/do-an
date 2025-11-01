import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';
import 'package:provider/provider.dart';
import 'SanPhamProvider.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'PaymentScreen.dart';
import 'barcode_scanner_screen.dart';

class ThemSanPhamScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSanPhamAdded;
  final Map<String, dynamic>? sanPhamToEdit;
  final String userRole;
  final bool isForPayment;
  final Function(Map<String, dynamic>)? onProductSelected;

  ThemSanPhamScreen({
    required this.onSanPhamAdded,
    this.sanPhamToEdit,
    required this.userRole,
    this.isForPayment = false,
    this.onProductSelected,
  });

  @override
  _ThemSanPhamScreenState createState() => _ThemSanPhamScreenState();
}

class _ThemSanPhamScreenState extends State<ThemSanPhamScreen> {
  final TextEditingController _tenSanPhamController = TextEditingController();
  final TextEditingController _giaSanPhamController = TextEditingController();
  final TextEditingController _maVachController = TextEditingController();
  File? _selectedImage;
  bool _isScanning = false;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    if (widget.sanPhamToEdit != null) {
      _tenSanPhamController.text = widget.sanPhamToEdit!['ten'];
      _giaSanPhamController.text = widget.sanPhamToEdit!['gia'].toString();
      if (widget.sanPhamToEdit!['hinhAnh'] != null) {
        _selectedImage = File(widget.sanPhamToEdit!['hinhAnh']);
      }
      if (widget.sanPhamToEdit!['maVach'] != null) {
        _maVachController.text = widget.sanPhamToEdit!['maVach'];
      }
    }
  }

  @override
  void dispose() {
    _tenSanPhamController.dispose();
    _giaSanPhamController.dispose();
    _maVachController.dispose();
    super.dispose();
  }

  Future<void> _chonAnh() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _startScan(BuildContext context) async {
    setState(() {
      _isScanning = true;
    });
    final String? barcodeResult = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BarcodeScannerScreen(
          userRole: widget.userRole,
          forPayment: widget.isForPayment,
        ),
      ),
    );
    setState(() {
      _isScanning = false;
      if (barcodeResult != null) {
        _maVachController.text = barcodeResult;
      }
    });
  }

  Future<void> _luuSanPham(BuildContext context) async {
    if (_formKey.currentState!.validate()) {
      String tenSanPham = _tenSanPhamController.text.trim();
      String giaSanPham = _giaSanPhamController.text.trim();
      String maVach = _maVachController.text.trim();

      double gia = double.parse(giaSanPham);


      String maVachToLuu = maVach;
      if (maVach.isEmpty) {
        maVachToLuu = 'NO_BARCODE_${DateTime.now().millisecondsSinceEpoch}';
      } else {
        bool isMaVachValid = await DatabaseHelper.instance.isMaVachUnique(maVach);
        if (widget.sanPhamToEdit != null && maVachToLuu == widget.sanPhamToEdit!['maVach'])
        {
          isMaVachValid = true;
        }
        if (!isMaVachValid) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                  content:
                  Text('Mã vạch đã tồn tại! Vui lòng nhập mã vạch khác.')),
            );
          }
          return;
        }
      }

      Map<String, dynamic> sanPham = {
        'ten': tenSanPham,
        'gia': gia,
        'hinhAnh': _selectedImage?.path,
        'maVach': maVachToLuu,
      };

      if (widget.isForPayment) {
        if (widget.onProductSelected != null)
        {
          widget.onProductSelected!(sanPham);
        }
        Navigator.of(context).pop();
        return;
      }

      try {
        if (widget.sanPhamToEdit != null) {
          sanPham['id'] = widget.sanPhamToEdit!['id'];
          await Provider.of<SanPhamProvider>(context, listen: false)
              .capNhatSanPham(sanPham);
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        } else {
          await DatabaseHelper.instance.insertSanPham(sanPham);
          widget.onSanPhamAdded(sanPham);
          Provider.of<SanPhamProvider>(context, listen: false)
              .dongBoHoaDanhSach();
          if (context.mounted) {
            Navigator.pop(context, true);
          }
        }
      } catch (e) {
        print('Lỗi lưu sản phẩm: $e');
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                Text('Có lỗi xảy ra khi lưu sản phẩm: ${e.toString()}')),
          );
        }
        if (context.mounted) {
          Navigator.pop(context, false);
        }
      }
    }
  }

  void _xoaSanPham() async {
    if (widget.sanPhamToEdit != null) {
      try {
        await DatabaseHelper.instance
            .deleteSanPham(widget.sanPhamToEdit!['id']);
        Provider.of<SanPhamProvider>(context, listen: false)
            .xoaSanPham(widget.sanPhamToEdit!['id']);
        if (context.mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        print("Lỗi xóa sản phẩm: $e");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Có lỗi xảy ra khi xóa sản phẩm"),
          ));
        }
        if (context.mounted) {
          Navigator.pop(context, false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: Text(widget.sanPhamToEdit != null
              ? 'Sửa sản phẩm'
              : 'Thêm sản phẩm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(  // Wrap with a Form
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(
                onTap: _chonAnh,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: _selectedImage != null
                      ? Image.file(_selectedImage!, fit: BoxFit.cover)
                      : const Icon(Icons.camera_alt,
                      size: 50, color: Colors.grey),
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _tenSanPhamController,
                decoration: const InputDecoration(labelText: 'Tên sản phẩm'),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập tên sản phẩm';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _giaSanPhamController,
                decoration: const InputDecoration(labelText: 'Giá sản phẩm'),
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Vui lòng nhập giá sản phẩm';
                  }
                  if (double.tryParse(value) == null) {
                    return 'Giá không hợp lệ';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _maVachController,
                decoration: InputDecoration(
                  labelText: 'Mã vạch (tùy chọn)',
                  suffixIcon: IconButton(
                    icon: Icon(_isScanning
                        ? Icons.scanner_outlined
                        : Icons.camera_alt),
                    onPressed:
                    _isScanning ? null : () => _startScan(context),
                  ),
                ),
                readOnly: true,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => _luuSanPham(context),
                child: Text(widget.sanPhamToEdit != null
                    ? 'Cập nhật sản phẩm'
                    : 'Thêm sản phẩm'),
              ),
              if (widget.sanPhamToEdit != null && !widget.isForPayment) ...[
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _xoaSanPham,
                  style:
                  ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: const Text('Xóa sản phẩm'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

