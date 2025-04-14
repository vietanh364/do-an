import 'package:flutter/material.dart';

import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void login() {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();
    String? role;

    if (username == "QL" && password == "123") {
      role = "Quản lý";
    } else if (username == "NV" && password == "123") {
      role = "Nhân viên";
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Sai tài khoản hoặc mật khẩu!")));
      return;
    }

    if (role != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => HomeScreen(userRole: role!),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue, title: Text('Đăng nhập')),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 40),
              Image.asset(
                'assets/images/logo.jpg',
                width: 180,
                height: 130,
                fit: BoxFit.contain,
              ),
              SizedBox(height: 8),
              Text(
                'Chào mừng bạn đến với hệ thống\nquản lý cửa hàng tiện lợi',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 50),
              TextField(
                controller: _usernameController,
                decoration: InputDecoration(labelText: 'Tên đăng nhập'),
              ),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: InputDecoration(labelText: 'Mật khẩu'),
              ),
              SizedBox(height: 20),
              ElevatedButton(onPressed: login, child: Text('Đăng nhập')),
              SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}