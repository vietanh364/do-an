import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';

class SanPhamProvider extends ChangeNotifier {
  List<Map<String, dynamic>> _sanPhamList = [];
  bool _isLoading = false;

  List<Map<String, dynamic>> get sanPhamList => _sanPhamList;
  bool get isLoading => _isLoading;

  SanPhamProvider() {
    layDanhSachSanPham();
  }

  Future<void> layDanhSachSanPham() async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await DatabaseHelper.instance.getAllSanPham();
      _sanPhamList = data.map((item) => Map<String, dynamic>.from(item)).toList();
      print('SanPhamProvider: Loaded ${sanPhamList.length} products.');
    } catch (e) {
      print('SanPhamProvider: Error loading product list: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addSanPham(Map<String, dynamic> sanPham) async {
    try {
      final id = await DatabaseHelper.instance.insertSanPham(sanPham);
      final newSanPham = Map<String, dynamic>.from(sanPham);
      newSanPham['id'] = id;
      _sanPhamList.add(newSanPham);
      notifyListeners();
      print('SanPhamProvider: Added new product: ${newSanPham['ten']} with ID: $id.');
    } catch (e) {
      print("Lỗi khi thêm sản phẩm: $e");
      rethrow;
    }
  }

  Future<void> xoaSanPham(int id) async {
    try {
      await DatabaseHelper.instance.deleteSanPham(id);
      _sanPhamList.removeWhere((item) => item['id'] == id);
      notifyListeners();
      print('SanPhamProvider: Deleted product with ID: $id.');
    } catch (e) {
      print("Lỗi khi xóa sản phẩm: $e");
      rethrow;
    }
  }

  Future<void> capNhatSanPham(Map<String, dynamic> sanPham) async {
    try {
      await DatabaseHelper.instance.updateSanPham(sanPham);
      final index = _sanPhamList.indexWhere((item) => item['id'] == sanPham['id']);
      if (index != -1) {
        _sanPhamList[index] = Map<String, dynamic>.from(sanPham);
        notifyListeners();
        print('SanPhamProvider: Product ID ${sanPham['id']} updated locally and notified.');
      }
    } catch (e) {
      print("Lỗi cập nhật sản phẩm: $e");
      rethrow;
    }
  }

  Future<void> updateSanPhamQuantity(int productId, int newQuantity) async {
    try {
      int rowsAffected = await DatabaseHelper.instance.updateSoLuongSanPham(productId, newQuantity);

      if (rowsAffected > 0) {
        final index = _sanPhamList.indexWhere((item) => item['id'] == productId);
        if (index != -1) {
          _sanPhamList[index]['soLuong'] = newQuantity;
          notifyListeners();
          print('SanPhamProvider: Updated quantity for product ID $productId to $newQuantity. Local list updated and notified.');
        } else {
          print('SanPhamProvider: Product with ID $productId not found in local list, reloading all data.');
          await layDanhSachSanPham();
        }
      } else {
        print('SanPhamProvider: No rows affected when updating quantity for product ID $productId. Product might not exist in DB.');
      }
    } catch (e) {
      print('SanPhamProvider: Error updating product quantity: $e');
      rethrow;
    }
  }

  Future<void> dongBoHoaDanhSach() async {
    await layDanhSachSanPham();
  }

  void setSanPhamList(List<Map<String, dynamic>> sanPhamList) {

    _sanPhamList = sanPhamList.map((item) => Map<String, dynamic>.from(item)).toList();
    notifyListeners();
  }
}
