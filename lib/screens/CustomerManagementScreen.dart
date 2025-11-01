import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';

class CustomerManagementScreen extends StatefulWidget {
  const CustomerManagementScreen({Key? key}) : super(key: key);

  @override
  _CustomerManagementScreenState createState() => _CustomerManagementScreenState();
}

class _CustomerManagementScreenState extends State<CustomerManagementScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _customers = [];
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
    _searchController.addListener(_filterCustomers);
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterCustomers);
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final data = await _dbHelper.getAllCustomers();
      setState(() {
        _customers = data;
      });
    } catch (e) {
      print('Error loading customers: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Lỗi khi tải danh sách khách hàng: ${e.toString()}')),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _filterCustomers() {
    setState(() {
    });
  }

  List<Map<String, dynamic>> get _filteredCustomers {
    if (_searchController.text.isEmpty) {
      return _customers;
    } else {
      return _customers.where((customer) {
        final query = _searchController.text.toLowerCase();
        return (customer['name']?.toLowerCase().contains(query) ?? false) ||
            (customer['phone']?.toLowerCase().contains(query) ?? false);
      }).toList();
    }
  }

  Future<void> _addOrEditCustomer({Map<String, dynamic>? customerToEdit}) async {
    final TextEditingController nameController = TextEditingController(text: customerToEdit?['name']);
    final TextEditingController phoneController = TextEditingController(text: customerToEdit?['phone']);
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(customerToEdit == null ? 'Thêm khách hàng mới' : 'Sửa thông tin khách hàng'),
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
                  };

                  try {
                    if (customerToEdit == null) {
                      await _dbHelper.insertCustomer(newCustomerData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã thêm khách hàng mới.')),
                        );
                      }
                    } else {
                      newCustomerData['id'] = customerToEdit['id'];
                      newCustomerData['points'] = customerToEdit['points'];
                      await _dbHelper.updateCustomer(newCustomerData);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Đã cập nhật thông tin khách hàng.')),
                        );
                      }
                    }
                    _loadCustomers();
                    if (mounted) {
                      Navigator.pop(context);
                    }
                  } catch (e) {
                    print('Error saving customer: $e');
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Lỗi khi lưu khách hàng: ${e.toString()}')),
                      );
                    }
                  }
                }
              },
              child: Text(customerToEdit == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteCustomer(int id) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xác nhận xóa'),
        content: const Text('Bạn có chắc chắn muốn xóa khách hàng này?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Hủy'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _dbHelper.deleteCustomer(id);
        _loadCustomers();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Đã xóa khách hàng.')),
          );
        }
      } catch (e) {
        print('Error deleting customer: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Lỗi khi xóa khách hàng: ${e.toString()}')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý khách hàng'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(kToolbarHeight),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Tìm kiếm theo tên hoặc SĐT...',
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.3),
                contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 10),
              ),
              style: const TextStyle(color: Colors.white),
              cursorColor: Colors.white,
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _filteredCustomers.isEmpty
          ? const Center(child: Text('Không có khách hàng nào.'))
          : ListView.builder(
        itemCount: _filteredCustomers.length,
        itemBuilder: (context, index) {
          final customer = _filteredCustomers[index];
          return Card(
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            elevation: 2,
            child: ListTile(
              title: Text(customer['name'] ?? 'Không tên'),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('SĐT: ${customer['phone'] ?? 'N/A'}'),
                  Text('Điểm: ${NumberFormat("#,###", "vi_VN").format(customer['points'] ?? 0.0)}'),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () => _addOrEditCustomer(customerToEdit: customer),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () => _deleteCustomer(customer['id']),
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _addOrEditCustomer(),
        child: const Icon(Icons.add),
      ),
    );
  }
}
