import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:base_project/database/database_helper.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';
import 'package:base_project/screens/SanPhamProvider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove('isLoggedIn');
  await prefs.remove('userRole');
  await prefs.remove('userId');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => SanPhamProvider()),
      ],
      child: MaterialApp(
        title: 'My App',
        home: LoginOrHome(prefs: prefs),
        routes: {
          '/login': (context) => LoginScreen(),
          '/home': (context) => HomeScreen(userRole: '', userId: 0),
        },
      ),
    ),
  );
}

class LoginOrHome extends StatelessWidget {
  final SharedPreferences prefs;
  LoginOrHome({required this.prefs});

  @override
  Widget build(BuildContext context) {
    final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final String? userRole = prefs.getString('userRole');
    final int? userId = prefs.getInt('userId');

    if (isLoggedIn && userRole != null && userId != null) {
      return HomeScreen(
        userRole: userRole,
        userId: userId,
      );
    } else {
      return LoginScreen();
    }
  }
}
