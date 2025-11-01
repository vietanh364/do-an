import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:base_project/database/database_helper.dart';
import 'SanPhamProvider.dart';

class InventoryScreen extends StatefulWidget {
  final String userRole;

  InventoryScreen({Key? key, required this.userRole}) : super(key: key);

  @override
  _InventoryScreenState createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SanPhamProvider>(context, listen: false).layDanhSachSanPham();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Quản lý tồn kho')),
      body: Consumer<SanPhamProvider>(
        builder: (context, sanPhamProvider, child) {
          List<Map<String, dynamic>> inventory = sanPhamProvider.sanPhamList;

          if (inventory.isEmpty) {
            return Center(child: Text('Không có sản phẩm nào trong kho.'));
          }

          return ListView.builder(
            itemCount: inventory.length,
            itemBuilder: (context, index) {
              final item = inventory[index];
              return ListTile(
                title: Text(item['ten']),
                subtitle: Text('Số lượng: ${item['soLuong']}'),
                trailing: (widget.userRole == "Quản lý") ? IconButton(
                  icon: Icon(Icons.edit),
                  onPressed: () {
                    _showEditDialog(context, Map<String, dynamic>.from(item));
                  },
                ) : null,
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showEditDialog(
      BuildContext context, Map<String, dynamic> item) async {
    final _soLuongController = TextEditingController(text: item['soLuong'].toString());
    final _formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Chỉnh sửa số lượng'),
          content: Form(
            key: _formKey,
            child: TextFormField(
              controller: _soLuongController,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Vui lòng nhập số lượng';
                }
                if (int.tryParse(value) == null) {
                  return 'Số lượng phải là một số nguyên';
                }
                return null;
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  int newSoLuong = int.parse(_soLuongController.text);
                  try {
                    await Provider.of<SanPhamProvider>(context, listen: false)
                        .updateSanPhamQuantity(item['id'], newSoLuong);

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Cập nhật số lượng thành công')),
                    );
                    Navigator.of(context).pop();
                  } catch (e) {
                    print('Lỗi khi cập nhật số lượng: $e');
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Có lỗi xảy ra: ${e.toString()}')),
                    );
                  }
                }
              },
              child: Text('Lưu'),
            ),
          ],
        );
      },
    );
  }
}