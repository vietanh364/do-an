import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({Key? key}) : super(key: key);

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<Map<String, dynamic>> _userList = [];
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _roleController = TextEditingController();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  int? _editingUserId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await DatabaseHelper.instance.getAllUsers();
    setState(() {
      _userList = users;
    });
  }

  Future<void> _addUser() async {
    if (_formKey.currentState!.validate()) {
      final newUser = {
        'username': _usernameController.text,
        'password': _passwordController.text,
        'role': _roleController.text,
        'ten_nv': _nameController.text,
        'sdt_nv': _phoneController.text,
        'dia_chi_nv': _addressController.text,
      };

      try {
        if (_editingUserId == null) {
          await DatabaseHelper.instance.insertUser(newUser);
        } else {

          await DatabaseHelper.instance.updateUser(_editingUserId!, newUser);
          _editingUserId = null;
        }
        await _loadUsers();
        _clearInputFields();
        if (mounted) Navigator.of(context).pop();
      } catch (e) {
        print("Error adding/updating user: $e");
        if (mounted) {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Error'),
              content: Text('Failed to add/update user: ${e.toString()}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    }
  }

  void _showAddUserDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            _editingUserId == null ? 'Thêm nhân viên' : 'Sửa nhân viên',
          ),
          content: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên đăng nhập',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên đăng nhập';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Mật khẩu'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mật khẩu';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _roleController,
                    decoration: const InputDecoration(
                      labelText: 'Vai trò (Quản lý/Nhân viên)',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập vai trò';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Tên nhân viên',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập tên nhân viên';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _phoneController,
                    decoration: const InputDecoration(
                      labelText: 'Số điện thoại',
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập số điện thoại';
                      }
                      if (!RegExp(r'^\d{10}$').hasMatch(value)) {
                        return 'Số điện thoại không hợp lệ';
                      }
                      return null;
                    },
                  ),
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(labelText: 'Địa chỉ'),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập địa chỉ';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Hủy'),
            ),
            ElevatedButton(
              onPressed: _addUser,
              child: Text(_editingUserId == null ? 'Thêm' : 'Lưu'),
            ),
          ],
        );
      },
    );
  }

  void _editUser(Map<String, dynamic> user) {
    _clearInputFields(); // Gọi clearInputFields trước khi set state
    _editingUserId = user['id'];
    _usernameController.text = user['username'];
    _passwordController.text = user['password'];
    _roleController.text = user['role'];
    _nameController.text = user['ten_nv'];
    _phoneController.text = user['sdt_nv'];
    _addressController.text = user['dia_chi_nv'];
    _showAddUserDialog();
  }

  Future<void> _deleteUser(int id) async {
    try {
      await DatabaseHelper.instance.deleteUser(id);
      await _loadUsers();
    } catch (e) {
      print("Error deleting user: $e");
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('Failed to delete user: ${e.toString()}'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
    }
  }

  void _clearInputFields() {
    _usernameController.clear();
    _passwordController.clear();
    _roleController.clear();
    _nameController.clear();
    _phoneController.clear();
    _addressController.clear();
    _editingUserId = null;
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _roleController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quản lý nhân viên')),
      body: ListView.builder(
        itemCount: _userList.length,
        itemBuilder: (context, index) {
          final user = _userList[index];
          return ListTile(
            title: Text(user['username']),
            subtitle: Text('Vai trò: ${user['role']}, Tên: ${user['ten_nv']}'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editUser(user),
                ),
                IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () => _deleteUser(user['id']),
                ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddUserDialog,
        child: const Icon(Icons.add),
      ),
    );
  }
}

