class NotificationModel {
  final int? id;
  final int senderId;
  final int? receiverId;
  final String message;
  final DateTime timestamp;
  final bool isRead;

  NotificationModel({
    this.id,
    required this.senderId,
    this.receiverId,
    required this.message,
    required this.timestamp,
    this.isRead = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'senderId': senderId,
      'receiverId': receiverId,
      'message': message,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead ? 1 : 0,
    };
  }

  factory NotificationModel.fromMap(Map<String, dynamic> map) {
    return NotificationModel(
      id: map['id'] as int?,
      senderId: map['senderId'] as int,
      receiverId: map['receiverId'] as int?,
      message: map['message'] as String,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isRead: (map['isRead'] as int) == 1,
    );
  }
}