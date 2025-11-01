import 'package:flutter/material.dart';
import 'package:base_project/database/database_helper.dart';
import 'package:base_project/models/notification.dart';
import 'package:intl/intl.dart';
import 'package:collection/collection.dart';
class ManagerNotificationScreen extends StatefulWidget {
  final int managerId;

  const ManagerNotificationScreen({Key? key, required this.managerId}) : super(key: key);

  @override
  State<ManagerNotificationScreen> createState() => _ManagerNotificationScreenState();
}

class _ManagerNotificationScreenState extends State<ManagerNotificationScreen> {
  final TextEditingController _messageController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  List<Map<String, dynamic>> _users = [];
  List<Map<String, dynamic>> _sentNotifications = [];
  int? _selectedReceiverId;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _loadSentNotifications();
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final users = await _dbHelper.getAllUsers();
      setState(() {
        _users = users.where((user) => user['id'] != widget.managerId).toList(); // Don't send to self
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading users: $e')),
      );
    }
  }

  Future<void> _loadSentNotifications() async {
    try {
      // Get all notifications where senderId is this manager, regardless of receiver
      final notifications = await _dbHelper.getNotificationsForUser(widget.managerId); // This will fetch notifications where receiverId is NULL or is this user's ID
      setState(() {
        _sentNotifications = notifications.where((notification) => notification['senderId'] == widget.managerId).toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading sent notifications: $e')),
      );
    }
  }

  Future<void> _sendNotification() async {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nội dung thông báo không được để trống.')),
      );
      return;
    }

    try {
      final notification = NotificationModel(
        senderId: widget.managerId,
        receiverId: _selectedReceiverId,
        message: _messageController.text.trim(),
        timestamp: DateTime.now(),
        isRead: false,
      );

      await _dbHelper.insertNotification(notification.toMap());

      _messageController.clear();
      setState(() {
        _selectedReceiverId = null; // Reset selection after sending
      });
      _loadSentNotifications(); // Refresh the list of sent notifications

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thông báo đã được gửi thành công!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi gửi thông báo: $e')),
      );
    }
  }

  Future<void> _deleteNotification(int notificationId) async {
    try {
      await _dbHelper.deleteNotification(notificationId);
      _loadSentNotifications();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thông báo đã được xóa.')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi xóa thông báo: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quản lý Thông báo'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Gửi thông báo mới:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _messageController,
              decoration: const InputDecoration(
                labelText: 'Nội dung thông báo',
                border: OutlineInputBorder(),
                hintText: 'Nhập nội dung thông báo...',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<int?>(
              value: _selectedReceiverId,
              decoration: const InputDecoration(
                labelText: 'Gửi đến (Chọn Nhân viên cụ thể hoặc Để trống cho Tất cả)',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<int?>(
                  value: null,
                  child: Text('Tất cả nhân viên'),
                ),
                ..._users.map((user) => DropdownMenuItem<int?>(
                  value: user['id'] as int,
                  child: Text(user['username'] as String),
                )).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedReceiverId = value;
                });
              },
            ),
            const SizedBox(height: 15),
            Center(
              child: ElevatedButton.icon(
                onPressed: _sendNotification,
                icon: const Icon(Icons.send),
                label: const Text('Gửi Thông báo'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  textStyle: const TextStyle(fontSize: 16),
                ),
              ),
            ),
            const Divider(height: 30),
            const Text(
              'Thông báo đã gửi:',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: _sentNotifications.isEmpty
                  ? const Center(child: Text('Chưa có thông báo nào được gửi.'))
                  : ListView.builder(
                itemCount: _sentNotifications.length,
                itemBuilder: (context, index) {
                  final notificationMap = _sentNotifications[index];
                  final notification = NotificationModel.fromMap(notificationMap);
                  final receiverName = notification.receiverId != null
                      ? (_users.firstWhereOrNull((user) => user['id'] == notification.receiverId)?['username'] ?? 'Người dùng không xác định')
                      : 'Tất cả nhân viên';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 5),
                    elevation: 2,
                    child: ListTile(
                      title: Text(notification.message),
                      subtitle: Text(
                        'Đến: $receiverName - Thời gian: ${DateFormat('dd/MM HH:mm').format(notification.timestamp)}',
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteNotification(notification.id!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}


