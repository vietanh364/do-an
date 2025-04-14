import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../database/database_helper.dart';

class ThemSanPhamScreen extends StatefulWidget {
  final Function(Map<String, dynamic>) onSanPhamAdded;
  final Map<String, dynamic>? sanPhamToEdit;
  final String userRole;

  ThemSanPhamScreen({
    required this.onSanPhamAdded,
    this.sanPhamToEdit,
    required this.userRole,
  });

  @override
  _ThemSanPhamScreenState createState() => _ThemSanPhamScreenState();
}

class _ThemSanPhamScreenState extends State<ThemSanPhamScreen> {
  final TextEditingController _tenSanPhamController = TextEditingController();
  final TextEditingController _giaSanPhamController = TextEditingController();
  final TextEditingController _maVachSanPhamController = TextEditingController();
  File? _selectedImage;

  @override
  void initState() {
    super.initState();
    if (widget.sanPhamToEdit != null) {
      _tenSanPhamController.text = widget.sanPhamToEdit!['ten'];
      _giaSanPhamController.text = widget.sanPhamToEdit!['gia'].toString();
      _maVachSanPhamController.text = widget.sanPhamToEdit!['maVach'] ?? '';
      if (widget.sanPhamToEdit!['hinhAnh'] != null) {
        _selectedImage = File(widget.sanPhamToEdit!['hinhAnh']);
      }
    }
  }

  Future<void> _chonAnh() async {
    final pickedFile = await ImagePicker().pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _themSanPham() async {
    String tenSanPham = _tenSanPhamController.text.trim();
    String giaSanPham = _giaSanPhamController.text.trim();
    String maVachSanPham = _maVachSanPhamController.text.trim();
    print('Giá trị maVachSanPham: $maVachSanPham');
    if (tenSanPham.isEmpty || giaSanPham.isEmpty || maVachSanPham.isEmpty || _selectedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Vui lòng nhập đầy đủ thông tin và chọn ảnh!')),
      );
      return;
    }

    double gia;
    try {
      gia = double.parse(giaSanPham);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Giá sản phẩm không hợp lệ!')),
      );
      return;
    }

    Map<String, dynamic> sanPham = {
      'ten': tenSanPham,
      'gia': gia,
      'maVach': maVachSanPham,
      'hinhAnh': _selectedImage!.path,
      'id': widget.sanPhamToEdit?['id'],
    };
    print('Dữ liệu sản phẩm trước khi chèn: $sanPham');
    try {
      print('Dữ liệu sản phẩm trước khi chèn: $sanPham');
      int result = await DatabaseHelper.instance.insertSanPham(sanPham);
      print('Kết quả chèn sản phẩm: $result');

      if (result > 0) {
        widget.onSanPhamAdded(sanPham);
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Không thể thêm sản phẩm. Vui lòng thử lại.')),
        );
        Navigator.pop(context, false);
      }

    } catch (e) {
      print('Lỗi thêm sản phẩm: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Có lỗi xảy ra khi thêm sản phẩm.')),
      );
      Navigator.pop(context, false);
    }
  }

  void _xoaSanPham() async {
    if (widget.sanPhamToEdit != null) {
      await DatabaseHelper.instance.deleteSanPham(widget.sanPhamToEdit!['id']);
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    double gia = 0.0;
    try {
      gia = double.parse(_giaSanPhamController.text);
    } catch (e) {
      print('Error parsing gia in build: $e');
    }

    return Scaffold(
      appBar: AppBar(
          title: Text(widget.sanPhamToEdit != null ? 'Sửa sản phẩm' : 'Thêm sản phẩm')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
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
                    : Icon(Icons.camera_alt, size: 50, color: Colors.grey),
              ),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _tenSanPhamController,
              decoration: InputDecoration(labelText: 'Tên sản phẩm'),
            ),
            SizedBox(height: 10),
            TextField(
              controller: _giaSanPhamController,
              decoration: InputDecoration(labelText: 'Giá sản phẩm'),
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 10),
            TextField(
              controller: _maVachSanPhamController,
              decoration: InputDecoration(labelText: 'Mã vạch sản phẩm'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _themSanPham,
              child: Text(widget.sanPhamToEdit != null
                  ? 'Cập nhật sản phẩm'
                  : 'Thêm sản phẩm'),
            ),
            if (widget.sanPhamToEdit != null) ...[
              SizedBox(height: 10),
              ElevatedButton(
                onPressed: _xoaSanPham,
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa sản phẩm'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}