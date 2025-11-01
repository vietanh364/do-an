import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:base_project/models/notification.dart';
import 'package:intl/intl.dart';

class EmployeeNotificationScreen extends StatefulWidget {
  final int userId;

  const EmployeeNotificationScreen({Key? key, required this.userId}) : super(key: key);

  @override
  State<EmployeeNotificationScreen> createState() => _EmployeeNotificationScreenState();
}

class _EmployeeNotificationScreenState extends State<EmployeeNotificationScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<NotificationModel> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final notificationMaps = await _dbHelper.getNotificationsForUser(widget.userId);
      setState(() {
        _notifications = notificationMaps.map((map) => NotificationModel.fromMap(map)).toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải thông báo: $e')),
      );
    }
  }

  Future<void> _markAsRead(int notificationId) async {
    try {
      await _dbHelper.markNotificationAsRead(notificationId);
      _loadNotifications();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi đánh dấu đã đọc: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Thông báo của bạn'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
          ? const Center(child: Text('Bạn chưa có thông báo nào.'))
          : ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _notifications.length,
        itemBuilder: (context, index) {
          final notification = _notifications[index];
          return Card(
            color: notification.isRead ? Colors.grey[200] : Colors.blue[50],
            margin: const EdgeInsets.symmetric(vertical: 5),
            elevation: notification.isRead ? 1 : 3,
            child: ListTile(
              leading: Icon(
                notification.isRead ? Icons.mark_email_read : Icons.email,
                color: notification.isRead ? Colors.grey : Colors.blue,
              ),
              title: Text(
                notification.message,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Thời gian: ${DateFormat('dd/MM/yyyy HH:mm').format(notification.timestamp)}',
                style: TextStyle(
                  color: Colors.grey[600],
                ),
              ),
              onTap: () {
                if (!notification.isRead) {
                  _markAsRead(notification.id!);
                }
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Chi tiết Thông báo'),
                    content: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(notification.message),
                          const SizedBox(height: 10),
                          Text('Thời gian: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(notification.timestamp)}'),
                          Text('Trạng thái: ${notification.isRead ? 'Đã đọc' : 'Chưa đọc'}'),
                        ],
                      ),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Đóng'),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
