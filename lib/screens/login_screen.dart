import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart'; // Import DatabaseHelper
import 'home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
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


  void login(BuildContext context) async {
    String username = _usernameController.text.trim();
    String password = _passwordController.text.trim();


    var user = await DatabaseHelper.instance.getUserByUsername(username);

    if (user != null) {
      if (password == user['password']) {
        print('Login successful for user: $username with role: ${user['role']}');

        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setBool('isLoggedIn', true);
        await prefs.setString('userRole', user['role']);
        await prefs.setInt('userId', user['id']);

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => HomeScreen(
              userRole: user['role'],
              userId: user['id'],
            ),
          ),
        );
      } else {
        print('Incorrect password for user: $username');
        _showSnackBar(context, "Sai mật khẩu!");
      }
    } else {
      print('User not found: $username');
      _showSnackBar(context, "Tài khoản không tồn tại!");
    }
  }


  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.blue, title: Text('Đăng nhập')),
      body: SingleChildScrollView(
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
            ElevatedButton(
              onPressed: () {
                login(context);
              },
              child: Text('Đăng nhập'),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
